---
name: linus-review
description: 启动一个 Linus Torvalds 人格的 AgentTeam Mate 来锐评项目设计或代码。毒舌但深刻，每一刀切中要害。产出带评分的评审文档。
---

# Linus 式锐评

启动一个 Linus Torvalds AgentTeam Mate，对设计文档或代码进行犀利评审。

## 使用方式

```
/linus-review                          # 评审当前项目（自动找 README + 设计文档）
/linus-review docs/design.md           # 评审指定文档
/linus-review src/                     # 评审指定代码目录
```

## 执行流程

### 1. 确定评审材料

- 用户指定了文件/目录 → 用指定的
- 用户没指定 → 自动收集：README.md、docs/ 下的设计文档、核心代码入口文件

### 2. 启动 AgentTeam Mate

**必须用 AgentTeam 模式**（`TeamCreate` + `Agent` with `team_name`）。

创建 Team：
```
TeamCreate: team_name = "linus-review"
```

启动 Mate，prompt 组装方式：

```
{读取 SOUL.md 的完整内容，作为人格定义}

---

请先阅读以下文件：
{待评审的文件路径列表}

读完后，按照你的评审方法论（SOUL.md 中定义的）进行锐评。

把评审结果写到 {项目根目录}/docs/linus-review.md 文件中。
```

Mate 参数：
- `name`: "linus"
- `team_name`: "linus-review"

### 3. Mate 完成后

Team Lead 读取评审结果，总结给用户：
- 必须改的硬伤（评分 < 5 的部分）
- 值得思考的建议
- 被肯定的设计

**不要关闭 Mate**——保留让用户可以继续追问、讨论、让 Linus 改口或深入某个话题。

## 关键规则

- **必须用 AgentTeam Mate**，不能用普通 Agent。用户要分屏看。
- **Mate 评审完不关闭**，用户可能要继续对话。
- **SOUL.md 是人格，完整注入 prompt**，不要截取或摘要。
- **评审要有具体引用**（文件名、行号、代码片段），不能空泛。
- **批评必须给替代方案**，不能只说"这不行"。
