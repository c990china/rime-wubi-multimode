# Rime 小狼毫 · 极点五笔86（z 引导拼音 · 反引号引导英文）

本仓库提供一套 **Rime 小狼毫（Weasel）** 输入法方案：在「极点五笔86」码表基础上，增加两种引导式输入——

- **`z` 引导拼音**：不会拆的字用拼音打（可打任意长度），与五笔互不干扰；
- **反引号 `` ` `` 引导英文**：打 `` ` `` 不上屏，随后字母原样回显，空格整串上屏后自动回到五笔。

并保留五笔**四码顶字上屏**、候选词屏蔽、五笔编码提示、简繁切换等增强。

> 配置文件的字面内容以仓库内实际文件为准；本文档只记录「文件里看不出来的东西」：为什么这样配、如何安装与维护、踩过哪些坑。

## 一、功能特性

| 功能 | 说明 |
|---|---|
| 极点五笔86 | 基于 KyleBing 极点五笔86 码表 |
| 四码顶字上屏 | 五笔打满 4 码不按空格，第 5 码自动顶上前 4 码 |
| z 引导拼音 | `` z `` 开头切到拼音（script_translator），可打任意长度（如 `zdouyin`、`zzhongguo`） |
| 反引号引导英文 | `` ` `` 开头切到英文，原样回显，空格上屏后自动回五笔（如 `` `hello ``） |
| 候选词屏蔽 | `lua_filter` 隐藏不想看到的词，不改词库 |
| 五笔编码提示 | 拼音候选右侧标注五笔编码，边打边学 |
| 简繁切换 | 通过 opencc 简繁开关 |

## 二、设计要点（为什么这样配）

五笔盲打用户要同时满足「四码顶字」和「拼音救场」，二者天然冲突：四码上屏靠数到第 4 个字母触发，而无前缀拼音也从第 1 个字母数起，五笔与拼音共用同一套字母，引擎在第 4 字母处无法区分。

解法是**引导键**：用 `` z `` 把拼音切成独立分段（`affix_segmentor` + `recognizer` 成对），让拼音走 `script_translator`，从而天然免疫四码顶字。同理，反引号 `` ` `` 在五笔码表里是空集（同 `z`，零冲突），用它把英文切成独立分段，与五笔/拼音互不干扰。

> 实测（gnfy/rime-wubipinyin 的 `tools/collision_check.py`）：无前缀混输 + 四码上屏，每 7 个高频拼音词约有 1 个被顶掉（约 13–15%）。这是数学上不可兼得，引导键是必要代价。

### 判定机制（核心）

`recognizer` 处理器命中 pattern 后执行 `PushInput` 并返回 `kAccepted`，引擎立即中断处理器链，使 `speller` 的 `AutoSelectAtMaxCodeLength` 全程不运行——这是 z 拼音与反引号英文都「免疫四码顶字、可打任意长度」的真正原因。

**实践铁律**：`recognizer.patterns.<name>` 必须与对应的 `affix_segmentor@<name>` **成对存在**；一旦拆散，该段退回 speller 管辖，会在第 4 码被 auto_select 截断。

### 三种错误配法（排障对照）

| 配法 | 症状 | 错在哪 |
|---|---|---|
| `max_code_length: 4` + `z` 前缀 `reverse_lookup` | 拼音 4 字母打不出 | `z` 占 1 位，码长上限同样生效，只剩 3 位 |
| `auto_select_pattern: ^[a-y]{4}$` | `douyin`/`nihao` 打一半没了 | 正则只看字母、不看候选类型；多数拼音不含 z |
| `script_translator` 混输 + `auto_select: false` | 五笔四码不自动上屏 | 把四码上屏一起关了 |

## 三、环境要求

- Windows（小狼毫 Weasel）
- 小狼毫 Weasel 0.17.x 安装包
- 上游极点五笔86 配置包（KyleBing/rime-wubi86-jidian，含 `pinyin_simp` 依赖）

## 四、快速开始

详见 `QUICKSTART.md`。五步概要：

1. 安装小狼毫 Weasel；
2. 解压上游配置包到 `%AppData%\Rime\`；
3. 用本仓库 `config\` 下的方案文件覆盖同名文件；
4. 以管理员身份运行 `dict\setup-symlinks.cmd` 建立软链接；
5. 右键托盘图标 →「重新部署」。

## 五、安装与部署（详细）

### 5.1 素材

- **安装包 + 上游配置包（zip）**：自行准备（见 `QUICKSTART.md` 下载地址），或自行保管。
- **本仓库**：方案文件（`config\`）+ 词库（`dict\`）+ 屏蔽脚本（`lua\`）+ 算码器（`scripts\`）。

### 5.2 步骤

**第 0 步 · 清理旧残留**（新机迁移时）：删除 `%AppData%\Rime\` 下的旧方案文件 `wubi86_jidian.schema.yaml`、`wubi86_jidian_pinyin.schema.yaml`、`default.custom.yaml` 及整个 `build\` 文件夹。全新安装可跳过。

1. 装好小狼毫 Weasel（用户目录保持默认 `%AppData%\Rime`）。
2. 解压 `rime-wubi86-jidian-master.zip` 的**全部文件**到 `%AppData%\Rime\`（注意取出 zip 内顶层目录里的文件，别整目录塞入）。
   - 此步不能省：方案声明 `dependencies: [pinyin_simp]`，z 引导拼音依赖 zip 里的 `pinyin_simp.schema.yaml` 与 `pinyin_simp.dict.yaml`；缺它们，`zdouyin`→「抖音」会静默失效。
3. 用本仓库 `config\` 下的 `wubi86_jidian.schema.yaml`、`default.custom.yaml`、`weasel.custom.yaml` 覆盖 `%AppData%\Rime\` 同名文件。
   - 完成判据：`%AppData%\Rime\default.custom.yaml` 的 `schema_list` 只含 `wubi86_jidian`。
4. 以管理员身份运行 `dict\setup-symlinks.cmd`，建立三条软链接：词库、候选屏蔽 `lua\cand_blocker.lua`、英文回显 `lua\english.lua`。
   - 完成判据：cmd 结尾自动列出三条 `<SYMLINK>`。
   - ⚠️ lua 链接必须先于重新部署存在；否则 `lua_filter@*cand_blocker` 取不到模块会导致一个字都打不出。
5. 右键托盘图标 →「重新部署」→ 等「部署成功」。
   - 完成判据：`%AppData%\Rime\build\wubi86_jidian.schema.yaml` 时间戳刷新为当前时刻。

> 手动等价命令见 `dict\symlink-commands.txt`。

### 5.3 改完配置如何生效

1. 改本仓库 `config\wubi86_jidian.schema.yaml`（它是唯一真相源）；
2. 复制到 `%AppData%\Rime\` 覆盖同名文件（`diff` 应无输出）；
   - 注：`*.custom.yaml` 部署时会被重写 `customization.modified_time`，永远 `diff` 有输出属正常，别误判。
3. 校验 YAML 语法（可选）：`python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1],encoding='utf-8'))" 文件路径`；
4. 重新部署（见上）。

## 六、配置详解

文件：`%AppData%\Rime\wubi86_jidian.schema.yaml`；源文件：本仓库 `config\wubi86_jidian.schema.yaml`（两份内容必须一致）。

**z 引导拼音：**

1. `engine.segmentors` 含 `affix_segmentor@pinyin_hint`；`engine.translators` 含 `script_translator@pinyin_hint`（取代 `reverse_lookup_translator`）。
2. `speller: { max_code_length: 4, auto_select: true }`。
3. `recognizer.patterns.pinyin_hint: "^z[a-z]*$"` —— 必须与第 1 条成对。

**反引号引导英文：**

4. `engine.segmentors` 含 `affix_segmentor@english`；`engine.translators` 含 `lua_translator@*english`（**注意带 `*`**）。
5. `recognizer.patterns.english: "^`.*$"` —— 必须与第 4 条成对。
6. 配置块 `english: { tag: english, prefix: "`", tips: 〔英文〕 }` + `lua/english.lua`。

**附带功能：** `reverse_lookup_filter@wubi_code_hint`（拼音候选标注五笔码）、`lua_filter@*cand_blocker`（候选屏蔽）、`zh_trad` 简繁开关。

### 反引号英文机制

1. `recognizer.patterns.english` 命中后 `PushInput` + `kAccepted`，反引号进入合成串（不靠 `speller.alphabet`），并中断 `speller` 的 auto_select（英文可打任意长度）。
2. `matcher` 给段打 `english` 标签。
3. `affix_segmentor@english` 据 `english.prefix` 剥掉反引号，剩余字母段交下游。
4. `lua_translator@*english` → `lua/english.lua` 把该段原样回显为唯一候选；空格确认即整串上屏；`Commit → Clear` 后自动回五笔。

配置片段：

```yaml
engine:
  segmentors:
    - affix_segmentor@english
  translators:
    - lua_translator@*english
recognizer:
  patterns:
    english: "^`.*$"
english:
  tag: english
  prefix: "`"
  tips: 〔英文〕
```

`lua/english.lua`：

```lua
local M = {}
function M.func(input, seg, env)
    if not seg:has_tag("english") then return end
    if input == nil or input == "" then return end
    yield(Candidate("english", seg.start, seg._end, input, ""))
end
return M
```

**三个承重点（缺一即坏）：**

- `lua_translator@*english` 必须带 `*`；漏星则模块取不到、英文静默失效。
- `recognizer.patterns.english` 与 `affix_segmentor@english` 成对；`english.tag: english` 在位。
- lua 的 `seg:has_tag("english")` 守卫：缺它会污染五笔/拼音候选框。

**已知代价：** 反引号不能再当标点打；`` ` `` 后直接空格吐出反引号本身（Esc 取消）；大写用「按住 Shift + 字母」，CapsLock 会清合成；英文串中不能含空格。

## 七、使用与自检

| 测什么 | 敲 | 预期 |
|---|---|---|
| 五笔正常 | `aaaa` | 候选第 1 位「工」 |
| z 引导拼音 | `zdouyin` | 「抖音」，右侧标注五笔码 `ruuj` |
| 四码顶字上屏 | `aaaa` 不按空格再敲 `b` | 「工」自动上屏，`b` 留在输入框 |
| 长拼音不被截断 | `zzhongguo` | 「中国」 |
| 反引号英文 | `` `hello `` | 原样回显 `hello`，右侧〔英文〕 |
| 英文空格上屏 | `` `hello `` + 空格 | 上屏 `hello`，随后自动回五笔 |
| 英文长串不截断 | `` `abcdefghij `` + 空格 | 整串 `abcdefghij` |
| 英文大写 | `` `Abc `` + 空格 | `Abc`（用 Shift+字母，勿按 CapsLock） |

## 八、词库维护

词库源：本仓库 `dict\wubi86_jidian_user.dict.yaml`，经软链接映射到 Rime 用户目录，改它即生效。

```
本仓库 dict/wubi86_jidian_user.dict.yaml
        ↓ mklink 软链接
%APPDATA%\Rime\wubi86_jidian_user.dict.yaml
        ↓ 重新部署
新词生效
```

**加词流程：**

1. 算码：`python scripts/wubi_code.py 新词1 新词2`；
2. 追加一行：`词条<Tab>编码<Tab>1000000`（**Tab 分隔，不能用空格**；权重 `1000000` 锁定第 1 候选位）；
3. 重新部署（右键托盘 →「重新部署」）。

**编码规则**（出处：主码表 `encoder.rules`）：

| 词长 | 规则 | 示例 |
|---|---|---|
| 2 字 | 第1字前2码 + 第2字前2码 | 核岛 = sy + qy → `syqy` |
| 3 字 | 第1字首码 + 第2字首码 + 第3字前2码 | 演 `d` 示 `r` 科 `t` 技 `l` → `drtl` |
| 4–10 字 | 第1、2、3字首码 + 末字首码 | 同上 |

**例外（不用规则硬算，等用户给码）：** 含标点/数字/英文的长句、超 10 字、长公司名/专名（用户惯例取拼音首字母）。专名默认先问再写。

**删词：** 自己加的词直接在词库删行；上游原生词删不掉，改用候选屏蔽（见下）。

**校验：** `python scripts/wubi_code.py --check` / `--list`。

## 九、候选词屏蔽（lua_filter）

隐藏不想看到的候选词，不改词库。唯一需维护的文件：`lua/cand_blocker.lua`，把词加进顶部 `blocked_list`：

```lua
local blocked_list = {
  "程朱",
  -- 想屏蔽谁就加一行
}
```

保存 → 重新部署 → 生效。

> ⚠️ 挂载须带 `*`：schema 的 `engine.filters` 首行 `- lua_filter@*cand_blocker`；入口函数名须为 `M.func`。任一写错会导致输入法一个字都打不出（旧版 librime-lua 无空函数保护）。排查：`%TEMP%\rime.weasel\` 目录下的 `*.log.ERROR.*.log`。

## 十、排障

| 现象 | 先查 |
|---|---|
| 拼音打不出 / 打一半被顶 | `segmentors` 与 `recognizer.patterns` 的 `pinyin_hint` 是否成对 |
| 英文打不出 / 没反应 | ①`recognizer.patterns.english` 与 `affix_segmentor@english` 成对；②`lua_translator` 带 `*`；③`lua\english.lua` 软链接；④`english.tag` 在位 |
| 英文回显成 `` `abc `` | `english.prefix`/`english.tag` 缺失 |
| 英文字母第 4 位被截断 | `recognizer.patterns.english` 被改坏，成对拆散 |
| 五笔/拼音混入原样回显项 | lua `has_tag` 守卫被删 |
| 五笔四码不自动上屏 | `speller.auto_select` 是否为 `true` |
| 一个字都打不出 | lua 过滤器取不到模块（缺 `*` 或软链接未建），查 `%TEMP%\rime.weasel\` 日志 |
| 改完没反应 | 是否重新部署；`build\` 时间戳是否刷新 |
| 新加的词打不出 | Rime 按时间戳增量编译；词库 mtime 早于 `build\*.table.bin` 会跳过重建。解法：`touch` 词库或删 `build\` 后重新部署 |
| 全英文、崩溃 | 删 `%AppData%\Rime\build\` 整个文件夹后重新部署 |

## 十一、回滚

部署前建议备份 `%AppData%\Rime\` 下的 `wubi86_jidian.schema.yaml`、`default.custom.yaml`、`weasel.custom.yaml`。如需回退，将备份拷回并重新部署即可。

## 十二、文件结构

| 路径 | 作用 |
|---|---|
| `config/` | 配置源（schema / default.custom / weasel.custom） |
| `dict/` | 词库源 + 软链接脚本 |
| `lua/` | 候选屏蔽 `cand_blocker.lua`、英文回显 `english.lua` |
| `scripts/wubi_code.py` | 五笔86 算码 / 校验 / 列出 |
| `LICENSE` | Apache-2.0 全文 |
| `ACKNOWLEDGEMENTS.md` | 上游版权与许可证 |
| `QUICKSTART.md` | 五步快速安装 |
| `README.md` | 本文档 |

## 十三、许可证与致谢

本仓库以 **Apache-2.0** 发布。完整上游版权与再分发要求见 `ACKNOWLEDGEMENTS.md`。

要点：

- 直接来源（Apache-2.0）：`gnfy/rime-wubipinyin`（z 引导拼音结构）、`KyleBing/rime-wubi86-jidian`（极点五笔86 码表）。
- 运行依赖（GPL-3.0 / LGPL-3.0 / BSD-3-Clause）：`rime/weasel`、`rime/librime`、`rime/plum`、`hchunhui/librime-lua`、`rime/rime-wubi`。

## 附：设计出处

核心结构取自 [gnfy/rime-wubipinyin](https://github.com/gnfy/rime-wubipinyin)（基于 KyleBing/rime-wubi86-jidian 码表重构，Apache-2.0），其 `docs/design.md` 有完整的「为什么不能无前缀混输」论证与 `tools/collision_check.py` 复现脚本。
