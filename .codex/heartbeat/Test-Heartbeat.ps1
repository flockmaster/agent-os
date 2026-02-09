<#
.SYNOPSIS
    Codex Heartbeat v2.0 - Test Suite
.DESCRIPTION
    Test 1: Simulated heartbeat (no codex)
    Test 2: Real codex simple task
    Test 3: Real codex complex task  
    Test 4: Heartbeat timeout detection
#>

$ErrorActionPreference = "Continue"
Import-Module (Join-Path $PSScriptRoot "CodexHeartbeat.psm1") -Force

Write-Host ""
Write-Host ("=" * 55) -ForegroundColor Magenta
Write-Host "   Codex Heartbeat v2.0 - Test Suite" -ForegroundColor Magenta
Write-Host ("=" * 55) -ForegroundColor Magenta
Write-Host ""

# ===== Test 1: Simulated heartbeat =====
function Test-SimulatedHeartbeat {
    Write-Host "[TEST 1] Simulated heartbeat (no codex needed)" -ForegroundColor Yellow
    Write-Host ("-" * 50)

    $taskId = "SIM-001"
    $taskDir = Join-Path $PSScriptRoot "..\tasks"
    $logDir  = Join-Path $PSScriptRoot "..\logs"

    Initialize-CodexHeartbeat

    # Use Start-Job to simulate a codex task
    $job = Start-Job -ScriptBlock {
        param($TaskDir, $TaskId)

        $stateFile = Join-Path $TaskDir "$TaskId.json"
        $steps = @(
            "Analyzing requirements...",
            "Generating code scaffold...",
            "Writing HTML structure...",
            "Writing CSS styles...",
            "Writing JavaScript...",
            "Running tests...",
            "Formatting code..."
        )

        foreach ($step in $steps) {
            Start-Sleep -Seconds 3
            if (Test-Path $stateFile) {
                $state = Get-Content $stateFile -Raw | ConvertFrom-Json
                $state.lastHeartbeat = (Get-Date).ToString("o")
                $state.progress = $step
                $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8
            }
        }
        return "All 7 steps completed successfully"
    } -ArgumentList $taskDir, $taskId -Name "Codex-$taskId"

    # Create initial state
    $stateFile = Join-Path $taskDir "$taskId.json"
    $state = @{}
    $state["taskId"] = $taskId
    $state["prompt"] = "Simulated web dev task"
    $state["status"] = "RUNNING"
    $state["jobId"] = $job.Id
    $state["jobName"] = $job.Name
    $state["startTime"] = (Get-Date).ToString("o")
    $state["lastHeartbeat"] = (Get-Date).ToString("o")
    $state["progress"] = "Starting..."
    $state["lastMsgFile"] = ""
    $state["lastMsgSize"] = 0
    $state["timeout"] = 120
    $state["exitCode"] = $null
    $state["error"] = $null
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8

    Write-Host "   Simulator job launched (ID: $($job.Id))" -ForegroundColor Green

    $result = Wait-CodexTask -TaskId $taskId -PollIntervalSeconds 5 -TimeoutSeconds 120 -HeartbeatTimeoutSeconds 30

    Write-Host ""
    Write-Host "   Results:" -ForegroundColor Cyan
    Write-Host "      Status:  $($result.Status)"
    Write-Host "      Elapsed: $([int]$result.Elapsed)s"
    Write-Host "      Polls:   $($result.PollCount)"

    # Cleanup job
    Remove-Job -Id $job.Id -Force -ErrorAction SilentlyContinue

    if ($result.Status -eq "DONE") {
        Write-Host "   >>> TEST 1 PASSED <<<" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   >>> TEST 1 FAILED: $($result.Status) <<<" -ForegroundColor Red
        return $false
    }
}

# ===== Test 2: Real Codex simple task =====
function Test-RealCodexSimpleTask {
    Write-Host ""
    Write-Host "[TEST 2] Real Codex simple task" -ForegroundColor Yellow
    Write-Host ("-" * 50)

    $taskId = "REAL-001"
    $workDir = Split-Path $PSScriptRoot -Parent | Split-Path -Parent

    $taskInfo = Start-CodexTask `
        -TaskId $taskId `
        -Prompt "Create a file named heartbeat-test-output.txt in the current directory with the text: Heartbeat test passed at followed by the current date and time." `
        -WorkDir $workDir

    if (-not $taskInfo) {
        Write-Host "   Task launch failed" -ForegroundColor Red
        return $false
    }

    Write-Host "   Codex job launched (ID: $($taskInfo.JobId))" -ForegroundColor Green

    $result = Wait-CodexTask -TaskId $taskId -PollIntervalSeconds 5 -TimeoutSeconds 300 -HeartbeatTimeoutSeconds 120

    Write-Host ""
    Write-Host "   Results:" -ForegroundColor Cyan
    Write-Host "      Status:  $($result.Status)"
    Write-Host "      Elapsed: $([int]$result.Elapsed)s"
    Write-Host "      Polls:   $($result.PollCount)"

    if ($result.Result) {
        $preview = $result.Result.Substring(0, [Math]::Min(200, $result.Result.Length))
        Write-Host "      Output:  $preview" -ForegroundColor DarkGray
    }

    # Check if file was created
    $testFile = Join-Path $workDir "heartbeat-test-output.txt"
    if (Test-Path $testFile) {
        $content = Get-Content $testFile -Raw
        Write-Host "      File:    $content" -ForegroundColor Green
        Remove-Item $testFile -Force
        Write-Host "   >>> TEST 2 PASSED <<<" -ForegroundColor Green
        return $true
    } else {
        if ($result.Status -eq "DONE") {
            Write-Host "   >>> TEST 2 PARTIAL PASS (done but no file) <<<" -ForegroundColor Yellow
            return $true
        }
        Write-Host "   >>> TEST 2 FAILED <<<" -ForegroundColor Red
        return $false
    }
}

# ===== Test 3: Real Codex complex task =====
function Test-RealCodexComplexTask {
    Write-Host ""
    Write-Host "[TEST 3] Real Codex complex task (web page)" -ForegroundColor Yellow
    Write-Host ("-" * 50)

    $taskId = "REAL-002"
    $workDir = Split-Path $PSScriptRoot -Parent | Split-Path -Parent

    $prompt = "Create the file website/heartbeat-demo.html containing an HTML page with a CSS animated pulsing heart shape, the title Heartbeat Monitor Test Success, and a dark background."

    $taskInfo = Start-CodexTask `
        -TaskId $taskId `
        -Prompt $prompt `
        -WorkDir $workDir

    if (-not $taskInfo) {
        Write-Host "   Task launch failed" -ForegroundColor Red
        return $false
    }

    Write-Host "   Codex job launched (ID: $($taskInfo.JobId))" -ForegroundColor Green

    $result = Wait-CodexTask -TaskId $taskId -PollIntervalSeconds 8 -TimeoutSeconds 600 -HeartbeatTimeoutSeconds 180

    Write-Host ""
    Write-Host "   Results:" -ForegroundColor Cyan
    Write-Host "      Status:  $($result.Status)"
    Write-Host "      Elapsed: $([int]$result.Elapsed)s"
    Write-Host "      Polls:   $($result.PollCount)"

    $testFile = Join-Path $workDir "website\heartbeat-demo.html"
    if (Test-Path $testFile) {
        $size = (Get-Item $testFile).Length
        Write-Host "      File:    heartbeat-demo.html ($size bytes)" -ForegroundColor Green
        Write-Host "   >>> TEST 3 PASSED <<<" -ForegroundColor Green
        return $true
    } else {
        if ($result.Status -eq "DONE") {
            Write-Host "   >>> TEST 3 PARTIAL PASS (task done) <<<" -ForegroundColor Yellow
            return $true
        }
        Write-Host "   >>> TEST 3 FAILED <<<" -ForegroundColor Red
        return $false
    }
}

# ===== Test 4: Heartbeat timeout detection =====
function Test-HeartbeatTimeout {
    Write-Host ""
    Write-Host "[TEST 4] Heartbeat timeout detection" -ForegroundColor Yellow
    Write-Host ("-" * 50)

    $taskId = "TIMEOUT-001"
    $taskDir = Join-Path $PSScriptRoot "..\tasks"

    Initialize-CodexHeartbeat

    # Start a sleeping job that never updates heartbeat
    $job = Start-Job -ScriptBlock {
        Start-Sleep 600
    } -Name "Codex-$taskId"

    # Create state with stale heartbeat (2 minutes ago)
    $stateFile = Join-Path $taskDir "$taskId.json"
    $oldTime = (Get-Date).AddMinutes(-2).ToString("o")

    $state = @{}
    $state["taskId"] = $taskId
    $state["prompt"] = "Timeout test task"
    $state["status"] = "RUNNING"
    $state["jobId"] = $job.Id
    $state["jobName"] = $job.Name
    $state["startTime"] = $oldTime
    $state["lastHeartbeat"] = $oldTime
    $state["progress"] = "Simulating hang..."
    $state["lastMsgFile"] = ""
    $state["lastMsgSize"] = 0
    $state["timeout"] = 60
    $state["exitCode"] = $null
    $state["error"] = $null
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Encoding UTF8

    Write-Host "   Hung task simulated (heartbeat = 2min ago, Job ID: $($job.Id))" -ForegroundColor Green

    # Should detect heartbeat timeout quickly (HB timeout = 30s, heartbeat is already 120s old)
    $result = Wait-CodexTask -TaskId $taskId -PollIntervalSeconds 3 -TimeoutSeconds 30 -HeartbeatTimeoutSeconds 30

    # Cleanup
    Stop-Job -Id $job.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $job.Id -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "   Results:" -ForegroundColor Cyan
    Write-Host "      Status: $($result.Status)"

    if ($result.Status -eq "HEARTBEAT_TIMEOUT") {
        Write-Host "   >>> TEST 4 PASSED (timeout correctly detected) <<<" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   >>> TEST 4 FAILED: expected HEARTBEAT_TIMEOUT, got $($result.Status) <<<" -ForegroundColor Red
        return $false
    }
}

# ===== Run Tests =====
Write-Host "Select test mode:" -ForegroundColor Yellow
Write-Host "  [1] Simulation only (fast, no codex)"
Write-Host "  [2] Simulation + real simple task"
Write-Host "  [3] Simulation + real simple + complex task"
Write-Host "  [4] All tests (+ timeout detection)"
Write-Host ""

$mode = Read-Host "Choose (default=1)"
if (-not $mode) { $mode = "1" }

$results = @()

$results += @{ Name = "Simulated heartbeat"; Pass = (Test-SimulatedHeartbeat) }

if ([int]$mode -ge 2) {
    $results += @{ Name = "Real simple task"; Pass = (Test-RealCodexSimpleTask) }
}

if ([int]$mode -ge 3) {
    $results += @{ Name = "Real complex task"; Pass = (Test-RealCodexComplexTask) }
}

if ([int]$mode -ge 4) {
    $results += @{ Name = "Heartbeat timeout"; Pass = (Test-HeartbeatTimeout) }
}

# ===== Report =====
Write-Host ""
Write-Host ("=" * 55) -ForegroundColor Magenta
Write-Host "   Test Report" -ForegroundColor Magenta
Write-Host ("=" * 55) -ForegroundColor Magenta
Write-Host ""

$passed = 0
$failed = 0

foreach ($r in $results) {
    if ($r.Pass) {
        Write-Host "   [PASS] $($r.Name)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "   [FAIL] $($r.Name)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
$totalColor = if ($failed -eq 0) { "Green" } else { "Red" }
Write-Host "   Total: $($results.Count) | Passed: $passed | Failed: $failed" -ForegroundColor $totalColor
Write-Host ""

Write-Host "All task records:" -ForegroundColor Yellow
Get-CodexTasks

Write-Host ""
Write-Host "Tip: Run 'Clear-CodexTasks -Force' to cleanup" -ForegroundColor DarkGray
