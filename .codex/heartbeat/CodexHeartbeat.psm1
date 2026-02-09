<#
.SYNOPSIS
    Codex Heartbeat Monitor Module v2.0
.DESCRIPTION
    Uses PowerShell Background Jobs + output file monitoring for reliable async execution.
    
    Key change from v1: Uses Start-Job instead of Start-Process for reliable
    process tracking and completion detection.
    
    Heartbeat is determined by:
    1. Job State (Running/Completed/Failed)
    2. Output file (-o lastmsg) growth
    3. JSONL stdout growth (when --json is used)
#>

$Script:TaskDir = Join-Path $PSScriptRoot "..\tasks"
$Script:LogDir  = Join-Path $PSScriptRoot "..\logs"

function Initialize-CodexHeartbeat {
    New-Item -Path $Script:TaskDir -ItemType Directory -Force | Out-Null
    New-Item -Path $Script:LogDir  -ItemType Directory -Force | Out-Null
    Write-Host "[OK] Heartbeat system initialized" -ForegroundColor Green
    Write-Host "     Task dir: $Script:TaskDir"
    Write-Host "     Log dir:  $Script:LogDir"
}

function Start-CodexTask {
    param(
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$WorkDir = (Get-Location).Path,
        [string]$Model = "",
        [int]$TimeoutSeconds = 3600
    )

    Initialize-CodexHeartbeat

    $lastMsgFile = Join-Path $Script:LogDir "$TaskId-lastmsg.txt"
    $stateFile = Join-Path $Script:TaskDir "$TaskId.json"

    # Build arg list for codex
    $argList = @("exec", "--full-auto", "-o", $lastMsgFile, "-C", $WorkDir)
    if ($Model) {
        $argList += @("-m", $Model)
    }
    $argList += $Prompt

    Write-Host ""
    Write-Host "[LAUNCH] Async task: $TaskId" -ForegroundColor Cyan
    Write-Host "         Args: codex $($argList -join ' ')" -ForegroundColor DarkGray

    # Use Start-Job for reliable background execution
    # The job runs codex synchronously inside the job context
    $job = Start-Job -ScriptBlock {
        param($ArgList)
        # Call codex directly - PowerShell resolves the .ps1 shim automatically
        $result = & codex @ArgList 2>&1
        return $result
    } -ArgumentList (,$argList) -Name "Codex-$TaskId"

    $state = @{}
    $state["taskId"] = $TaskId
    $state["prompt"] = $Prompt
    $state["status"] = "RUNNING"
    $state["jobId"] = $job.Id
    $state["jobName"] = $job.Name
    $state["startTime"] = (Get-Date).ToString("o")
    $state["lastHeartbeat"] = (Get-Date).ToString("o")
    $state["progress"] = "Job started (ID: $($job.Id))"
    $state["lastMsgFile"] = $lastMsgFile
    $state["lastMsgSize"] = 0
    $state["timeout"] = $TimeoutSeconds
    $state["exitCode"] = $null
    $state["error"] = $null
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8

    Write-Host "         Job ID: $($job.Id)" -ForegroundColor DarkGray
    Write-Host "         State: $stateFile" -ForegroundColor DarkGray
    Write-Host ""

    return @{
        TaskId   = $TaskId
        JobId    = $job.Id
        StateFile = $stateFile
        Job      = $job
    }
}

function Get-CodexTaskStatus {
    param(
        [Parameter(Mandatory)][string]$TaskId
    )

    $stateFile = Join-Path $Script:TaskDir "$TaskId.json"
    if (-not (Test-Path $stateFile)) {
        Write-Warning "Task $TaskId not found"
        return $null
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Json

    # Check job state if we have a jobId
    if ($state.jobId) {
        $job = Get-Job -Id $state.jobId -ErrorAction SilentlyContinue
        
        if (-not $job) {
            # Job no longer exists
            if ($state.status -eq "RUNNING") {
                $state.status = "DONE"
                $state.lastHeartbeat = (Get-Date).ToString("o")
                $state.progress = "Job completed (removed)"
                $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
            }
            return $state
        }

        switch ($job.State) {
            "Completed" {
                if ($state.status -eq "RUNNING") {
                    $state.status = "DONE"
                    $state.lastHeartbeat = (Get-Date).ToString("o")
                    $state.exitCode = 0

                    # Get job output
                    $output = Receive-Job -Id $state.jobId -ErrorAction SilentlyContinue
                    if ($output) {
                        $outputStr = ($output | Out-String).Trim()
                        $preview = $outputStr.Substring(0, [Math]::Min(300, $outputStr.Length))
                        $state.progress = "DONE: $preview"
                    } else {
                        $state.progress = "DONE (no output)"
                    }

                    # Check lastmsg file
                    if ($state.lastMsgFile -and (Test-Path $state.lastMsgFile)) {
                        $msgContent = Get-Content $state.lastMsgFile -Raw -ErrorAction SilentlyContinue
                        if ($msgContent) {
                            $state.progress = "DONE - last message written"
                        }
                    }

                    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
                }
            }
            "Failed" {
                if ($state.status -eq "RUNNING") {
                    $state.status = "ERROR"
                    $state.lastHeartbeat = (Get-Date).ToString("o")
                    $state.exitCode = 1

                    $errOutput = Receive-Job -Id $state.jobId -ErrorAction SilentlyContinue
                    if ($errOutput) {
                        $errStr = ($errOutput | Out-String).Trim()
                        $state.error = $errStr.Substring(0, [Math]::Min(500, $errStr.Length))
                    }
                    $state.progress = "FAILED"

                    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
                }
            }
            "Running" {
                # Job is still running - check for real heartbeat via output file
                $outputChanged = $false

                if ($state.lastMsgFile -and (Test-Path $state.lastMsgFile)) {
                    $currentSize = (Get-Item $state.lastMsgFile).Length
                    $lastKnownSize = if ($state.PSObject.Properties['lastMsgSize']) { $state.lastMsgSize } else { 0 }

                    if ($currentSize -gt $lastKnownSize) {
                        $outputChanged = $true
                        $state | Add-Member -NotePropertyName 'lastMsgSize' -NotePropertyValue $currentSize -Force
                        $state.progress = "Running... (output: $currentSize bytes)"
                    }
                }

                # Check if job has new partial output by comparing child job data counts
                if ($job.ChildJobs.Count -gt 0) {
                    $childOutput = $job.ChildJobs[0].Output.Count
                    $lastKnownOutput = if ($state.PSObject.Properties['lastJobOutputCount']) { $state.lastJobOutputCount } else { 0 }
                    if ($childOutput -gt $lastKnownOutput) {
                        $outputChanged = $true
                        $state | Add-Member -NotePropertyName 'lastJobOutputCount' -NotePropertyValue $childOutput -Force
                        $state.progress = "Running... (output lines: $childOutput)"
                    }
                }

                if ($outputChanged) {
                    $state.lastHeartbeat = (Get-Date).ToString("o")
                }

                $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
            }
            "Stopped" {
                $state.status = "CANCELLED"
                $state.lastHeartbeat = (Get-Date).ToString("o")
                $state.progress = "Job stopped"
                $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
            }
        }
    }

    return $state
}

function Wait-CodexTask {
    param(
        [Parameter(Mandatory)][string]$TaskId,
        [int]$PollIntervalSeconds = 10,
        [int]$TimeoutSeconds = 3600,
        [int]$HeartbeatTimeoutSeconds = 120
    )

    $startTime = Get-Date
    $spinChars = @('|','/','-','\')
    $spinIdx = 0
    $pollCount = 0

    Write-Host ""
    Write-Host "[WATCH] Monitoring task: $TaskId" -ForegroundColor Yellow
    Write-Host "        Poll: ${PollIntervalSeconds}s | Timeout: ${TimeoutSeconds}s | HB Timeout: ${HeartbeatTimeoutSeconds}s"
    Write-Host ("=" * 65) -ForegroundColor DarkGray

    while ($true) {
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $pollCount++

        if ($elapsed -gt $TimeoutSeconds) {
            Write-Host ""
            Write-Host "[TIMEOUT] Task $TaskId timed out (${TimeoutSeconds}s)" -ForegroundColor Red
            return @{ Status = "TIMEOUT"; Elapsed = $elapsed; PollCount = $pollCount }
        }

        $status = Get-CodexTaskStatus -TaskId $TaskId

        if (-not $status) {
            Write-Host "[ERROR] Cannot get task status" -ForegroundColor Red
            return @{ Status = "ERROR"; Error = "State file missing" }
        }

        # Calculate heartbeat age
        $heartbeatAge = ((Get-Date) - [DateTime]::Parse($status.lastHeartbeat)).TotalSeconds

        # Heartbeat timeout check
        if ($heartbeatAge -gt $HeartbeatTimeoutSeconds -and $status.status -eq "RUNNING") {
            Write-Host ""
            Write-Host "[DEAD] Heartbeat timeout! No activity for ${HeartbeatTimeoutSeconds}s. Last: $($status.lastHeartbeat)" -ForegroundColor Red
            return @{ Status = "HEARTBEAT_TIMEOUT"; LastHeartbeat = $status.lastHeartbeat; Elapsed = $elapsed }
        }

        $spinChar = $spinChars[$spinIdx % $spinChars.Length]
        $spinIdx++
        $elapsedStr = [TimeSpan]::FromSeconds([int]$elapsed).ToString("mm\:ss")

        switch ($status.status) {
            "DONE" {
                Write-Host ""
                Write-Host "[DONE] Task $TaskId completed! Time: $elapsedStr" -ForegroundColor Green

                $result = $null
                if ($status.lastMsgFile -and (Test-Path $status.lastMsgFile)) {
                    $result = Get-Content $status.lastMsgFile -Raw -ErrorAction SilentlyContinue
                }

                return @{
                    Status    = "DONE"
                    Elapsed   = $elapsed
                    PollCount = $pollCount
                    Result    = $result
                    Progress  = $status.progress
                }
            }
            "ERROR" {
                Write-Host ""
                Write-Host "[FAIL] Task $TaskId failed!" -ForegroundColor Red
                if ($status.error) {
                    Write-Host "       Error: $($status.error)" -ForegroundColor Red
                }
                return @{
                    Status  = "ERROR"
                    Elapsed = $elapsed
                    Error   = $status.error
                }
            }
            "CANCELLED" {
                Write-Host ""
                Write-Host "[CANCELLED] Task $TaskId was cancelled" -ForegroundColor Yellow
                return @{ Status = "CANCELLED"; Elapsed = $elapsed }
            }
            "RUNNING" {
                Write-Host "$spinChar [$elapsedStr] $TaskId | $($status.progress) | HB: $([int]$heartbeatAge)s ago | #$pollCount"
            }
            default {
                Write-Host "$spinChar [$elapsedStr] $TaskId | Status: $($status.status)"
            }
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }
}

function Stop-CodexTask {
    param(
        [Parameter(Mandatory)][string]$TaskId
    )

    $stateFile = Join-Path $Script:TaskDir "$TaskId.json"
    if (-not (Test-Path $stateFile)) {
        Write-Warning "Task $TaskId not found"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Json

    if ($state.jobId) {
        $job = Get-Job -Id $state.jobId -ErrorAction SilentlyContinue
        if ($job -and $job.State -eq "Running") {
            Stop-Job -Id $state.jobId
            Write-Host "[STOP] Task $TaskId stopped (Job: $($state.jobId))" -ForegroundColor Yellow
        }
    }

    $state.status = "CANCELLED"
    $state.lastHeartbeat = (Get-Date).ToString("o")
    $state.progress = "Cancelled by user"
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
}

function Get-CodexTasks {
    Initialize-CodexHeartbeat
    $files = Get-ChildItem -Path $Script:TaskDir -Filter "*.json" -ErrorAction SilentlyContinue
    if (-not $files) {
        Write-Host "[EMPTY] No tasks" -ForegroundColor DarkGray
        return @()
    }

    $tasks = @()
    foreach ($file in $files) {
        $state = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $elapsed = ""
        if ($state.startTime) {
            $elapsed = [TimeSpan]::FromSeconds(((Get-Date) - [DateTime]::Parse($state.startTime)).TotalSeconds).ToString("hh\:mm\:ss")
        }
        $tasks += [PSCustomObject]@{
            TaskId   = $state.taskId
            Status   = $state.status
            JobId    = $state.jobId
            Elapsed  = $elapsed
            Progress = $state.progress
        }
    }

    $tasks | Format-Table -AutoSize
    return $tasks
}

function Clear-CodexTasks {
    param([switch]$Force)

    if (-not $Force) {
        $confirm = Read-Host "Clear all task records? (y/N)"
        if ($confirm -ne 'y') { return }
    }

    # Clean up jobs
    $files = Get-ChildItem -Path $Script:TaskDir -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $state = Get-Content $file.FullName -Raw | ConvertFrom-Json
        if ($state.jobId) {
            Remove-Job -Id $state.jobId -Force -ErrorAction SilentlyContinue
        }
    }

    Remove-Item -Path "$Script:TaskDir\*" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$Script:LogDir\*" -Force -ErrorAction SilentlyContinue
    Write-Host "[CLEAN] All task records and jobs cleared" -ForegroundColor Yellow
}

Export-ModuleMember -Function @(
    'Initialize-CodexHeartbeat',
    'Start-CodexTask',
    'Get-CodexTaskStatus',
    'Wait-CodexTask',
    'Stop-CodexTask',
    'Get-CodexTasks',
    'Clear-CodexTasks'
)
