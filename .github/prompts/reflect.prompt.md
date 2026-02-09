---
description: 'Reflect — 反思总结，提取经验教训和知识'
mode: 'agent'
---

# /reflect — 反思工作流

执行自动反思，总结本次会话的经验教训，提取可复用的知识。

## 步骤

### Step 1: 读取会话状态
- 读取 `.agents/memory/active_context.md`
- 解析任务完成情况

### Step 2: 生成反思报告
分析本次会话：
- 任务完成率 = 已完成 / 总任务数
- 自动修复次数
- 回滚次数
- 遇到的问题和解决方案

### Step 3: 提取知识
- 识别 "What Went Well" 中的可复用经验
- 如有新知识，创建知识条目到 `.agents/memory/knowledge/`
- 更新 `knowledge_base.md` 索引

### Step 4: 提取 Action Items
- 识别改进点
- 将 Action Items 添加到 `active_context.md`

### Step 5: 追加到反思日志
- 将报告追加到 `.agents/memory/evolution/reflection_log.md`

### Step 6: 输出报告
向用户展示反思摘要、新提取的知识和 Action Items
