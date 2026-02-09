---
description: 'Export — 导出 Agent OS 系统为可移植压缩包'
mode: 'agent'
---

# /export — 系统导出

从当前项目中提取 Antigravity Agent OS 的完整或模板版本，生成可复用的压缩包。

用户输入格式: 
- `/export` 或 `/export template` — 模板导出（默认，清空项目特定数据）
- `/export full` — 完整导出（含所有知识和历史）

## 模式 1: Template (模板导出) — 默认

**包含**: `.agents/` 目录结构、README.md  
**清空/重置**: active_context.md、knowledge/、evolution 文件、history/  
**保留**: 工作流定义、技能定义、路由规则、状态机、用户偏好模板

## 模式 2: Full (完整导出)

**包含**: 所有文件，原样打包

## 步骤

### Step 1: 确定导出模式
- 解析用户输入，默认为 `template`

### Step 2: 创建临时目录并复制系统文件
```powershell
$exportDir = "$env:TEMP\antigravity-export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $exportDir
Copy-Item -Recurse ".agents" "$exportDir\.agents"
Copy-Item "README.md" "$exportDir\README.md"
```

### Step 3: Template 模式清理 (仅 template 模式)
- 重置 active_context.md
- 清空 knowledge/ 目录
- 重置 evolution/ 目录为初始模板

### Step 4: 生成压缩包
```powershell
Compress-Archive -Path "$exportDir\*" -DestinationPath "antigravity-agent-os-$(Get-Date -Format 'yyyyMMdd').zip"
```

### Step 5: 清理临时目录并输出结果
