# BOSS Job Assistant V4

面向 BOSS 直聘的多角色求职 Skill 包。它定义消息优先、岗位筛选、真实经历约束、风险暂停、投递确认、面试准备、职业策略和简历定向优化。

## 重要说明

- 本公开副本不包含任何真实求职者姓名、联系方式、简历原件、招聘方记录或投递历史。
- 使用前请在本地私有副本填写 `user-profile.md` 和 `job-filter-rules.yaml`；不要把个人资料提交到公开仓库。
- 履历事实只能来自用户自己提供并核验的简历；岗位偏好和平台规则不等于履历事实。
- 岗位薪资下限由本地 `user-profile.md` 与 `job-filter-rules.yaml` 配置；下限低于最低期望的岗位直接跳过，面议或无法确认下限的岗位人工复核。
- 本包定义可配置的工作日执行守卫和触发时间，但不会自行创建系统级定时任务。

## 安装

将整个 `boss-job-assistant-v4` 目录复制到全局 Skill 目录：

```bash
cp -R boss-job-assistant-v4 ~/.agents/skills/
```

安装后可用类似请求触发：

```text
使用 boss-job-assistant-v4，在已授权的 BOSS 直聘 Chrome 中执行当前一轮。
```

## 直接使用

1. 运行 `ruby scripts/validate.rb`。
2. 确认 Chrome 已登录 BOSS 直聘，并已授权浏览器控制。
3. 让执行代理读取 `SKILL.md`。
4. 每轮输入遵循 `schemas/run-input.schema.json`。
5. 机器输出遵循 `schemas/run-output.schema.json`，人类汇报使用 `report-template.md`。

## 目录

- `agents/`：七个角色的边界、输入、输出和停止条件
- `prompts/`：可直接装载的任务 Prompt
- `schemas/`：核心输入输出 JSON Schema
- `memory/`：空白初始状态，不含个人历史
- `manifest.yaml`：组件索引
- `workflow.yaml`：消息优先的执行流程
- `job-filter-rules.yaml`：岗位筛选与硬排除规则

## 修改原则

- 新增经历前必须由用户提供证据并确认。
- 修改触发时间后必须重新校验完整时间列表，尤其是 `13:40` 与 `19:00`。
- 不要将浏览器活动日志或历史“已沟通”状态写入 `memory/applied-history.json` 的新成功记录。

## 公开发布安全

提交前检查姓名、电话、邮箱、简历文件、公司名称、招聘对话、岗位链接、本机路径、令牌和运行时间戳；发现任何真实记录都应先清空。
