---
title: 从“人写代码”到“人与智能体共工程”：一份面向工程实践的《Agentic Software Engineering》深度解读
date: 2025-10-09T20:08:56+08:00
tags:
  - ai-agent
---

# 从“人写代码”到“人与智能体共工程”：一份面向工程实践的《Agentic Software Engineering》深度解读
> 原文：[Ahmed E. Hassan et al. *Agentic Software Engineering: Foundational Pillars and a Research Roadmap*, 2025](https://arxiv.org/abs/2509.06216)

---

## 1. 为什么你现在就该关心 Agentic SE？

过去 18 个月，GitHub Copilot、Claude Code、Google Jules、Cognition Devin 等“AI 队友”已经在开源仓库里提交了数十万合并 PR。
Jeff Dean 预测：一年内 AI 就将达到“初中级开发者”水平。
然而，真正让 CTO 们夜不能寐的，并不是“AI 会不会写代码”，而是——

> **当 AI 的产出速度比人类 Review 速度快 100 倍时，我们怎样保证代码仍然可信？**

这正是本文提出的 **Agentic Software Engineering（SE 3.0）** 所要解决的核心矛盾：**速度 vs. 信任**。

---

## 2. 一张图看懂 SE 3.0 的“双模态”世界观

传统软件工程（SE 1.0/2.0）只有一条主线：人→工具→代码。
SE 3.0 把这条线拆成两条互补的轨道，作者称之为 **SE for Humans（SE4H）** 与 **SE for Agents（SE4A）**。

| 维度 | SE4H（面向人） | SE4A（面向智能体） |
|---|---|---|
| **Actor** | Agent Coach（人） | 多智能体舰队 |
| **Process** | 策略制定、委托、验收 | 原子化、可重复、可回滚 |
| **Artifact** | BriefingScript / MentorScript / VCR | LoopScript / CRP / MRP |
| **Tool** | ACE（Agent Command Environment） | AEE（Agent Execution Environment） |

两条轨道之间用**版本化、机器可读、结构化的 living artifacts** 保持同步，而不是 Slack 里的一句 “hey, plz fix bug”。

---

## 3. 从 Level 0 到 Level 5：SE 的“自动驾驶等级”

类比 SAE 自动驾驶分级，作者给出了 6 级 SE 自动化阶梯，让我们一眼看清自己所处的位置：

| Level | 名称 | 人类职责 | 典型系统 | 汽车对照 |
|---|---|---|---|---|
| 0 | Manual Coding | 手敲每行代码 | Vim/Notepad | 无自动化 |
| 1 | Token Assistance | 逐 token 审核 | IDE 补全 | L1 巡航 |
| 2 | Task-Agentic | 审核整块代码 | Copilot | L2 车道保持 |
| 3 | Goal-Agentic（本文焦点） | 定目标+最终 Review | Devin/Claude Code | L3 有条件自动驾驶 |
| 4 | Specialized Domain Autonomy | 设定领域 KPI | GPT-5-Frontend 专精 | L4 区域无人车 |
| 5 | General Domain Autonomy | 设定公司级目标 | 尚不存在 | L5 全域无人车 |

> **行业共识：Level 3 是当前最紧迫的战场。**
> Level 4/5 需要大量 Level 3 的实践数据与治理框架才能演进。

---

## 4. 真实案例：7 张工单，28 个 PR，1.5 小时人类投入

作者用一位“超级开发者”的实际工作流展示了 SE 3.0 的日常：

1. **人类**在 ACE 中写 7 份 BriefingScript（每张 10~15 分钟）。
2. **智能体群**在 AEE 里并行生成 4×7=28 个 PR（N-version programming 回归）。
3. **人类**在 ACE 的可视化面板里按风险/成本/创新度排序，接受或回退。
4. 对 3 张工单需要细化，**智能体**主动发出 Consultation Request Pack（CRP）。
5. 人类用 Version Controlled Resolution（VCR）回复，形成新的 LoopScript。
6. 最终 Merge-Readiness Pack（MRP）被合并，所有 artifact 自动版本化，成为团队“集体记忆”。

该流程把“编码”时间压缩到近乎 0，把人类精力集中到 **意图、策略、风险评估**。

---

## 5. 为什么传统 IDE 已死？ACE vs. AEE 设计要点

| 特性 | ACE（人的驾驶舱） | AEE（智能体的工作台） |
|---|---|---|
| 核心设计目标 | 意图可视化、成本洞察、审计追踪 | 高并发、确定性、可观测 |
| 关键视图 | 事件收件箱、成本仪表盘、VCR 时间线 | 任务 DAG、资源池、沙盒日志 |
| 交互粒度 | 语义级（一个业务目标） | 语法级（一次测试运行） |
| 集成示例 | Jira + 成本会计 + LLM 审计 | K8s + 无服务器 + 弹性沙盒 |

一句话：**ACE 像 IDE + Jira + CFO Dashboard，AEE 像 CI 集群 + 1000 个永不疲倦的实习生。**

---

## 6. 研究路线图：四大挑战 + 教育冲击

作者没有只给愿景，而是列出了可落地的研究议程：

1. **可信合成（Trustworthy Synthesis）**
- 如何让 MRP 自带“证据链”：测试、形式化验证、变更影响分析一键打包？
- 需要新的 DSL 描述“可验证的意图”。

2. **可扩展 Review（Scalable Review）**
- 当 PR 量 > 人眼极限时，如何用“元 Review 智能体”做分层过滤？
- 需要新的 Review 博弈论模型与经济学激励。

3. **上下文迁移（Onboarding & Context Transfer）**
- 新人加入团队需要 2 周读文档，智能体能否 5 分钟完成？
- 需要可执行的“团队知识图谱” + 动态 LoopScript 生成。

4. **成本-质量 Pareto 前沿（Cost-Quality Frontier）**
- 如何用 RL 在“token 预算”内找到最优 N-version 配置？
- 需要在线强化学习 + 实时云成本 API。

**教育冲击**：
- CS 课程将从“写代码”转向“写 BriefingScript + 调试智能体”。
- 作业评分标准从“程序能通过测试”变为“程序能让 3 个智能体在 5 分钟内通过测试，且 token 花费最低”。

---

## 7. 工程师的 3 个立即行动项

1. **把需求写成结构化的 BriefingScript**：用 Markdown 模板固定“背景-目标-验收-边界-反例”。
2. **在 CI 里加一道 “Agent Budget Gate”**：当 PR 的 token 花费 > 阈值，自动打回重写。
3. **把 Review Checklist 机器可读化**：变成可执行的 Rego/Starlark 脚本，让 Review 智能体先跑一遍。

---

## 8. 结语：从 10x Developer 到 100x Agent Coach

> “未来最值钱的技能不是写代码，而是**写出能让 1000 个智能体协同工作的元指令**。”

Agentic SE 不是科幻，而是正在进行时。本文的价值在于：
- 把草根实践上升为**可传授、可度量、可治理**的工程学；
- 给出一张“从 Level 2 到 Level 3”的作战地图；
- 提前指出“速度 vs. 信任”瓶颈的系统性解法。

