---
description: 'Rollback — 回滚到上一个 Git 检查点'
mode: 'agent'
---

# /rollback — 回滚操作

将项目回滚到上一个 Git 检查点，撤销所有后续修改。

## ⚠️ 警告
此操作会丢弃自上次检查点以来的所有代码修改。需用户确认后执行。

## 步骤

### Step 1: 读取当前检查点
- 读取 `.agents/memory/active_context.md`
- 获取 `last_checkpoint` 字段
- 如果没有记录，运行 `git tag -l "checkpoint-*"` 列出所有检查点

### Step 2: 确认回滚
输出警告信息，要求用户确认：
```
⚠️ Rollback Confirmation
将回滚到: `[checkpoint-tag]`
以下修改将被丢弃: [列出自检查点以来的 commit]
确认回滚请输入 "Yes" 或 "确认"
```

### Step 3: 执行回滚 (用户确认后)
```
git reset --hard [checkpoint-tag]
git clean -fd
```

### Step 4: 更新状态
1. 将 `task_status` 更新为 `IDLE`
2. 清空当前任务队列
3. 记录回滚操作到 History

### Step 5: 报告结果

## 回滚失败处理
如果检查点不存在：
1. 列出所有可用的检查点 `git tag -l "checkpoint-*"`
2. 让用户选择要回滚到的检查点
