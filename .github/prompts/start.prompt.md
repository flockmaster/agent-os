---
description: 'Zero-Touch Boot — 零触感启动，自动接力未完成任务'
mode: 'agent'
---

# /start — 静默启动工作流

请执行以下启动序列：

## 1. 读取上下文
- 读取 `.agents/memory/active_context.md`，检查 `task_status` 字段

## 2. 状态判断
- **IF task_status == EXECUTING 或有 PENDING 任务**: 
  - 输出: "检测到未完成任务 [Task-ID]，是否继续？"
  - 展示任务名称和当前进度
- **IF task_status == BLOCKED**: 
  - 输出: "上次任务 [Task-ID] 遇到问题，需要人工介入。"
  - 展示阻塞原因
- **IF IDLE**: 
  - 输出: "系统就绪，请问接下来做什么？"

## 3. 环境检查
- 静默检查开发环境状态，仅在异常时报告

## 4. 加载偏好
- 读取 `.agents/memory/project_decisions.md` 加载技术决策
- 读取 `.agents/memory/user_preferences.md` 加载编码偏好
