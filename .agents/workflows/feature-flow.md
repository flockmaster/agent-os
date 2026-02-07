---
description: Feature Delivery Pipeline - 全自动交付流水线
---

# Feature Flow (The Executor)

**PRD Driven Development** 的核心引擎。无限续航，直到所有任务完成或熔断。

## Phase 0: Pre-Flight Check (起飞前检查)
> **Mandatory**: 每次流水线启动前必须执行。

// turbo (自动执行环境检查)
0.1. **Conflict Detection (冲突检测)**:
   - **Run**: `git status --porcelain`
   - **IF** 有未提交的本地修改:
     - 询问用户: "检测到本地未提交的修改，是否 Stash 后继续？(Y/N)"
     - **IF Y**: `git stash push -m "auto-stash-before-flow"`
     - **IF N**: 终止流程，让用户先处理

// turbo (自动创建检查点)
0.2. **Checkpoint Creation (检查点创建)**:
   - **Run**: `git tag checkpoint-YYYYMMDD-HHMMSS`
   - **Output**: "✓ Checkpoint created: checkpoint-20260208-010800"
   - **Update Memory**: 在 `active_context.md` 中记录 `last_checkpoint`

## Phase 1: Planning & Confirmation
1. **Ambiguity Check**: Agent 自检需求是否模糊。若模糊，强制反问。
2. **PRD Generation**: 调用 `prd-crafter-lite` 生成 `docs/prd/[feature_name].md`。
3. **Wait for Confirmation**: 必须等待用户输入 "Confirm" / "Go" / "OK"。

## Phase 2: Execution Loop (Infinite)
> **Loop Condition**: While `Task Queue` has PENDING items.

// turbo (自动执行代码生成与文件写入)
4. **Code Generation**: 根据当前 Task 生成代码。

// turbo (自动执行静态检查)
5. **Static Analysis**: `flutter analyze`
   - **If Error**: Enter **Auto-Fix Loop** (Max 3 retries).

// turbo (自动执行测试)
6. **Testing**: `flutter test`
   - **If Fail**: Enter **Auto-Fix Loop** (Max 3 retries).

// turbo (自动检查测试覆盖率)
7. **Coverage Check (可选)**:
   - **Run**: `flutter test --coverage`
   - **Threshold**: 
     - 覆盖率 < 60%: ⚠️ 警告 (不阻塞流程)
     - 覆盖率 < 30%: 🔴 暂停并提醒用户

// turbo (自动执行提交)
8. **Commit**: `git add . && git commit -m "feat: [Task-ID] ..."`
9. **Update Memory**: 调用 `context-manager` -> `update_progress` (Mark Task as DONE).

## Phase 3: Completion
10. **Archive**: If all tasks DONE -> Archive detailed plan to `history/task_archive_YYYYMM.md`.
11. **Cleanup**:
    - **Run**: `git stash pop` (如果之前 Stash 过)
    - 删除超过 7 天的 checkpoint tags
12. **Report**: Output "All tasks completed. Commit ID: [Hash]. Coverage: [X]%."

## Auto-Fix Loop (自动修复循环)
> 最多尝试 3 次，每次尝试都记录到 Scratchpad。

```
RETRY_COUNT = 0
WHILE RETRY_COUNT < 3:
    1. 读取错误日志
    2. 分析根因
    3. 应用修复
    4. 重新验证
    IF 验证通过: BREAK
    ELSE: RETRY_COUNT++

IF RETRY_COUNT == 3:
    状态 -> BLOCKED
    调用 `analyze-error` 工作流
```

## Rollback Command (回滚命令)
> 当熔断后用户选择回滚时执行。

1. **Find Checkpoint**: 读取 `active_context.md` 中的 `last_checkpoint`
2. **Execute Rollback**: `git reset --hard [checkpoint-tag]`
3. **Clean State**: 清空 Task Queue，状态 -> IDLE
4. **Output**: "已回滚到 [checkpoint-tag]，请重新评估需求。"
