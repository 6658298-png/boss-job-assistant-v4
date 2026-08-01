---
name: boss-job-assistant-v4
description: Use when operating an authorized BOSS直聘 session for message-first recruiter communication, evidence-bound role screening, safe outreach, resume tailoring, interview preparation, or career planning.
---

# BOSS Job Assistant V4

## 核心原则

在用户已登录且明确授权的 BOSS 直聘 Chrome 会话中工作。所有经历陈述以 `user-profile.md` 为唯一事实源；岗位目标、市场建议和招聘方描述不能反向写成用户经历。

## 使用前读取

按顺序读取：

1. `user-profile.md`
2. `job-filter-rules.yaml`
3. `workflow.yaml`
4. `agents/Orchestrator.md`
5. 本轮涉及的角色文件、Prompt 和 JSON Schema

浏览器操作需要使用 `computer-use:computer-use`，每次页面动作后重新读取当前界面。不得依据旧页面状态继续操作。

## 不可破坏的规则

- 每轮开始先检查消息；处理岗位期间在每个岗位动作后或安全等待点复查新消息；结束前再检查并处理一次消息。自动化触发间隔之外不承诺后台常驻监听。
- 回复必须简洁、真实、礼貌，并结合岗位与已有对话。
- 只能陈述 `user-profile.md` 中明确记录的事实；不推断证书、规模、客户、业绩或云平台项目。
- 招聘方索要简历时优先使用 BOSS 在线简历；出现安全的“发送简历”入口时选择“完整版简历”。
- 任何发送前必须通过 `RiskGuard`；验证码、身份认证、合同、付费、敏感信息或不明页面一律暂停。
- 同一岗位、招聘方或公司必须查重。
- 薪资是硬筛选项：读取岗位展示的薪资范围下限，与 `user-profile.md` 的最低期望比较；下限低于最低期望直接排除，不进入投递候选。薪资为面议、未知或无法确认下限时只能人工复核，不得投递。
- 只有本轮当前岗位页在操作后明确显示“已向BOSS发送消息”或同等成功状态，才能记为新成功。
- `已读`、`送达`、`继续沟通`、附件请求、历史已沟通状态、任务日志或点击按钮都不算新成功。
- 每次已确认发送后等待 3-10 秒。
- 不绕过平台限制，不伪造材料，不代替用户完成验证或签约。

## 岗位搜索覆盖

- 当前关键词加载结果没有符合条件的岗位时，切换到 `job-filter-rules.yaml` 中配置的下一个关键词继续搜索，不因单一关键词结果为空而结束本轮。公开副本不预置任何求职者职业方向。
- 每个关键词都要在职位列表区域滚动鼠标查看更多岗位；每次滚动后重新读取页面，再核对公司、岗位、薪资、地点、JD、雇佣主体、查重和风险，不得依据滚动前的旧状态操作。
- 只有通过硬排除、查重、事实和 RiskGuard 检查的岗位才可发送；切换关键词和滚动后仍无合适岗位时如实报告 0，不为凑数量投递低匹配岗位。

## 多角色路由

| 场景 | 角色 |
|---|---|
| 编排一轮任务 | `agents/Orchestrator.md` |
| 搜索、筛选、查重岗位 | `agents/JobHunter.md` |
| 生成招聘沟通 | `agents/RecruiterReply.md` |
| 检查风险和副作用 | `agents/RiskGuard.md` |
| 面试准备和复盘 | `agents/InterviewCoach.md` |
| 职业定位和 Offer 分析 | `agents/CareerStrategist.md` |
| 按岗位重排简历 | `agents/ResumeEngineer.md` |

## 每轮完成条件

输出必须符合 `schemas/run-output.schema.json`，并用 `report-template.md` 生成人类可读汇报。出现暂停条件时，保留安全断点到 `memory/run-state.json`，不要继续岗位操作。

## 常见错误

- 把简历“技能列表”写成已完成的大型项目：改为原样陈述技能，不补项目规模。
- 把目标职位写成当前职位：标记为求职目标。
- 把历史页面文案计为本轮投递：只记录本轮动作后的当前页确认。
- 未读筛选为空就断言没有消息：刷新并检查未筛选会话列表。
- 页面加载异常仍连续点击：停止并记录“状态未确认”。

## 校验

在包目录运行：

```bash
ruby scripts/validate.rb
```
