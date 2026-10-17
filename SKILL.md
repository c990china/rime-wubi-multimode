---
name: rime-wubi-multimode
description: 维护 Rime 小狼毫「极点五笔86」的完整方案（指南 + 配置源 + 词库 + 屏蔽 + 算码器）。当用户要求给输入法加词、新增快捷短语、删除或屏蔽候选词、修改或校验词库、或复现/重装整套输入法方案，或提到「词库」「加词」「新词」「删词」「屏蔽候选」「快捷短语」「五笔编码」「tdyw」「复现输入法」时使用。自动算出五笔86 编码并写入词库，用户重新部署后即可用键盘打出。
agent_created: true
---

# Rime 五笔词库维护

> 版本：v1.1　最后更新：2026-10-08
> 配套脚本：`scripts/wubi_code.py`（算码 / 校验 / 列出）
>
> **本包是全套方案**：根目录放指南（`2026xxxx=…指南.md`，最新一份为权威）；
> `config\` 放配置源（schema / default.custom / weasel.custom / 说明.txt）；
> `dict\` 词库源，`lua\` 屏蔽黑名单，`scripts\` 算码器。新电脑复现见根目录最新指南。

## 何时用

用户要给输入法**加词**、新增**快捷短语**，或校验、查看现有词库。
典型说法：「词库加个词：XXX」「加个快捷短语 XXX」「这个词打不出来，帮我加进词库」。

## 词库源在哪

**词库源就在本包内**：`dict/wubi86_jidian_user.dict.yaml`。

它经软链接映射进 Rime 用户目录，**改它就是改生效文件**：

```
本包 dict/wubi86_jidian_user.dict.yaml
        ↓ mklink 软链接
%APPDATA%\Rime\wubi86_jidian_user.dict.yaml
        ↓
Rime 读取
```

**AI 的职责边界**：**只改 yaml，到此为止**。
git 提交由用户自行处理——**不要向用户提 git、不要给 git 命令、不要提醒提交**。

```
AI 改 yaml  →  （用户自行 git 提交）  →  用户重新部署  →  新词生效
```

> 软链接尚未建立时（新电脑），先跑 `dict/新电脑-mklink软链接命令.txt` 里的命令。
> （对比：方案文件 `*.schema.yaml` **不是**软链接，改动需双写源与部署目录。）

## 加词流程

1. **算码**：

   ```bash
   python "<本技能目录>/scripts/wubi_code.py" 新词1 新词2
   ```

   输出即 `词条<Tab>编码<Tab>1000000`，可直接使用。
   词库不在默认位置时加 `--dict <路径>`。

2. **展示给用户确认** —— 专名尤其如此，见「编码规则」第 3 条。
3. **追加到合适分组**（保持 Tab 分隔）：
   `## 常用长句与快捷指令` / `## 企业与常用专有名词` / `## 技术与日常词汇`，
   或按需新建 `## 组名`。
4. **提醒用户重新部署** —— 右键任务栏小狼毫托盘图标 →「重新部署」。**到此结束，不提 git。**

## 删词流程

**先判断这个词在哪**——这决定用什么方法：

| 词来自哪 | 怎么处理 | 说明 |
|---|---|---|
| 本包 `dict/wubi86_jidian_user.dict.yaml`（自己加的） | **直接删掉那一行** | 重新部署即消失 |
| 上游码表 `wubi86_jidian.dict.yaml`（原生词） | **删不掉，改用黑名单屏蔽** | 上游文件重新下载会覆盖，删了白删 |

**定位词属于哪个文件**：在主码表、扩展表、用户词库里按编码逐个搜，看命中在哪。

```bash
grep -n "tkri" "%APPDATA%\Rime\wubi86_jidian.dict.yaml"
```

**删自己的词**：在 `dict/wubi86_jidian_user.dict.yaml` 里找到那一行，**整行删除**，重新部署。

**屏蔽原生词**：把词加进 `lua/cand_blocker.lua` 的 `blocked_list`，重新部署（见「屏蔽候选词」节）。

**改词**（改编码或权重）：在词库里直接改那一行，等同「删旧 + 加新」。

## 编码规则

出处：主码表 `wubi86_jidian.dict.yaml` 的 `encoder.rules`。

1. **二字词**：第一字前 2 码 + 第二字前 2 码
   （核岛 = 核 `sy` + 岛 `qy` → `syqy`）
2. **三字词**：第一字首码 + 第二字首码 + 第三字前 2 码
   （示例甲 = 示 `a` + 例 `w` + 甲 `lh` → 演示用码 `ailg`）
3. **四至十字词**：第一、二、三字首码 + 末字首码
   （演示科技 = 演 `d` 示 `r` 科 `t` 技 `l` → 演示用码 `drtl`）

**例外 —— 不用五笔规则硬算，等用户给码**：

- 含标点 / 数字 / 英文的长句
- 超过 10 字
- 长公司名 / 专名 —— 用户惯例是取关键词的拼音首字母

**专名默认先问再写**：即使字数落在规则内（「演示科技」规则算 `drtl`），
用户实际用的可能是拼音首字母。算出的码先展示，用户点头再写。

## 保留既有差异

用户手写的码优先于规则结果，不要「纠正」。

## 校验命令

```bash
python "<本技能目录>/scripts/wubi_code.py" --check    # 列出全部不合规词条
python "<本技能目录>/scripts/wubi_code.py" --list     # 列出全部词条
```

## 格式要求

- **必须用 Tab 分隔**（`词条<Tab>编码<Tab>权重`），不能用空格
- 权重填 `1000000` → 锁定第 1 候选位
- `#` 开头是注释（只能另起一行）；`##` 开头是分组名
- `z` 开头的词条不进用户词典（方案含 `disable_user_dict_for_patterns: ^z.*$`）

## 屏蔽候选词（lua_filter）

**用途**：隐藏不想看到的候选词，**不修改任何词库文件**。

**唯一需要维护的文件**：`lua/cand_blocker.lua`（黑名单内嵌在脚本顶部）。

```lua
local blocked_list = {
  "程朱",
  -- 想屏蔽谁就加一行
}
```

改完 → 重新部署 → 生效。**不用动词库，不用改 schema。**

**一次性挂载**（已完成，勿重复）：`wubi86_jidian.schema.yaml` 的 `engine.filters` 首行
已有 `- lua_filter@*cand_blocker`（**必须带 `*`**）。

> ⚠️ **两个必须写对的地方**（2026-10-07 实测踩坑，已双代理核实；错一处输入法完全打不出字）：
>
> 1. **挂载要带 `*`**：`lua_filter@*cand_blocker`。
>    不带 `*` 时 librime-lua 走 `lua_getglobal` 去找同名**全局变量**，
>    而本机没有 `rime.lua`，全局不存在 → 取不到模块。带 `*` 才走 `require`。
> 2. **入口函数名必须是 `M.func`**（不能写 `M.filter`）。
>    librime-lua 源码 `src/lua_gears.cc` 的 `raw_init()` 只查 `"func"` 字段。
>
> **症状**：日志报 `func type: nil ... func type error expect function`，
> 该过滤器取到 nil、输出为空 → 候选流为空 → **一个字都打不出来**
> （旧版 librime-lua；新版只静默禁用该过滤器）。
>
> **排查**：`%TEMP%\rime.weasel\` 目录下的 `*.log.ERROR.*.log`
> （注意 `rime.weasel` 是**目录**，不是文件名前缀）。

## 包内文件

| 文件 | 作用 |
|---|---|
| `scripts/wubi_code.py` | 算码 / 校验 / 列出 |
| `dict/wubi86_jidian_user.dict.yaml` | **词库源**（软链接进 Rime 用户目录，改这里即生效） |
| `dict/新电脑-mklink软链接命令.txt` | 新电脑建软链接的命令备忘录 |
| `lua/cand_blocker.lua` | 候选词屏蔽黑名单（软链接进 Rime 的 `lua/` 目录） |
