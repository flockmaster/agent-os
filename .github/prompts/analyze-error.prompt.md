---
description: 'Analyze Error — 错误智能分析与自动修复'
mode: 'agent'
---

# /analyze-error — 错误分析工作流

当遇到编译错误、测试失败或用户直接抛出报错时执行智能分析和修复。

## Phase 1: 日志收集
1. 收集构建日志（编译输出、分析器输出）
2. 收集测试日志（失败详情）
3. 收集 Git 状态: `git diff HEAD~1` 查看最近代码变更

## Phase 2: 差异分析
4. 获取检查点: 读取 `active_context.md` 中的 `last_checkpoint`
5. 对比差异: `git diff [last_checkpoint]..HEAD`
6. 定位变更文件: 识别出问题可能出在哪些文件

## Phase 3: 根因分析
7. **模式匹配**: 检查 `.agents/memory/project_decisions.md` 的 `Known Issues` 是否有类似错误
   - IF 匹配: 直接应用历史修复方案
8. **AI 推理**: 基于上下文分析可能的根因

## Phase 4: 解决方案
- **Option A - Auto-Fix (高置信度 > 80%)**: 自动应用修复，重新验证
- **Option B - Rollback**: 执行 `git reset --hard [last_checkpoint]`
- **Option C - Skip Task**: 将当前任务标记为 BLOCKED，继续下一个

## Phase 5: 学习记录
- 将此错误的模式写入 `project_decisions.md` 的 `## Known Issues`
- 更新 `active_context.md` 的 Scratchpad
