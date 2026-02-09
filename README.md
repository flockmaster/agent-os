<div align="center">

# 🌌 Antigravity Agent OS

### 给你的 AI 编程助手装上"大脑"

<br/>

**让 AI 不再是金鱼记忆，而是一个越用越聪明的编程搭档。**

<br/>

[![Evolution Engine v1.0](https://img.shields.io/badge/🧬_进化引擎-v1.0-blueviolet?style=for-the-badge)](docs/prd/evolution-engine.md)
[![Status](https://img.shields.io/badge/🟢_状态-可用-success?style=for-the-badge)](#-30-秒快速上手)
[![Framework](https://img.shields.io/badge/🔌_适配-任意项目-blue?style=for-the-badge)](#-适配任何项目)

</div>

---

## 🏁 一键安装

克隆仓库，运行初始化向导——脚本会交互式地帮你配好一切：

```bash
git clone https://github.com/flockmaster/agent-os.git
cd agent-os

# macOS / Linux
bash setup.sh /path/to/your-project

# Windows (PowerShell)
pwsh setup.ps1 -TargetDir "D:\your-project"
```

> 向导会询问你的**项目名称**、**技术栈**和**AI 工具**，然后自动完成：
> - 将 `.agent/` 复制到你的项目
> - 生成定制化的记忆文件
> - 写入 `.gitignore` 规则
> - 安装 AI 全局配置

<details>
<summary>📸 <b>安装向导长什么样？</b>（点击展开）</summary>
<br/>

```
╔══════════════════════════════════════════╗
║   🌌 Antigravity Agent OS — Setup        ║
║   给你的 AI 编程助手装上大脑              ║
╚══════════════════════════════════════════╝

🔧 Step 1/5 — 设置目标项目
   ✅ 目标目录: D:\my-awesome-app

🔧 Step 2/5 — 项目信息
   项目名称: My Awesome App
   选择技术栈:
     [1] Flutter / Dart
     [2] React / TypeScript
     [3] Vue / TypeScript
     ...
   ✅ 项目: My Awesome App | React / TypeScript / Component

🔧 Step 3/5 — 选择你的 AI 编程工具
     [1] Gemini
     [2] GitHub Copilot
     [3] Claude
   ✅ AI 工具: GitHub Copilot

🔧 Step 4/5 — 安装 Agent OS 到项目
   ✅ 已复制 .agent/
   ✅ 已初始化 project_decisions.md
   ✅ 已重置 active_context.md
   ✅ 已追加 .gitignore 规则

🔧 Step 5/5 — 安装 AI 全局配置
   ✅ 已安装全局配置

╔══════════════════════════════════════════╗
║   🎉 安装完成！                          ║
╚══════════════════════════════════════════╝
   👉 对 AI 说: /start
```

</details>

---

## 😤 痛不痛？

你有没有遇到过这些场景：

| 场景 | 痛感指数 |
|------|:------:|
| 新开一个聊天窗口，又要从头跟 AI 解释项目背景 | 🔥🔥🔥🔥🔥 |
| 让 AI 改完代码，它忘了 commit，你也忘了 | 🔥🔥🔥🔥 |
| 同样的 bug 上周修过一次，今天 AI 又走了一遍弯路 | 🔥🔥🔥🔥🔥 |
| 让 AI 写个功能，写一半停下来问"要继续吗？" | 🔥🔥🔥 |
| AI 每次都像新来的实习生，你是永远的导师 | 🔥🔥🔥🔥🔥 |

> **根本原因：AI Agent 没有记忆，没有流程，没有成长机制。**

Antigravity 就是解决这个问题 —— **一个 `.agent/` 文件夹，给你的 AI 装上大脑。**

---

## 🧠 它能做什么？

<table>
<tr>
<td width="50%">

### 💾 记得住事
AI 终于有了"长短期记忆"，不再每次从零开始。

- 🟢 **项目背景**：架构、技术栈、关键决策，只说一次就够
- 🟢 **工作进度**：关掉窗口明天接着干，断点续传
- 🟢 **你的偏好**：代码风格、沟通习惯，越用越懂你

</td>
<td width="50%">

### 🧬 学得会
每完成一个任务，AI 会自动总结经验教训。

- 🟢 **知识积累**：踩过的坑自动记录，绝不踩第二次
- 🟢 **模式识别**：自动发现代码中的通用模板
- 🟢 **效能优化**：追踪工作效率，自动调优流程

</td>
</tr>
<tr>
<td width="50%">

### 🚀 干得完
不再"做一步问一步"，而是全自动交付。

- 🟢 **一句话需求** → 自动生成方案 + 写代码 + 测试 + 提交
- 🟢 **报错自愈**：遇到 bug 自动修 3 轮，修不好再找你
- 🟢 **续航模式**：一个功能做完自动接下一个

</td>
<td width="50%">

### 🔌 搬得走
不绑定任何框架，哪个项目都能用。

- 🟢 **即插即用**：拷贝一个文件夹到项目里就行
- 🟢 **技术无关**：Flutter、React、Python、Go... 全都行
- 🟢 **团队共享**：打包给同事，开箱即用

</td>
</tr>
</table>

---

## ⚡ 30 秒快速上手

**方式一：运行安装向导（推荐）**

```bash
# 向导会交互式引导你完成所有配置
bash setup.sh /path/to/your-project       # macOS / Linux
pwsh setup.ps1 -TargetDir "D:\project"     # Windows
```

**方式二：手动安装**

```bash
# 1️⃣ 把 .agent/ 文件夹拷贝到你的项目根目录
cp -r .agent/ /path/to/your-project/

# 2️⃣ 编辑 .agent/memory/project_decisions.md，填入你的技术栈

# 3️⃣ 在 IDE 中打开项目，对 AI 说：
```

> **你说**：`/start`
> **AI 回**："系统就绪，记忆已加载。请吩咐。"

---

## 🎬 日常使用长什么样？

### 场景一：开发新功能

```
你：我想加一个微信登录功能
AI：好的，我已生成设计方案，请确认 ✅ → [查看方案]
你：Go!
AI：✅ 代码已写完 → ✅ 编译通过 → ✅ 测试通过 → ✅ 已提交 Git
    开始处理下一个任务...
```

### 场景二：隔天继续

```
你：早
AI：早！昨天做到"用户登录"模块的第 3 个子任务，还剩 2 个。继续？
你：继续
AI：🔨 Working...
```

### 场景三：遇到 Bug

```
你：（粘贴一大堆红色报错）
AI：检测到 NullPointerException...
    → 第 1 次修复尝试 ❌
    → 第 2 次修复尝试 ✅ 已解决！原因已记入知识库。
```

---

## 🗂️ 系统结构一览

```
.agent/                          ← 整个"大脑"就在这个文件夹里
│
├── 📂 memory/                   ← 记忆中枢
│   ├── active_context.md            今天在干嘛？（短期记忆）
│   ├── project_decisions.md         项目的"宪法"（长期记忆）
│   ├── user_preferences.md          你喜欢什么风格？
│   ├── 📂 evolution/               进化引擎数据
│   └── 📂 knowledge/               AI 积累的知识库
│
├── 📂 rules/                    ← 行为规则
│   └── router.rule                  任务分发路由
│
├── 📂 skills/                   ← 技能模块
│   ├── evolution-engine/            自进化引擎
│   ├── context-manager/             记忆管理器
│   └── prd-crafter/                 需求文档生成器
│
└── 📂 workflows/                ← 自动化流程
    ├── feature-flow.md              功能开发全流程
    ├── evolve.md                    学习与进化
    └── reflect.md                   复盘与反思
```

---

## 🔌 适配任何项目

Antigravity 与技术栈无关。只需修改一行配置：

```markdown
# .agent/memory/project_decisions.md

Tech Stack: Flutter / Dart / MVVM    ← 改成你的技术栈就行
```

| 已验证 | 理论兼容 |
|:------|:--------|
| Flutter / Dart | React / TypeScript |
| Python / Django | Vue / Nuxt |
| Node.js / Express | Go / Gin |

---

## ⌨️ 命令速查表

| 命令 | 干什么用 | 一句话说明 |
|:---:|---------|-----------|
| `/start` | ⚡ 开机 | 加载记忆，恢复上下文 |
| `/suspend` | 💾 存档 | 保存进度，下次接着干 |
| `/feature-flow` | 🚀 造功能 | 需求→方案→编码→测试→提交，一条龙 |
| `/analyze-error` | 🔥 灭火 | 智能分析报错，自动修复 |
| `/evolve` | 🧬 进化 | 整理知识库，让 AI 变聪明 |
| `/reflect` | 💭 复盘 | 总结经验教训 |
| `/status` | 📊 看板 | 当前任务做到哪了 |
| `/rollback` | ⏪ 后悔药 | 回到上一个安全版本 |
| `/meta` | 🔧 改系统 | 修改 AI 自身的行为规则 |
| `/export` | 📦 打包 | 导出干净的系统副本给别人 |

---

## 🔄 它是怎么运转的？

```mermaid
graph LR
    A((💤 空闲)) -->|你说了个需求| B(📝 规划)
    B -->|生成方案| C{👀 你确认}
    C -->|"Go!"| D[⚡ 执行中]
    D -->|报错了| E(🔧 自动修复)
    E -->|修好了| D
    E -->|修不好| F[🚨 求助人类]
    D -->|成功| G(📚 存档学习)
    G -->|还有任务| D
    G -->|全做完了| A
```

> **关键设计**：AI 遇到错误不会立刻停下，而是自动重试最多 3 次。只有真的搞不定才会打扰你。

---

## 📝 版本演进

| 版本 | 里程碑 |
|:---:|-------|
| **v3.0** 🆕 | 接入自进化引擎：知识收割 + 模式库 + 自动反思 |
| **v2.1** | 状态机 + Git 检查点保护 + 自动修复循环 |
| **v2.0** | 结构化记忆系统 + PRD 全流程自动化 |
| **v1.0** | 基础规则引擎 + 对话驱动 |

---

## 🤔 常见问题

<details>
<summary><b>Q：这跟直接写 Prompt 有啥区别？</b></summary>
<br/>
Prompt 是"一次性的叮嘱"，关掉窗口就没了。Antigravity 是"持久化的操作系统"——记忆、规则、知识库都存在文件里，AI 每次启动都自动加载。就像给 AI 从"每天新入职"变成"老员工"。
</details>

<details>
<summary><b>Q：会不会搞乱我的项目代码？</b></summary>
<br/>
不会。系统所有文件都在 <code>.agent/</code> 文件夹里，与你的业务代码完全隔离。加一行 <code>.gitignore</code> 就能控制哪些文件纳入版本管理。
</details>

<details>
<summary><b>Q：支持哪些 AI 工具？</b></summary>
<br/>
理论上支持所有能读取项目文件的 AI 编程助手（Cursor、Copilot、Gemini Code Assist 等）。核心原理是通过文件系统传递上下文，不依赖任何特定 API。
</details>

<details>
<summary><b>Q：记忆库会不会越来越大？</b></summary>
<br/>
不会。系统内置了"遗忘机制"——过期决策自动标记 Deprecated 并清理，完成的任务归档压缩，知识库定期整理去重。
</details>

---

<div align="center">

**⭐ 如果觉得有用，给个 Star 是最大的鼓励**

Made with 🧠 by **Antigravity Systems**

*让每一次对话，都不白聊。*

</div>
