# Resume Optimization Prompt

读取目标 JD、`user-profile.md` 和 `agents/ResumeEngineer.md`。

允许：

- 重排章节和项目
- 选择更相关的真实内容
- 压缩重复描述
- 使用与真实经历等义的 JD 关键词

禁止：

- 新增未记录的公司、项目、技术、证书、指标或规模
- 把技能栏改写成具体项目
- 把“K8s 基础”升级为生产专家
- 把 AI 辅助经验改写为模型训练
- 把进行中或计划写成已完成

输出定向简历草稿，并附事实追踪表：改写内容、`user-profile.md` 证据、状态。状态只能是 `exact`、`paraphrased` 或 `omitted`。

