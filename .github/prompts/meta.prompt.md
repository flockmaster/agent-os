---
description: 'Meta — 修改 Agent OS 系统本身（工作流、技能、规则等）'
mode: 'agent'
---

# /meta — 系统修改命令

当需要改进 Antigravity Agent OS 系统本身（而非项目业务代码）时使用。

用户输入格式: `/meta [修改描述]`

## 可修改范围
| 模块 | 路径 |
|------|------|
| 工作流 | `.agents/workflows/*.md` |
| 技能 | `.agents/skills/*/SKILL.md` |
| 路由规则 | `.agents/rules/router.rule` |
| 记忆模板 | `.agents/memory/*.md` |
| 进化引擎 | `.agents/memory/evolution/*.md` |
| Copilot 指令 | `.github/copilot-instructions.md` |
| Copilot Prompts | `.github/prompts/*.prompt.md` |

**禁止修改**: 业务代码 (`lib/`, `test/`, `pubspec.yaml`)

## 步骤

### Step 1: 识别修改意图
- 解析用户的修改描述
- 判断涉及的系统模块

### Step 2: 读取当前配置
- 读取相关的配置文件
- 理解当前结构和逻辑

### Step 3: 执行修改
- 按照用户描述修改配置文件
- 保持与现有系统的格式一致性

### Step 4: 验证一致性
- 检查修改后是否与其他模块冲突
- 如有路由表相关修改，同步更新 `router.rule`

### Step 5: 提交变更
- Git commit message 前缀使用 `meta:`
