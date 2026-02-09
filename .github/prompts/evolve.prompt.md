---
description: 'Evolve — 手动触发进化引擎，处理学习队列并优化系统'
mode: 'agent'
---

# /evolve — 进化工作流

手动触发完整的进化周期，包括知识收割、模式检测、工作流优化。

## 步骤

### Step 1: 检查学习队列
- 读取 `.agents/memory/evolution/learning_queue.md`（如存在）
- 统计待处理素材数量

### Step 2: 处理学习素材
对于队列中每个素材，根据类型处理：
- `code_change`: 分析代码变更，提取模式
- `error_fix`: 提取错误解决方案，更新 Known Issues
- `workflow_run`: 更新工作流指标

### Step 3: 更新知识库
- 将新知识追加到 `knowledge_base.md`
- 更新分类统计和标签

### Step 4: 检测代码模式
- 读取 `pattern_library.md`
- 检查是否有新模式可以提升 (occurrences >= 3)

### Step 5: 分析工作流效能
- 读取 `workflow_metrics.md`
- 计算平均耗时、成功率、常见瓶颈

### Step 6: 处理反思日志
- 读取 `reflection_log.md`
- 检查未完成的 Action Items

### Step 7: 生成进化报告
输出完整的进化报告，包括知识更新、模式检测、工作流洞察和推荐行动。
