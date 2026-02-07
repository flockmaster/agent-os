---
description: 知识图谱索引 - 管理所有知识条目的元信息
version: 1.0
last_updated: 2026-02-08
---

# Knowledge Base (知识图谱索引)

本文件是知识系统的中央索引，记录所有知识条目的元信息。

## 1. 索引表 (Knowledge Index)

| ID | Title | Category | Confidence | Created | Status |
|----|-------|----------|------------|---------|--------|
| k-000 | (示例) Flutter 状态管理最佳实践 | architecture | 0.85 | 2026-02-08 | active |

## 2. 分类统计 (Category Stats)

| Category | Count | Description |
|----------|-------|-------------|
| architecture | 0 | 架构相关知识 |
| debugging | 0 | 调试技巧 |
| pattern | 0 | 代码模式 |
| workflow | 0 | 工作流相关 |
| tooling | 0 | 工具使用 |

## 3. 标签云 (Tag Cloud)

> 使用频率: (tag: count)

- flutter: 0
- dart: 0
- stacked: 0
- state-management: 0

## 4. 知识质量管理

### 4.1 Confidence 分数说明
- `0.9+`: 高置信度，经过多次验证
- `0.7-0.9`: 中等置信度，单次成功经验
- `0.5-0.7`: 低置信度，需要更多验证
- `<0.5`: 待清理，可能已过时

### 4.2 清理规则
- Confidence < 0.5 且超过 30 天未使用 → 标记为 `deprecated`
- `deprecated` 状态超过 7 天 → 删除

## 5. 最近更新 (Recent Updates)

| Date | Action | Knowledge ID | Notes |
|------|--------|--------------|-------|
| 2026-02-08 | init | - | 知识库初始化 |
