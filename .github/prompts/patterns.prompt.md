---
description: 'Patterns — 查询代码模式库的可复用模板'
mode: 'agent'
---

# /patterns — 模式查询

检索项目专属代码模式库，查找可复用的架构模式、UI 组件或工具类。

用户输入格式: `/patterns [查询关键词]`

## 步骤

### Step 1: 解析查询意图
- 识别用户输入的查询关键词
- 如果未输入查询词，提示: "请提供查询关键词，例如：`/patterns repository`"

### Step 2: 搜索模式库
- 读取 `.agents/memory/evolution/pattern_library.md`（如存在）
- 搜索 Pattern Index 表中的 Title、Category 或 Description

### Step 3: 读取模式详情
- 对于匹配的模式，提取 Description 和 Template
- 包含代码示例

### Step 4: 生成回答
- 输出模式摘要和代码模板
- 说明使用场景和注意事项
