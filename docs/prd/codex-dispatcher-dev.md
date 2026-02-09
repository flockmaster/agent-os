# PRD: Codex Task Dispatcher (研发版)

> 版本: 2.0 | 日期: 2026-02-09 | 状态: 待确认

## 1. 技术背景

### 1.1 架构概览

Dispatcher v2.0 采用 **PM (Orchestrator) ↔ Worker (Executor)** 模式。

- **PM**: 运行在 Antigravity OS 中的 Python 脚本/模块
- **Worker**: 独立的 `codex exec` 进程 (CLI)
- **通信**:
  - PM → Worker: 启动参数 (Prompt) + 重启注入 (Context Injection)
  - Worker → PM: `stdout` JSONL 事件流

### 1.2 核心组件

| 组件 | 职责 | 实现方式 |
|-----|------|---------|
| **Task Scheduler** | 维护任务依赖图，选择下一个任务 | Python DAG |
| **Worker Process** | 执行具体任务 | `subprocess.Popen(["codex", ...])` |
| **Event Stream Parser** | 解析 Worker 输出 | JSONL Parser |
| **Intervention Handler** | 处理提问和阻塞 | 语义分析 + User 交互 |

---

## 2. 任务拆解 (第1层 - 10个大任务)

> ⚠️ **重要**: 请勿修改任务 ID (T-XXX)，否则自动化调度将失效。

| ID | 任务 | 状态 | 描述 | 预估 | 依赖 |
|----|------|------|------|-----|------|
| T-001 | **实现基础调度器 (Scheduler)** | ⏳ PENDING | 读取 PRD，解析 Markdown 表格，构建任务依赖图 | 2h | - |
| T-002 | **实现 Worker 封装器 (Wrapper)** | ⏳ PENDING | 封装 `codex exec` 调用，支持 JSONL 解析和超时控制 | 3h | T-001 |
| T-003 | **实现交互式监控 (Monitor)** | ⏳ PENDING | 实时显示 Worker 进度，识别 PENDING 状态 | 2h | T-002 |
| T-004 | **实现语义提问识别** | ⏳ PENDING | 解析 Agent 输出，识别"疑问句"并提取问题 | 3h | T-003 |
| T-005 | **实现"重启注入"机制** | ⏳ PENDING | 终止进程，构造新 Prompt (含答案)，重启 Worker | 2h | T-002 |
| T-006 | **实现 User 交互接口** | ⏳ PENDING | 当 Worker 阻塞时，向用户展示问题并获取输入 | 2h | T-004 |
| T-007 | **集成 Git 自动提交** | ⏳ PENDING | 任务完成后自动执行 git commit | 1h | T-002 |
| T-008 | **实现"智能跳过"逻辑** | ⏳ PENDING | 任务阻塞时，自动查找无依赖的下一任务 | 2h | T-001 |
| T-009 | **实现 PRD 状态回写** | ⏳ PENDING | 将执行结果 (DONE/BLOCKED) 实时写回 PRD Markdown | 1h | T-001 |
| T-010 | **集成测试与文档** | ⏳ PENDING | 端到端测试，更新用户手册 | 2h | T-009 |

---

## 3. 风险缓解计划

| 风险 | 缓解措施 |
|-----|---------|
| **Codex 上下文限制** | 每次重启 Worker 都会重新加载上下文，需确保 Prompt 包含必要历史摘要。**v2.1 考虑增量 Context 缓存**。|
| **JSONL 解析异常** | 增加异常捕获，若解析失败则回退到 raw text 记录。 |
| **僵尸进程** | 在 PM 退出钩子 (atexit) 中强制 kill 所有子进程。 |

---

## 4. 测试策略

### 4.1 单元测试
- **TaskParseTest**: 测试能否正确解析 Markdown 任务表
- **DependencyTest**: 测试依赖图构建和拓扑排序
- **JsonlParserTest**: 测试各种 Worker 输出的解析

### 4.2 集成测试
- **MockWorker**: 模拟一个会提问的 Worker，测试 PM 的回答注入流程
- **TimeoutTest**: 模拟死循环 Worker，验证超时终止机制

---

## 5. 里程碑

| Milestone | 包含任务 | 预计完成 | 目标 |
|-----------|---------|---------|------|
| **M1: 核心执行器** | T-001 ~ T-003 | Day 1 | 能跑通"非交互式"任务 |
| **M2: 交互与增强** | T-004 ~ T-006 | Day 2 | 支持 Worker 提问和 PM 回答 |
| **M3: 完整自动化** | T-007 ~ T-010 | Day 3 | 全自动调度 + 状态回写 |

---

## 6. 执行协议 (Worker Protocol)

> 本文档是自动化执行的单一事实来源 (SSOT)。

### 状态流转
- **PENDING**: 等待执行
- **DONE**: 任务已完成且通过验证
- **BLOCKED**: 任务阻塞 (等待 User)
- **SKIPPED**: 临时跳过

### 执行规则
1. **自动领取**: Worker 应选择第一个状态为 `PENDING` 且依赖已满足的任务。
2. **原子提交**: 每个任务完成后必须进行 Git 提交。
3. **自我更新**: 任务完成后，**必须**将本文档中对应的状态更新为 `✅ DONE`。
