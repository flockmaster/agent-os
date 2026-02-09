---
description: 'Knowledge — 查询项目知识库中的架构决策和最佳实践'
mode: 'agent'
---

# /knowledge — 知识查询

检索项目专属知识库，回答关于架构决策、最佳实践的问题。

用户输入格式: `/knowledge [查询关键词]`

## 步骤

### Step 1: 解析查询意图
- 识别用户输入的查询关键词
- 如果未输入查询词，提示: "请提供查询关键词，例如：`/knowledge 架构`"

### Step 2: 搜索知识库
1. 读取 `.agents/memory/evolution/knowledge_base.md` 索引（如存在）
2. 根据关键词匹配 Title、Category 或 Tags
3. 同时搜索 `.agents/memory/project_decisions.md`

### Step 3: 读取知识详情
- 对于前 3 个最相关的匹配项，读取对应的知识文件
- 提取 Summary 和 Code Example

### Step 4: 生成回答
- 输出知识摘要和代码示例（如有）
- 标注知识来源和置信度
