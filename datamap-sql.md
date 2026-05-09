---
description: 在数据地图平台自动写SQL查数、导出数据、分析结果
argument-hint: [SQL查询需求描述]
allowed-tools: mcp__playwright__browser_navigate, mcp__playwright__browser_evaluate, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_click, mcp__playwright__browser_network_requests, mcp__feishu-mcp-pro__bitable_ops, Bash, Read, Write, Agent
---

# 数据地图 SQL 自动查数助手

通过浏览器 MCP 自动操作数据地图平台写 SQL 查数。

## 平台信息

- **URL**: `http://datamap.pdt.mixiaojin.srv/#/sql/query?noteId=820`
- **技术栈**: Vue 2 + Vuex + Ant Design + CodeMirror
- **当前用户名**: likai（已登录）
- **笔记本**: 政策平台 (noteId=820)
- **数据源**: hive, spark_tbds, jixin_doris, Doris

## 用户需求

$ARGUMENTS

## 表结构缓存（飞书共享库）

飞书多维表格: https://mi.feishu.cn/base/CWXTbLpxOaBe1PsZE8Cc8Suvn6g
- 表索引 (`tblHPp8HOas6hByo`): 表名、数据源、分区、列数、业务说明
- 字段明细 (`tbl3zQHRrwaeZuKQ`): 字段名、类型、说明
- 表关联 (`tblCSWFIelHwbCIG`): JOIN 关系

**查询前先查飞书缓存：**
1. `search_records` 搜索表索引 → 命中则查字段明细 → 直接用
2. 未命中 → DESC 获取结构 → 写回飞书（表索引 + 字段明细）

## 表命名规则

| 后缀 | 类型 | SQL 要点 |
|------|------|----------|
| `df` | 存量表（全量快照） | `WHERE dt = '${date-1}'` |
| `di` | 增量表（仅增量） | `WHERE dt >= '开始' AND dt <= '${date-1}'` |
| 无后缀 | 需判断 | 先少量数据确认 |

- hive 表必须加 `WHERE dt = '${date-1}'`
- Doris 表（policy_db 开头）无 dt 分区限制

## 浏览器初始化

Chrome 147+ CDP 需非默认数据目录。用 Junction 共享真实 profile（登录状态、Cookie 全部共享）。

```bash
CHROME_PROFILE_JUNCTION="$HOME/.agent-browser/chrome-profile"
CHROME_REAL_PROFILE="$LOCALAPPDATA/Google/Chrome/User Data"

CDP_OK=$(curl -s http://127.0.0.1:9222/json/version 2>&1 | grep -c "Browser")
if [ "$CDP_OK" = "1" ]; then
  echo "CDP 已就绪"
else
  if [ ! -e "$CHROME_PROFILE_JUNCTION" ]; then
    mkdir -p "$HOME/.agent-browser"
    powershell -NoProfile -Command "New-Item -ItemType Junction -Path '$CHROME_PROFILE_JUNCTION' -Target '$CHROME_REAL_PROFILE'" 2>/dev/null
  fi
  taskkill //F //IM chrome.exe 2>/dev/null
  sleep 2
  "/c/Program Files/Google/Chrome/Application/chrome.exe" --remote-debugging-port=9222 --remote-allow-origins=* --user-data-dir="$CHROME_PROFILE_JUNCTION" &
  sleep 4
fi
```

## 操作流程

### 第一步：打开数据地图

```bash
curl -s -X PUT "http://127.0.0.1:9222/json/new?http://datamap.pdt.mixiaojin.srv/%23/sql/query?noteId=820"
```

### 第二步：写入 SQL

```javascript
const cm = document.querySelectorAll('.CodeMirror')[0].CodeMirror;
cm.setValue('YOUR_SQL_HERE');
```

**SQL 格式化规则：**
- 关键字大写：SELECT、FROM、WHERE、AND、JOIN、ON、GROUP BY、ORDER BY、LIMIT
- 每个主要子句换行左对齐
- 字段超 3 个时每个独占一行，缩进 2 空格
- WHERE 条件逐行缩进，AND/OR 放行首
- 日期变量：`${date-1}` = 昨天，`${date}` = 今天

### 第三步：执行 SQL

```javascript
const cm0 = document.querySelectorAll('.CodeMirror')[0];
let container = cm0;
for (let i = 0; i < 10; i++) {
  container = container.parentElement;
  if (!container) break;
  const runBtn = Array.from(container.querySelectorAll('button'))
    .find(b => b.textContent.trim() === '运 行');
  if (runBtn) { runBtn.click(); break; }
}
```

### 第四步：等待结果

小查询 5 秒，中等 15 秒，大查询 30 秒。检查：`document.querySelector('.ant-spin-spinning')`

### 第五步：读取结果

```javascript
const tables = document.querySelectorAll('.ant-table');
const firstTable = tables[0];
let el = firstTable;
let dataSource = null;
for (let i = 0; i < 15; i++) {
  el = el.parentElement;
  if (!el) break;
  const vueKey = Object.keys(el).find(k => k.startsWith('__vue__'));
  if (vueKey) {
    const vue = el[vueKey];
    if (vue.$data) {
      for (const key of Object.keys(vue.$data)) {
        const val = vue.$data[key];
        if (Array.isArray(val) && val.length > 0 && val[0] && typeof val[0] === 'object') {
          dataSource = val;
          break;
        }
      }
    }
    if (dataSource) break;
  }
}
```

结果以表格形式展示，查询结束。

## 常用表

| 表名 | 数据源 | 说明 |
|------|--------|------|
| `policy_db.cp_credit_variable_raw` | doris | 策略执行表 |
| `cfc.ods_gd_case_base_df` | hive(dt) | 案件基础表 |
| `dws_sxj_amount_adjust_instruction` | hive(dt) | 调额指令表 |
| `ods_mifi_risk_base_di` | hive(dt) | 风控基础数据 |
| `dwd_loan_xj_contract_fact_df` | hive(dt) | 现金贷合同事实表 |
| `dwd_loan_user_contract_fact_df` | hive(dt) | 用户合同事实表 |
| `ods_loan_order_info_df` | hive(dt) | 订单信息表 |

## 错误处理

- 登录页 → 提示用户手动登录
- 查询超时 → 检查 SQL
- 数据源不可用 → 切换左上角下拉框
- COUNT > 10000 → 建议异步执行
