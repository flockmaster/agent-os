---
description: 'Session Suspend — 会话暂存，保存状态并生成总结'
mode: 'agent'
---

# /suspend — 会话收尾工作流

用户要求暂停/休息/保存/暂存时触发。保存当前状态，确保下次会话能无缝接力。

## Phase 1: 状态快照 (State Snapshot)
1. 获取当前时间，记录会话结束时间
2. 收集进度信息：
   - 当前正在执行的 Task ID
   - Task Queue 中的 PENDING / DONE / BLOCKED 统计
   - Scratchpad 中的临时笔记

## Phase 2: 更新记忆文件 (Memory Update)
3. 更新 `.agents/memory/active_context.md`：
   - 更新 `task_status` (如果任务全部完成则设为 IDLE)
   - 更新 `last_session_end` 为当前时间
   - 保存当前 Task Queue 状态
   - 记录 `last_checkpoint` 标签

## Phase 3: Git 快照
4. 检查是否有未提交的修改 (`git status`)
5. 如有修改，执行 `git add -A && git commit -m "wip: session suspend"`
6. 创建检查点标签: `git tag checkpoint-YYYYMMDD-HHMMSS`

## Phase 4: 会话总结
7. 输出本次会话的工作总结：
   - 完成的任务列表
   - 未完成的任务 (下次继续)
   - 遇到的问题和临时方案
   - 关键决策记录

## 输出格式
```
## 💤 Session Suspended

**会话时间**: [开始] ~ [结束]
**完成任务**: X/Y
**检查点**: checkpoint-YYYYMMDD-HHMMSS

### 已完成
- [T-xxx] 任务名称

### 待继续
- [T-xxx] 任务名称 (进度: XX%)

### 备忘
- [关键笔记]

---
下次使用 `/start` 自动接力
```
