---
created: 2026-02-10
last_updated: 2026-02-10
status: ACTIVE
---

# 📋 Antigravity Agent OS — 待办事项 (Backlog)

> 本文档记录所有已识别但尚未完成的工作项，避免遗忘。
> 完成后将对应条目状态改为 ✅ 并记录完成日期。

---

## 一、安装脚本 — Hooks 未被安装 🔴 HIGH

### 问题描述

`setup.ps1` 的 Step 4 只做了 `Copy-Item .agent/ → 目标项目/.agent/`，
但 **从未调用** `python .agent/guards/install_hooks.py` 来把钩子部署到 `.git/hooks/`。

也就是说：用户执行安装后，`.agent/guards/` 目录里有完整的 Hook 文件，
但 `.git/hooks/` 里没有，**所有 Guard 功能都不会生效**。

### 受影响的钩子文件

| 文件 | 功能 | 当前状态 |
|------|------|---------|
| `pre-commit` / `pre-commit.ps1` | 检查 active_context.md 是否更新、冲突检测、TODO 扫描 | ❌ 未安装到 .git/hooks |
| `post-commit` / `post-commit.ps1` | 自动打 checkpoint tag、提交统计 | ❌ 未安装到 .git/hooks |
| `session_watchdog.py` | 监控 context 超时，终端提醒 | ⚠️ 需手动启动，未集成 |
| `status_dashboard.py` | /status 仪表盘生成器 | ⚠️ 需手动调用 |
| `install_hooks.py` | Hook 自动安装器 | ✅ 存在但未被 setup.ps1 调用 |

### 待办

- [ ] **T-HOOK-01**: `setup.ps1` Step 4 结尾增加调用 `python .agent/guards/install_hooks.py`
- [ ] **T-HOOK-02**: `setup.sh` (bash 版) 同步增加 hook 安装步骤
- [ ] **T-HOOK-03**: 安装后验证 `.git/hooks/pre-commit` 是否存在并给出反馈
- [ ] **T-HOOK-04**: 考虑 Windows 上 `.git/hooks/pre-commit` 是 bash 脚本，Git for Windows 能执行，但也应优先使用 `.ps1` 版本的逻辑（或自动检测环境）

---

## 二、心跳模块 — 待解决问题 🟡 MEDIUM

### 已完成

- ✅ `CodexHeartbeat.psm1` v2.0 核心模块（Start-Job 方案）
- ✅ `Test-Heartbeat.ps1` 测试套件 4/4 通过
- ✅ Start-Job 异步启动 + 轮询监控方案验证通过
- ✅ 心跳超时检测（2分钟无活动报 HEARTBEAT_TIMEOUT）
- ✅ Job 输出计数（ChildJobs[0].Output.Count）精准检测

### 待解决

- [ ] **T-HB-01**: Codex sandbox 只读问题
  - **现象**: Start-Job 内 `codex exec --full-auto` 使用 `workspace-write` 沙箱，但实际无法写入文件
  - **影响**: 任务"完成"但产物文件未生成（partial pass）
  - **方案**: 考虑 `--sandbox danger-full-access` 或 `--add-dir` 参数
  
- [ ] **T-HB-02**: 心跳模块集成到 `.agent/` 体系
  - 当前位置: `.codex/heartbeat/CodexHeartbeat.psm1`（临时测试位置）
  - 目标位置: 应移入 `.agent/dispatcher/` 或 `.agent/guards/` 下
  - 需要在 `.agent/config/agent_config.md` 中注册心跳配置
  
- [ ] **T-HB-03**: 更新 `codex-dispatch.md` 工作流
  - Step 5 (启动 Codex Worker) 应集成 `Start-CodexTask` 替代直接 `codex exec`
  - Step 6 (实时监控) 应集成 `Wait-CodexTask` 的心跳轮询
  - 新增心跳超时处理分支
  
- [ ] **T-HB-04**: 多任务并行心跳
  - 当前模块支持多 Job 记录，但未实现真正并行调度
  - 需要 `Start-CodexTaskPool` 批量启动 + 汇总等待
  
- [ ] **T-HB-05**: 心跳数据持久化与恢复
  - 当前 JSON state 文件仅在运行时有效
  - 需要支持：PM 窗口关闭后重新 attach 已有 Job
  - PowerShell 的 `Start-Job` 不跨进程持久化，需要考虑替代方案

- [ ] **T-HB-06**: 心跳模块的 bash/Unix 版本
  - 当前仅有 PowerShell 实现
  - macOS/Linux 用户需要等价的 bash 实现

---

## 三、.agent 文件联动更新 🟡 MEDIUM

心跳和调度改动后，以下 `.agent/` 文件需要同步更新：

### 工作流文件

- [ ] **T-AGENT-01**: `.agent/workflows/codex-dispatch.md`
  - 增加心跳监控章节
  - Step 5 加入 `Start-CodexTask` 用法
  - Step 6 改为心跳轮询模式
  - 新增心跳超时决策流程

- [ ] **T-AGENT-02**: `.agent/workflows/start.md`
  - 启动流程中提示：如果有 Codex CLI，自动加载心跳模块
  - `Import-Module .agent/dispatcher/CodexHeartbeat.psm1`（迁移后路径）

- [ ] **T-AGENT-03**: `.agent/workflows/status.md`
  - 增加正在执行的 Codex 任务心跳状态展示
  - 集成 `Get-CodexTasks` 输出

### 调度器代码

- [ ] **T-AGENT-04**: `.agent/dispatcher/worker.py`
  - 考虑 Python 版心跳实现（比 PowerShell 更跨平台）
  - 或在 worker.py 中调用 PowerShell 模块

- [ ] **T-AGENT-05**: `.agent/dispatcher/core.py` / `main.py`
  - 注册心跳模块作为调度器的可选组件

### 配置文件

- [ ] **T-AGENT-06**: `.agent/config/agent_config.md`
  - 增加心跳相关配置项：
    ```
    HEARTBEAT_TIMEOUT: 120       # 秒
    HEARTBEAT_POLL_INTERVAL: 5   # 秒
    CODEX_SANDBOX_MODE: workspace-write
    TASK_LOG_DIR: .codex/logs
    ```

### 记忆文件

- [ ] **T-AGENT-07**: `.agent/memory/active_context.md`
  - 模板中增加"活跃 Codex 任务"区块（心跳状态表）

### 设计文档

- [ ] **T-AGENT-08**: `docs/task-monitoring-heartbeat.md`
  - 将测试结果和最终方案（Start-Job + ChildJobs Output Count）补充到文档
  - 标记方案 A (文件轮询) 为已实现
  - 记录已知限制（sandbox 只读、跨进程不持久化）

---

## 四、网页内容丰富 🟡 MEDIUM

当前网页 (`website/index.html`) 缺少以下关键内容的深入介绍：

### 4.1 Git Hooks / Guards 系统

- [ ] **T-WEB-01**: 新增 "🛡️ 智能守卫" 功能卡片
  - pre-commit: 上下文同步检查、冲突检测、TODO 扫描
  - post-commit: 自动 checkpoint tag
  - session watchdog: 超时提醒
  - status dashboard: 实时仪表盘
  - 一键安装 (`install_hooks.py`)

### 4.2 PM + Worker 工作模式

- [ ] **T-WEB-02**: 新增 "PM-Worker 协作架构" 详细介绍章节
  - PM (Antigravity) 的角色：读 PRD、拆任务、决策、监控
  - Worker (Codex) 的角色：接 Prompt、写代码、报告完成
  - 调度循环图（Step 1~9 的可视化流程）
  - 会话管理三件套：exec (新建) / resume (恢复) / fork (分叉)
  - 失败重试策略和阻塞处理

- [ ] **T-WEB-03**: 扩充架构图
  - 当前架构图只有 4 层静态方块
  - 需要：加入心跳监控层、Guards 层
  - 需要：加入数据流箭头（PRD → PM → Codex → Git → Checkpoint）
  - 考虑: 用动画展示任务流转过程

### 4.3 心跳监控

- [ ] **T-WEB-04**: 新增 "💓 心跳监控" 功能卡片或章节
  - 展示单窗口多任务监控能力
  - 心跳超时检测机制
  - 实时状态轮询效果（可做动画演示）

### 4.4 演示增强

- [ ] **T-WEB-05**: 终端演示增加心跳监控场景
  - 当前只演示了 dispatch 流程
  - 增加：任务挂起 → 心跳超时 → 自动恢复的演示动画

- [ ] **T-WEB-06**: 增加 PM-Worker 对话演示
  - 展示 PM 如何自动回答 Worker 的技术问题
  - 展示 resume / fork 的决策过程

### 4.5 其他改进

- [ ] **T-WEB-07**: 完善功能特性对比表
  - 传统 AI 编程 vs Antigravity 的对比
  - v2.0 脚本驱动 vs v3.0 Agent 原生的对比

- [ ] **T-WEB-08**: 增加用户评价 / 使用场景区块
  - 真实使用案例
  - 适用场景说明

---

## 五、优先级排序

| 优先级 | 编号 | 工作项 | 预估工时 |
|--------|------|--------|---------|
| 🔴 P0 | T-HOOK-01~04 | 安装脚本补装 Hooks | 1h |
| 🟡 P1 | T-HB-01 | Sandbox 只读问题修复 | 2h |
| 🟡 P1 | T-AGENT-01 | codex-dispatch.md 集成心跳 | 2h |
| 🟡 P1 | T-HB-02 | 心跳模块迁移到 .agent/ | 1h |
| 🟡 P2 | T-AGENT-02~08 | 其余 .agent 文件更新 | 3h |
| 🟡 P2 | T-WEB-01~04 | 网页内容丰富（核心功能） | 4h |
| 🔵 P3 | T-WEB-05~08 | 网页内容丰富（演示增强） | 3h |
| 🔵 P3 | T-HB-03~06 | 心跳高级功能 | 4h |

**总预估**: ~20h

---

## 六、备注

- 网页本地预览: `python -m http.server 8080 -d website/`
- 心跳测试: `cd .codex/heartbeat && powershell -File Test-Heartbeat.ps1`
- Hook 手动安装: `python .agent/guards/install_hooks.py`
- 所有变更完成后应更新 `README.md` 和 `AGENT.md`
