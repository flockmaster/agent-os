---
description: 'Status — 显示当前系统状态和任务进度'
mode: 'agent'
---

# /status — 状态查询

显示系统当前的状态机状态、任务队列进度和关键指标。

## 步骤

### Step 1: 读取当前状态
- 读取 `.agents/memory/active_context.md`
- 解析 YAML frontmatter 获取 `task_status`

### Step 2: 统计任务进度
- 统计 Task Queue 中各状态任务数量 (PENDING/EXECUTING/DONE/BLOCKED)
- 计算完成百分比

### Step 3: 读取工作流指标
- 读取 `.agents/memory/evolution/workflow_metrics.md`（如存在）
- 提取最近的执行统计

### Step 4: 生成状态报告
```
## 📊 System Status

**状态**: [IDLE / EXECUTING / BLOCKED]
**活动 PRD**: [PRD 名称或无]

### 任务进度
| 状态 | 数量 |
|------|------|
| ✅ Done | X |
| 🔄 Executing | X |
| ⏳ Pending | X |
| 🚫 Blocked | X |
| 完成率 | XX% |

### 最近活动
| 任务 | 状态 | 备注 |
|------|------|------|
| T-xxx | ✅ | ... |

### 系统指标
- 知识库条目: X
- 代码模式: X
- 最近检查点: checkpoint-xxx
```
