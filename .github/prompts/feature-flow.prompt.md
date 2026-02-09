---
description: 'Feature Flow — PRD 驱动的全自动交付流水线'
mode: 'agent'
---

# /feature-flow — 全自动交付流水线

PRD Driven Development 的核心引擎。读取研发版 PRD，递归拆解并执行所有任务。

## Phase 0: 起飞前检查
1. **冲突检测**: `git status --porcelain`
   - 如有未提交修改 → 询问用户是否 Stash
2. **检查点创建**: `git tag checkpoint-YYYYMMDD-HHMMSS`

## Phase 1: PRD 加载
1. 读取研发版 PRD: `docs/prd/[feature_name]-dev.md`
2. 加载任务队列到 `active_context.md`
3. 状态更新: `task_status` → `EXECUTING`

## Phase 2: 递归执行循环
3 层递归拆解: 任务 → 子任务 → 原子任务

对于每个任务：
1. 判断是否可在 1 小时内完成
2. 如果不行，拆解为 5-10 个子任务
3. 对每个子任务继续判断和拆解
4. 执行原子任务: 编码 → 测试 → 提交 (micro-commit)

每个原子任务完成后：
- 静态分析检查
- 测试执行
- 如有错误 → Auto-Fix Loop (最多 3 次重试)
- Git 提交: `feat: [Task-ID.SubID.AtomID] ...`
- 更新进度

## Phase 3: 收尾
- 归档已完成任务
- `git stash pop` (如之前有 Stash)
- 生成完成报告

## Auto-Fix Loop
最多 3 次：读取错误 → 分析根因 → 修复 → 验证
第 3 次仍失败 → 标记 BLOCKED → 调用 `/analyze-error`
