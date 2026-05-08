# datamap-sql Skill

数据地图 SQL 自动查数助手，配合 Claude Code 使用。

## 功能

- 通过浏览器 MCP 自动操作数据地图平台写 SQL
- 表结构缓存在飞书多维表格，团队共享
- 自动识别 df（存量表）/ di（增量表）后缀
- 支持 CSV 导出和本地数据分析

## 飞书共享库

地址: https://mi.feishu.cn/base/CWXTbLpxOaBe1PsZE8Cc8Suvn6g

包含 3 个表：
- **表索引** — 表名、数据源、分区信息、列数、业务说明
- **字段明细** — 每张表的字段名、类型、说明
- **表关联关系** — 表与表之间的 JOIN 关系

## 安装（一行命令）

```bash
npx datamap-sql-skill
```

自动备份旧版本到 `~/.claude/commands/datamap-sql.md.bak.*`，然后安装最新版。

## 使用

在 Claude Code 中输入：
```
/datamap-sql 查昨天ods_gd_case_detail_df的案件数
```

## 前置条件

1. 已安装 Claude Code
2. 已配置 Playwright MCP（浏览器自动化）
3. 已配置飞书 MCP（读写共享表结构）
4. 已登录数据地图平台
