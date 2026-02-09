<#
.SYNOPSIS
    Codex Heartbeat Monitor Module v2.1
.DESCRIPTION
    Uses PowerShell Background Jobs + output file monitoring for reliable async execution.
    
    Key change from v1: Uses Start-Job instead of Start-Process for reliable
    process tracking and completion detection.
    
    v2.1: Migrated to .agent/dispatcher/ (T-HB-02)
    
    Heartbeat is determined by:
    1. Job State (Running/Completed/Failed)
    2. Output file (-o lastmsg) growth
    3. JSONL stdout growth (when --json is used)
#>

# 统一使用 .agent/ 体系下的路径
$Script:AgentRoot = Join-Path $PSScriptRoot ".."
$Script:TaskDir = Join-Path $Script:AgentRoot "memory" "heartbeat_tasks"
$Script:LogDir  = Join-Path $Script:AgentRoot "memory" "heartbeat_logs"

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
        [int]$TimeoutSeconds = 3600,
        [ValidateSet("read-only","workspace-write","full-auto","danger-full-access")]
        [string]$SandboxMode = "danger-full-access",
        [string[]]$AddDirs = @()
    )

    Initialize-CodexHeartbeat

    $lastMsgFile = Join-Path $Script:LogDir "$TaskId-lastmsg.txt"
    $stateFile = Join-Path $Script:TaskDir "$TaskId.json"

    # Build arg list for codex
    $argList = @("exec", "--full-auto", "-o", $lastMsgFile, "-C", $WorkDir)
    if ($Model) {
        $argList += @("-m", $Model)
    }
    # T-HB-01: Sandbox 模式控制（默认 danger-full-access 以确保文件可写）
    if ($SandboxMode -eq "danger-full-access") {
        $argList += @("--sandbox", "danger-full-access")
    }
    # 额外目录访问
    foreach ($dir in $AddDirs) {
        if (Test-Path $dir) {
            $argList += @("--add-dir", $dir)
        }
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
    $state["sandboxMode"] = $SandboxMode
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

# T-HB-04: 多任务并行心跳 — 批量启动 + 汇总等待
function Start-CodexTaskPool {
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Tasks,  # @( @{TaskId="T-001"; Prompt="..."}, @{TaskId="T-002"; Prompt="..."} )
        [string]$WorkDir = (Get-Location).Path,
        [string]$Model = "",
        [int]$TimeoutSeconds = 3600,
        [string]$SandboxMode = "danger-full-access",
        [int]$MaxConcurrent = 3
    )

    $results = @()
    $queue = [System.Collections.Queue]::new()
    $Tasks | ForEach-Object { $queue.Enqueue($_) }
    $running = @{}

    Write-Host ""
    Write-Host "[POOL] Starting task pool: $($Tasks.Count) tasks, max $MaxConcurrent concurrent" -ForegroundColor Cyan

    while ($queue.Count -gt 0 -or $running.Count -gt 0) {
        # 启动新任务（如果有空位）
        while ($queue.Count -gt 0 -and $running.Count -lt $MaxConcurrent) {
            $taskDef = $queue.Dequeue()
            $taskResult = Start-CodexTask -TaskId $taskDef.TaskId -Prompt $taskDef.Prompt `
                -WorkDir $WorkDir -Model $Model -TimeoutSeconds $TimeoutSeconds -SandboxMode $SandboxMode
            $running[$taskDef.TaskId] = $taskResult
            Write-Host "[POOL] Started: $($taskDef.TaskId) (running: $($running.Count)/$MaxConcurrent)" -ForegroundColor DarkGray
        }

        # 检查所有运行中任务
        $completed = @()
        foreach ($taskId in @($running.Keys)) {
            $status = Get-CodexTaskStatus -TaskId $taskId
            if ($status -and $status.status -ne "RUNNING") {
                $completed += $taskId
                $results += [PSCustomObject]@{
                    TaskId = $taskId
                    Status = $status.status
                    Progress = $status.progress
                }
                Write-Host "[POOL] Completed: $taskId → $($status.status)" -ForegroundColor $(if ($status.status -eq "DONE") { "Green" } else { "Yellow" })
            }
        }
        $completed | ForEach-Object { $running.Remove($_) }

        if ($running.Count -gt 0) {
            Start-Sleep -Seconds 5
        }
    }

    Write-Host "[POOL] All $($Tasks.Count) tasks processed" -ForegroundColor Green
    $results | Format-Table -AutoSize
    return $results
}

# T-HB-05: 心跳数据持久化 — 重新附加已有 Job
function Restore-CodexTasks {
    <#
    .SYNOPSIS
        尝试恢复任务状态文件中记录的 Job。
    .DESCRIPTION
        遍历 TaskDir 中的 JSON 状态文件，检查对应 JobId 是否仍在运行。
        如果 Job 已丢失（进程重启），标记为 LOST。
    #>
    Initialize-CodexHeartbeat
    $files = Get-ChildItem -Path $Script:TaskDir -Filter "*.json" -ErrorAction SilentlyContinue
    if (-not $files) {
        Write-Host "[RESTORE] No task records found" -ForegroundColor DarkGray
        return
    }

    $restored = 0
    $lost = 0
    foreach ($file in $files) {
        $state = Get-Content $file.FullName -Raw | ConvertFrom-Json
        if ($state.status -ne "RUNNING") { continue }

        $job = $null
        if ($state.jobId) {
            $job = Get-Job -Id $state.jobId -ErrorAction SilentlyContinue
        }

        if ($job -and $job.State -eq "Running") {
            Write-Host "[RESTORE] Task $($state.taskId): Job $($state.jobId) still running" -ForegroundColor Green
            $restored++
        } else {
            # Job 丢失，标记状态
            $state.status = "LOST"
            $state.progress = "Job lost after process restart. Last heartbeat: $($state.lastHeartbeat)"
            $state.lastHeartbeat = (Get-Date).ToString("o")
            $state | ConvertTo-Json -Depth 5 | Set-Content $file.FullName -Encoding UTF8
            Write-Host "[RESTORE] Task $($state.taskId): Job LOST (process restarted)" -ForegroundColor Yellow
            $lost++
        }
    }

    Write-Host "[RESTORE] Summary: $restored running, $lost lost" -ForegroundColor Cyan
}

Export-ModuleMember -Function @(
    'Initialize-CodexHeartbeat',
    'Start-CodexTask',
    'Get-CodexTaskStatus',
    'Wait-CodexTask',
    'Stop-CodexTask',
    'Get-CodexTasks',
    'Clear-CodexTasks',
    'Start-CodexTaskPool',
    'Restore-CodexTasks'
)
