---
description: Zero-Touch Boot - 零触感启动，自动接力任务
---

# Start Workflow (Silent Boot)

Agent 开窗后的第一反应，用于偷偷读取上下文。

1. **Invoke Skill**: `context-manager` -> `read_context`
   - **Check**: Look for PENDING tasks in `.agent/memory/active_context.md`.
2. **Decision Point**:
   - **IF PENDING**: Output "检测到未完成任务 [Task-ID]，是否继续？"
   - **IF IDLE**: Output "系统就绪，请问接下来做什么？"
3. **Environment Check**:
   - **Run**: `flutter doctor` (Silent check, only alert on error).
4. **Heartbeat Module** (T-AGENT-02):
   - 检测 Codex CLI 是否可用: `Get-Command codex`
   - 如果可用，自动加载心跳模块:
     ```powershell
     Import-Module .agent/dispatcher/CodexHeartbeat.psm1
     Initialize-CodexHeartbeat
     ```
   - 检查是否有残留的运行中任务: `Get-CodexTasks`
   - 如果有运行中任务，提示用户是否要继续监控
