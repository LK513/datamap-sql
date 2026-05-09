---
description: 在数据地图平台自动写SQL查数、导出数据、分析结果
argument-hint: [SQL查询需求描述]
allowed-tools: mcp__playwright__browser_navigate, mcp__playwright__browser_evaluate, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_click, mcp__playwright__browser_network_requests, mcp__feishu-mcp-pro__bitable_ops, Bash, Read, Write, Agent
---

# 数据地图 SQL 自动查数助手

你是一个能通过浏览器 MCP 自动操作数据地图平台写 SQL 查数的助手。

## 平台信息

- **URL**: `http://datamap.pdt.mixiaojin.srv/#/sql/query?noteId=820`
- **技术栈**: Vue 2 + Vuex + Ant Design + CodeMirror
- **当前用户名**: likai（已登录，无需处理登录）
- **笔记本名称**: 政策平台 (noteId=820)
- **可用数据源**: hive, spark_tbds, jixin_doris, Doris

## 用户需求

$ARGUMENTS

## 表结构缓存（飞书共享库）

**飞书多维表格地址**: https://mi.feishu.cn/base/CWXTbLpxOaBe1PsZE8Cc8Suvn6g
- **表索引** (table_id: `tblHPp8HOas6hByo`): 记录表名、数据源、分区信息、列数、业务说明
- **字段明细** (table_id: `tbl3zQHRrwaeZuKQ`): 记录每张表的字段名、类型、说明
- **表关联关系** (table_id: `tblCSWFIelHwbCIG`): 记录表与表之间的 JOIN 关系

**重要：在执行任何查询前，先从飞书共享库查询表结构：**

### 查表结构流程

1. **搜索表索引**：用 `mcp__feishu-mcp-pro__bitable_ops` 的 `search_records` 搜索表名
   ```
   action: search_records
   app_token: CWXTbLpxOaBe1PsZE8Cc8Suvn6g
   table_id: tblHPp8HOas6hByo
   filters: ["文本~表名关键词"]
   ```
2. **查字段明细**：如果表索引中找到，再用 `search_records` 查字段明细
   ```
   action: search_records
   app_token: CWXTbLpxOaBe1PsZE8Cc8Suvn6g
   table_id: tbl3zQHRrwaeZuKQ
   filters: ["多行文本=完整表名"]
   ```
3. **命中** → 直接使用缓存结构，无需 DESC
4. **未命中** → 先执行 DESC 获取结构，查询完成后**必须**将表结构写入飞书共享库

### 写入新表结构流程

DESC 获取到表结构后，分两步写入：

**步骤1：写入表索引**
```
action: create_record
app_token: CWXTbLpxOaBe1PsZE8Cc8Suvn6g
table_id: tblHPp8HOas6hByo
fields: {"文本": "表名", "数据源": "hive/doris队列", "是否有分区": "是/否", "分区字段": "dt", "列数": N, "业务说明": "表用途说明", "添加人": "当前用户名"}
```

**步骤2：写入字段明细（每条字段一行）**
```
action: batch_create
app_token: CWXTbLpxOaBe1PsZE8Cc8Suvn6g
table_id: tbl3zQHRrwaeZuKQ
records: [{"多行文本": "表名", "字段名": "字段名", "字段类型": "类型", "字段说明": "说明"}, ...]
```

## 表命名规则（df/di 后缀）

数据表后缀决定表的类型和查询方式：

| 后缀 | 类型 | 含义 | 查询特点 |
|------|------|------|----------|
| `df` | 存量表 | Daily Full，每天全量快照 | 每个 dt 分区是当天所有数据的完整快照 |
| `di` | 增量表 | Daily Increment，每天增量 | 每个 dt 分区仅包含当天新增/变更的记录 |
| 无后缀 | 需判断 | 不确定，需跑数验证 | 先查少量数据确认 |

**SQL 编写要点：**
- hive 表必须加 `WHERE dt = '${date-1}'` 分区条件（df 和 di 都需要）
- 查某天数据 → `WHERE dt = '${date-1}'`
- df 表查最新状态 → 取最新 dt 分区即可
- di 表查累计数据 → 需要 `WHERE dt >= '开始日期' AND dt <= '${date-1}'`
- policy_db 开头的 Doris 表无 dt 分区限制

**写入表索引时，根据表名后缀自动填写：**
- `xxx_df` → 业务说明补充"（存量表）"
- `xxx_di` → 业务说明补充"（增量表）"

## 浏览器初始化（必须先执行）

使用 agent-browser 操作数据地图前，必须确保 Chrome 以 CDP 模式运行。

### 检查并启动 Chrome CDP

Chrome 147+ 要求 CDP 远程调试必须使用非默认的用户数据目录。解决方案：用 Windows Junction 将默认 profile 链接到另一个路径，Chrome 看到的不是默认目录但数据完全共享（登录状态、Cookie、扩展等）。

```bash
# 1. 检查 CDP 是否可用
curl -s http://127.0.0.1:9222/json/version 2>&1

# 2. 如果连不上，检查 junction 是否已创建
ls -la "$HOME/.agent-browser/chrome-profile" 2>/dev/null

# 3. 如果 junction 不存在，先创建（只需执行一次）
mkdir -p "$HOME/.agent-browser"
powershell -NoProfile -Command "New-Item -ItemType Junction -Path 'C:\Users\$env:USERNAME\.agent-browser\chrome-profile' -Target 'C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data'"

# 4. 关闭所有 Chrome 后重新启动
taskkill //F //IM chrome.exe 2>/dev/null
sleep 2
"/c/Program Files/Google/Chrome/Application/chrome.exe" --remote-debugging-port=9222 --user-data-dir="C:\Users\likai\.agent-browser\chrome-profile" &

# 5. 等待启动完成
sleep 4
curl -s http://127.0.0.1:9222/json/version
```

**说明：**
- Junction 方案：Chrome 看到 `~/.agent-browser/chrome-profile`（非默认路径），实际指向 `%LOCALAPPDATA%/Google/Chrome/User Data`（同一份数据）
- 登录状态、Cookie、扩展、书签等全部共享，无需重新登录
- 首次使用需创建 Junction（步骤3），之后不需要重复
- Chrome 启动时会带 CDP 调试端口，skill 可直接连接操作
- 如果当前 Chrome 已在运行但没有 CDP 端口，需要先关闭所有 Chrome 再重启

## 操作流程

### 第一步：导航到数据地图

```bash
agent-browser open "http://datamap.pdt.mixiaojin.srv/#/sql/query?noteId=820"
```

等待页面加载完成（等待 5 秒），确认页面标题包含「数据地图」。

### 第二步：写入 SQL

使用 CodeMirror API 写入 SQL 到第一个编辑器：

```javascript
const cm = document.querySelectorAll('.CodeMirror')[0].CodeMirror;
cm.setValue('YOUR_SQL_HERE');
```

**注意事项：**
- 日期变量用 `${date-1}` 表示昨天，`${date}` 表示今天
- 如果需要写入到已有的编辑器单元格，先找到对应 index 的 CodeMirror
- SQL 写入后不要自动保存，避免干扰其他单元格

### 第三步：执行 SQL

在 `pannel-wrapper` 中找到「运 行」按钮并点击：

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

### 第四步：等待查询完成

- 小查询（<100行）：等待 5 秒
- 中等查询（100-1000行）：等待 15 秒
- 大查询（>1000行）：等待 30 秒

检查加载状态：
```javascript
const loading = document.querySelector('.ant-spin-spinning');
return { isLoading: !!loading };
```

### 第五步：读取结果

从 Vue 组件的 dataSource 中读取数据（支持全部行，不受分页限制）：

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

**注意：** 数据在 `$data` 的某个数组字段中，字段名不固定，通过遍历查找长度 > 0 且元素为对象的数组。

### 第六步（可选）：下载 CSV

如果用户要求下载数据，点击结果区域的下载按钮：

1. 找到当前单元格的 `pannel-wrapper`（通过 CodeMirror 向上查找 `id` 以 `pannel-wrapper-` 开头的元素）
2. 在该 wrapper 内找到 `.wheader__btns.operation-bar` 中的图标按钮
3. 下载按钮的 SVG href 包含 `#iconbiaoge-xiazai`（从右数第3个图标）
4. 点击后出现下拉菜单，选择「导出csv」

```javascript
// 找到下载图标并点击
const wrapper = document.getElementById('pannel-wrapper-XXXXX');
const icons = wrapper.querySelectorAll('.wheader__btns.operation-bar .anticon');
const visibleIcons = Array.from(icons).filter(el => el.getBoundingClientRect().width > 0);
// 从右数第3个 = index = length - 3
const downloadBtn = visibleIcons[visibleIcons.length - 3];
downloadBtn.click();

// 等待下拉菜单出现后，点击"导出csv"
const dropdown = document.querySelector('.ant-dropdown:not(.ant-dropdown-hidden)');
const items = dropdown?.querySelectorAll('.ant-dropdown-menu-item');
for (const item of items) {
  if (item.textContent.trim() === '导出csv') { item.click(); break; }
}
```

下载的文件会自动保存到 `.playwright-mcp/` 目录。

### 第七步（可选）：本地数据分析

如果用户需要分析数据：
1. 用 `Bash` 执行 Python 脚本读取 CSV
2. 使用 pandas 做透视表、统计分析
3. 保存为 Excel 文件（含多个 sheet）

```bash
pip install pandas openpyxl -q 2>/dev/null
python << 'PYEOF'
import pandas as pd
df = pd.read_csv("下载的文件路径.csv", sep=",", dtype=str)
# ... 分析逻辑 ...
with pd.ExcelWriter("输出路径.xlsx", engine='openpyxl') as writer:
    df.to_excel(writer, sheet_name='原始数据', index=False)
    # ... 其他透视表 sheet ...
PYEOF
```

## 常用表参考

以下是一些常用的数据表（根据用户需求选择）：

| 表名 | 数据源 | 分区 | 说明 |
|------|--------|------|------|
| `policy_db.cp_credit_variable_raw` | doris队列 | 无 | 策略执行表（key-value结构） |
| `cfc.ods_gd_case_base_df` | 消金数仓(hive) | dt | 案件基础表 |
| `dws_sxj_amount_adjust_instruction` | 消金数仓(hive) | dt | 调额指令表 |
| `ods_mifi_risk_base_di` | 消金数仓(hive) | dt | 风控基础数据日表 |
| `dwd_loan_xj_contract_fact_df` | 消金数仓(hive) | dt | 现金贷合同事实表 |
| `dwd_loan_user_contract_fact_df` | 消金数仓(hive) | dt | 用户合同事实表 |
| `ods_loan_order_info_df` | 消金数仓(hive) | dt | 订单信息表 |

**注意：** hive表必须加 `WHERE dt = '${date-1}'` 分区条件，否则报错「分区表没有分区条件约束」。Doris表（如policy_db开头的）无此限制。

## 表结构记录规范

每次查询新表后，必须将表结构写入飞书共享库（见上方「写入新表结构流程」），包括：
1. 表索引：表名、数据源、是否有分区、列数、业务说明、添加人
2. 字段明细：每条字段一行（表名、字段名、类型、说明）
3. 业务含义（如枚举值：MXJ_result 1=通过，2=拒绝）记录在字段说明中

## 数据上传（大名单批量查询）

当查询 ID 列表超过 2000 个时，无法直接写入 SQL 的 IN 子句，需要先上传到临时表再关联查询。

### 临时表：ods_linshi_ai

- **表结构**：5个 STRING 字段（field_1 ~ field_5）+ dt 分区字段（INT）
- **位置**：消金数仓（hive）
- **用途**：存放临时查询名单，用于关联查询

### 上传流程

**步骤1：准备 .xls 文件**
- 格式：仅支持 `.xls`（Excel 97-2003），不支持 `.xlsx`
- 列名：必须是 `field_1`, `field_2`, `field_3`, `field_4`, `field_5`（共5列）
- **不要包含 dt 列**（分区在上传时填写）
- 长数字（如用户ID）必须作为**字符串**格式，避免科学计数法

```python
import pandas as pd
import xlwt

# 读取原始数据
df = pd.read_excel('原始文件.xlsx', dtype=str)  # dtype=str 保持字符串

# 构造上传文件
new_df = pd.DataFrame()
new_df['field_1'] = df['user_id']      # 根据实际列名映射
new_df['field_2'] = df['contract_id']
new_df['field_3'] = df['product_id']
new_df['field_4'] = df['out_id']
new_df['field_5'] = ''                 # 空字段补齐到5列

# 保存为 .xls
output_path = 'upload_file.xls'
workbook = xlwt.Workbook(encoding='utf-8')
sheet = workbook.add_sheet('Sheet1')
headers = ['field_1', 'field_2', 'field_3', 'field_4', 'field_5']
for col, header in enumerate(headers):
    sheet.write(0, col, header)
for row_idx, row in new_df.iterrows():
    for col_idx, value in enumerate(row):
        sheet.write(row_idx + 1, col_idx, str(value) if pd.notna(value) else '')
workbook.save(output_path)
```

**步骤2：上传到数据地图**
1. 导航到元数据管理 → 数据表管理
2. 搜索 `ods_linshi_ai`，点击进入
3. 点击「数据存储」tab
4. 点击「导入分区数据」按钮
5. 上传 .xls 文件
6. 填写分区值：**昨天日期**（如今天 `20260508` → 填 `20260507`）
7. 点击「确定」
8. 如果提示分区已有数据，选择「覆盖」
9. 看到"导入成功"提示即完成

**步骤3：关联查询**
```sql
SELECT a.*, b.*
FROM ods_linshi_ai a
JOIN other_table b ON a.field_1 = b.user_id
WHERE a.dt = 20260507  -- 分区值
```

**注意事项**：
- field_1 ~ field_5 都是 STRING 类型
- dt 是 INT 类型，格式 YYYYMMDD
- 上传后需要等待几秒数据才会生效
- 用完后建议清理历史分区数据

## 错误处理

- 如果页面跳转到登录页，提示用户需要先手动登录
- 如果查询超时，提示用户检查 SQL 是否正确
- 如果数据源不可用，提示用户切换数据源（页面左上角下拉框）

## 输出格式

查询完成后，以清晰的表格形式展示结果，并根据数据内容提供简要分析。如果用户要求下载，确认文件已保存并告知路径。
