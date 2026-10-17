# Rime 小狼毫 · 极点五笔86（z 引导拼音 · 反引号引导英文）— AI 复现与维护指南

> **本文件的定位**：这台机器 Rime 输入法的权威说明（**2026-10-17 版，当前权威**）。
>
> 配置文件的**字面内容以实际文件为准**，本文件不复制它们，只记录文件里看不出来的东西：
> 为什么这样配、哪些坑踩过、改哪里会坏。
>
> **触发场景**：用户提到「五笔」「拼音打不出来」「输入法」「Rime」「小狼毫」「顶字上屏」
> 「码表」「词库」「加词」「新词」「快捷短语」「tdyw」「反引号」「英文」「`」，
> 或要求在新电脑上复现这套输入法时，读本文件。

---

## 零、本版修订记录（2026-10-17）

本版基于 `20261008=…` 版。**20261008 版内容全部仍有效**（z 引导拼音、四码顶字、软链接、词库维护均不变），本版是**增量版**：

| # | 变更 | 说明 |
|---|---|---|
| 1 | **新增功能：反引号引导英文** | 打 `` ` `` 不上屏 → 随后字母原样回显 → 空格整串上屏 → 自动回五笔。详见**第十三节** |
| 2 | **更正第二节「四码免疫」机制表述** | 真正免疫来源是 recognizer 收编按键使 speller 的 auto_select 不运行，而非"候选类型非 table"（librime-lua 的 `Candidate` 其实是可被 auto_select 接受的 `SimpleCandidate`） |
| 3 | 复现 / 自检 / 排障 / 文件地图同步更新 | 新增 `lua/english.lua` 与第 3 条软链接；自检与排障补英文项；更正第二节机制 |
| 4 | 承接软链接断链修复 | 已将两条断链重建；本次英文链接一并纳入建链接脚本（共 3 条） |

> 本功能经 3 个独立子代理盲核（不透露结论）源码级验证，三条承重结论：`lua_translator@*english` 必须带 `*`、
> `recognizer.patterns.english` 与 `affix_segmentor@english` 必须成对、`english.tag: english` 与 lua 的 `has_tag` 守卫缺一即坏。
> 三份独立子代理盲核报告：机制核实、lua 四码截断风险、回归影响（均为源码级核实）。
>
> 历史版本只读不删：`20260919`（纯五笔）、`20260920`（已废弃的无前缀混输，`auto_select_pattern` 有坑勿抄）、`20261007`、`20261008`。

---

## 一、目标与冲突（先读这节）

用户是五笔盲打用户，同时要三个目标：

1. **四码顶字上屏** — 五笔打满 4 码不按空格，敲第 5 码时前 4 码自动上屏，第 5 码成为下一词开头。
2. **拼音救场** — 不会拆的字用拼音打，**可打任意长度**（`zhong`/`zhuang`/`douyin` 等 5–6 字母）。
3. **反引号引导英文** — 打 `` ` `` 不上屏，随后英文字母原样回显，空格整串上屏，打完自动回五笔（详见**第十三节**）。

**目标 1 和 2 天然冲突**（数到第 4 个字母时，引擎分不清这是五笔码还是拼音），解法是 z 引导（见下）。

冲突的根源：「四码上屏」靠**数到第 4 个字母**触发；「无前缀拼音」意味着拼音也从第 1 个字母开始数。
五笔和拼音**共用同一套字母**，引擎在第 4 个字母处无法判断这是五笔码还是拼音。

**目标 3 与 1、2 不冲突**：反引号在五笔码表里是空集（同 `z`），用 `recognizer.patterns.english` 切成独立段、
走独立 translator，与五笔/拼音互不干扰——这是它能与 z 引导共存的根本原因。

实测数据（gnfy/rime-wubipinyin 的 `tools/collision_check.py`）：无前缀混输 + 四码上屏，
**每 7 个高频拼音词就有 1 个被顶掉**（约 13–15%）。这是数学上不可兼得，不是实现缺陷。

---

## 二、判定机制（决定一切的一节）

librime 的四码上屏（`AutoSelectAtMaxCodeLength`）**只对 `table` / `user_table` 类型候选生效**。

| 候选来源 | 候选类型 | 受四码上屏影响 |
|---|---|---|
| `table_translator`（五笔码表） | table | **是** ← 正是要它顶 |
| `script_translator`（真拼音引擎，走 prism 切音节） | phrase | **否** ← 天然免疫 |
| `reverse_lookup_translator`（拿 table 型词典做反查） | table | **是** ← 踩坑点 |
| `auto_select_pattern`（正则匹配输入串） | 全部 | **是** ← 踩坑点，它不看候选类型 |

**由这张表推出唯一正确解法**：让拼音走 `script_translator`，并用 `z` 把它切成**独立分段**。

**为什么引导键必须是 `z`**：五笔86 码表不含任何 `z` 开头的编码（`z` 是万能键，不作为编码首字母）。
「`z` 开头」在五笔世界里是空集 → 零歧义，引擎不必猜。其它字母做不到这一点。

> ⚠️ **2026-10-17 机制更正（重要）**：上表「拼音 / `script_translator` 免疫四码上屏」的**真正原因不是候选类型**。
> librime 的 `is_auto_selectable` 其实也接受任意 `SimpleCandidate`——而 librime-lua 的 `Candidate(...)` 产出正是 `SimpleCandidate`，
> 所以"phrase 型免疫"的说法不严密。**真正的免疫链**：`recognizer` 处理器在按键层命中 pattern 后执行 `PushInput` 并返回 `kAccepted`，
> 引擎 `ProcessKey` 遇 `kAccepted` 立即中断整条处理器链 → **`speller` 的 `AutoSelectAtMaxCodeLength` / `AutoSelectUniqueCandidate` 全程不运行**。
> z 拼音与反引号英文都靠这**第一层**免疫（候选类型只是第二层）。**实践铁律**：`recognizer.patterns.<name>` 必须与对应 `affix_segmentor@<name>`
> **成对存在**；一旦拆散，该段退回 speller 管辖，会在第 4 码被 auto_select 截断。

---

## 三、三种错误配法（历史踩坑，识别症状用）

| 配法 | 用户会这样描述症状 | 错在哪 |
|---|---|---|
| `max_code_length: 4` + `z` 前缀 `reverse_lookup` | 「拼音 4 个字母打不出来」 | `z` 占 1 位，码长上限对 `z`+拼音同样生效，只剩 3 位 |
| `auto_select_pattern: ^[a-y]{4}$` | 「`douyin`/`nihao`/`shang` 打一半就没了」 | 正则只数字母、不看候选类型；`[a-y]` 想用「含 z = 拼音」区分，但多数拼音不含 z |
| `script_translator` 混输 + `auto_select: false` | 「五笔四码不自动上屏了」 | 把四码上屏一起关掉了 |

**若用户描述的正是以上症状**，说明配置被改回了旧版 —— 按第四节修正。

---

## 四、当前正确配置（要点 + 状态核对）

文件：`%AppData%\Rime\wubi86_jidian.schema.yaml`
源文件：`<本仓库根目录>\config\wubi86_jidian.schema.yaml`（两份内容必须一致）

其余照抄文件，只需认准这些要点：

**z 引导拼音（原有）：**

1. `engine.segmentors` 含 `affix_segmentor@pinyin_hint`；`engine.translators` 含 `script_translator@pinyin_hint`
   —— 它**取代** `reverse_lookup_translator`。
2. `speller: { max_code_length: 4, auto_select: true }`
3. `recognizer.patterns.pinyin_hint: "^z[a-z]*$"`
   —— **必须与第 1 条成对存在**，缺这条 affix_segmentor 不剥前缀，`z` 会当普通字母进五笔码表。

**反引号引导英文（2026-10-17 新增，详见第十三节）：**

4. `engine.segmentors` 含 `affix_segmentor@english`；`engine.translators` 含 `lua_translator@*english`（**注意带 `*`**）
5. `recognizer.patterns.english: "^`.*$"` —— **必须与第 4 条成对存在**，缺它英文功能失效
6. 配置块 `english: { tag: english, prefix: "`", tips: 〔英文〕 }` + `lua/english.lua`（原样回显，`M.func` + `has_tag` 守卫）

附带功能（用户确认保留）：
- `reverse_lookup_filter@wubi_code_hint`（拼音候选右侧标注五笔编码，边打边学）
- `lua_filter@*cand_blocker`（候选词黑名单，见 12.7）
- `zh_trad` 简繁开关（opencc `s2hk.json`，数据在 Weasel 安装目录 `data/opencc/`）

### 4.1 状态核对（改配置后 / 接手时必跑）

本机部署目录的正确状态应是：

| 检查项 | 正确值 |
|---|---|
| `wubi86_jidian.schema.yaml` | 与 `config\` 那份 **diff 无输出**（z + 反引号英文版，约 4.1 KB） |
| `default.custom.yaml` 的 `schema_list` | **只含** `wubi86_jidian` |
| 词库软链接 `wubi86_jidian_user.dict.yaml` | 指向 **git 包** `<本仓库根目录>\dict\…` |
| lua 软链接 `lua\cand_blocker.lua` | 指向 **git 包** `<本仓库根目录>\lua\…` |
| lua 软链接 `lua\english.lua` | 指向 **git 包** `<本仓库根目录>\lua\…`（2026-10-17 新增，第 3 条） |
| `build\wubi86_jidian.schema.yaml` 时间戳 | 为最近一次「重新部署」的时刻 |

> ⚠️ **历史沿革**：本机 2026-10-08 前跑的是旧方案（`schema_list` 指向 `wubi86_jidian_pinyin`、
> `auto_select: false`、无 `pinyin_hint`）。2026-10-08 已对齐 z 方案：schema 与 `default.custom.yaml` 同步、
> 备份建于 `backup_20261008\`。同日 git 包由 `rime-wubi-dict` **改名为 `rime-wubi86`**，
> **两条软链接已随之重建**（命令见 10.2）；2026-10-17 新增第 3 条：`lua\english.lua`（反引号英文）。

---

## 五、操作：在新电脑上复现

> **素材分工**（两处都要就位）：
> - **安装包 + 上游配置包（zip）** → 本地安装素材目录（自行保管，例如 `~\Downloads\rime\`）
>   也可自行下载：Weasel 安装包 → `https://github.com/rime/weasel/releases` ；
>   上游配置包 → `https://github.com/KyleBing/rime-wubi86-jidian`
> - **指南 + 配置源（`config\`）+ 词库 + skill + 算码器 + 屏蔽黑名单** → git 仓库 `<本仓库根目录>\`
>   （新电脑需先把该仓库 clone 或拷贝到位，否则第 3、4 步没有源）
>
> ⚠️ **复现的硬前提**：`rime-wubi-multimode` 目录必须**已纳入仓库版本管理**。
> 若它仍是 untracked 状态（`git status` 显示 `?? rime-wubi-multimode/`），
> 那么 clone 出来的副本里**不会有这些文件**，整条链路断在第一步。
> 该前提**由仓库维护者（用户本人）负责保证**——操作者若发现不满足，**停下来告知即可，
> 不要自行执行仓库操作**。替代方案：把该目录**整目录拷贝**到新机同一位置。

**第 0 步 · 清理旧残留（本版新增）**
若新机曾装过 Rime 或从旧机迁移，先清 `%AppData%\Rime\` 里的旧方案文件：
`wubi86_jidian.schema.yaml`、`wubi86_jidian_pinyin.schema.yaml`、`default.custom.yaml`、`build\` 整个文件夹。
全新安装可跳过本步。**`build\` 可安全删除**（会重建）。

1. 装好小狼毫 Weasel（本目录内有 `weasel-0.17.4.0-installer.exe`，双击按向导走，用户目录保持默认 `%AppData%\Rime`）。
2. 解压 `rime-wubi86-jidian-master.zip` 的**全部文件**到 `%AppData%\Rime\`
   （⚠️ zip 内有顶层目录，注意把里面的文件取出来放进 `%AppData%\Rime\`，
   不要整个目录塞进去，否则 Rime 读不到）。
   - **这一步不能跳过**：方案声明了 `dependencies: [pinyin_simp]`，
     `z` 引导拼音依赖 zip 里的 `pinyin_simp.schema.yaml` 与 `pinyin_simp.dict.yaml`；
     少了它们，第七节的核心验收项 `zdouyin` →「抖音」会**静默失效**。
   - 说明：zip 里也含 `wubi86_jidian_pinyin.schema.yaml`（上游旧方案），
     只要第 3 步的 `default.custom.yaml` 覆盖正确，它不会被启用，留着无害。
3. 用 git 包 `config\` 下的 `wubi86_jidian.schema.yaml`、`default.custom.yaml`、`weasel.custom.yaml`
   覆盖 `%AppData%\Rime\` 下的同名文件。
   - **完成判据**：`%AppData%\Rime\default.custom.yaml` 的 `schema_list` 只含 `wubi86_jidian`。
4. **建立软链接**：右键运行 `<本仓库根目录>\dict\setup-symlinks.cmd`
   （**以管理员身份运行**）。它会建**三条**：
   - 词库 `wubi86_jidian_user.dict.yaml` → git 包
   - 屏蔽黑名单 `lua\cand_blocker.lua` → git 包
   - 英文回显 `lua\english.lua` → git 包（2026-10-17 新增）

   - **完成判据**：这三条都显示为指向 git 包的软链接（cmd 结尾会自动列出核对）。
   - 手动等价命令见 **git 仓库**的 `dict\新电脑-mklink软链接命令.txt`。
   - ⚠️ **lua 链接必须先于重新部署存在**：schema 里挂了 `lua_filter@*cand_blocker`，
     若 lua 文件取不到，旧版 librime-lua 会因空函数导致**一个字都打不出来**（详见 12.7）。
5. 重新部署（见第六节）。
6. 跑第七节自检清单。

> ⚠️ **不要**照 `20260920=…` 旧指南的**方案部分**操作——它描述的是**已废弃的无前缀混输**方案，
> 其中的 `auto_select_pattern` 写法有坑。旧指南只可用于参考 Weasel 安装向导的界面步骤。

---

## 六、操作：改完配置让它生效

1. 改 `<本仓库根目录>\config\wubi86_jidian.schema.yaml`（**改源文件**，它是唯一真相源）。
2. 复制到 `%AppData%\Rime\` 覆盖同名文件。
   - **完成判据**：`wubi86_jidian.schema.yaml` 两份内容一致（`diff` 无输出）。
     ⚠️ 该判据**不适用于** `default.custom.yaml` 等 `*.custom.yaml`——Rime 部署时会重写其中的
     `customization.modified_time`，所以它们**永远 diff 有输出**，属正常现象，别误判为"没同步成功"。
3. 校验 YAML 语法：
   ```bash
   python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1],encoding='utf-8'))" 文件路径
   ```
   - 若无 pyyaml，装进隔离 venv：`<python> -m venv <env>` 后 `<env>/Scripts/pip install pyyaml`。
4. **重新部署**。这一步有两个环境事实，务必知道：
   - **命令行 `WeaselDeployer.exe /deploy` 从脚本启动会失败**（沙箱拦截 → SIGTERM；PowerShell
     `Start-Process` 报 sandbox-center 错误）。**可靠路径是让用户手动操作**：
     > 右键任务栏右下角小狼毫托盘图标 → 「重新部署」 → 等「部署成功」弹窗。
   - **完成判据**：`%AppData%\Rime\build\wubi86_jidian.schema.yaml` 的修改时间刷新为当前时刻。
     时间戳没变 = 部署没发生，配置未生效。
5. 跑第七节自检清单。

---

## 七、自检清单（每次改配置后必跑）

| 测什么 | 敲 | 预期 |
|---|---|---|
| 五笔正常 | `aaaa` | 候选第 1 位「工」 |
| **z 引导拼音** | `zdouyin` | 「抖音」，右侧标注五笔码 `ruuj` |
| **四码顶字上屏** | `aaaa` 不按空格再敲 `b` | 「工」自动上屏，`b` 留在输入框 |
| 长拼音不被截断 | `zzhongguo` | 「中国」（验证 6 字母以上不被顶） |
| 业务词库（演示） | `whsz` | 「演示科技深圳分公司」 |
| **反引号英文** | `` `hello `` | 原样回显 `hello`，右侧〔英文〕提示 |
| **英文空格上屏** | `` `hello `` +空格 | 上屏 `hello`，随后直接打五笔（自动回五笔） |
| **英文长串不截断** | `` `abcdefghij `` +空格 | 整串 `abcdefghij`（验证不在第 4 字母被顶） |
| **英文大写** | `` `Abc `` +空格 | `Abc`（用"按住 Shift+字母"输大写，勿按 CapsLock） |

第 2、3 条是这套配置的**核心验收项**：第 2 条证明拼音走通了 script 通道，第 3 条证明五笔顶字手感还在。

> **词条出处已核**（2026-10-08）：`抖音` 在 `pinyin_simp.dict.yaml`（dou yin）与主码表（`ruuj`）均存在；
> `中国` 在 pinyin_simp（zhong guo）与主码表（`khlg`）均存在；`工` 主码表有 `a`/`aaa`/`aaaa` 三码。
> 若自检第 2 条不出「抖音」，先查 `pinyin_simp.*` 是否就位（第五节第 2 步）。

---

## 八、排障

| 现象 | 先查 |
|---|---|
| 拼音打不出 / 打一半被顶 | `segmentors` 与 `recognizer.patterns` 里的 `pinyin_hint` 是否**成对**存在 |
| 英文打不出 / 完全没反应 | ①`recognizer.patterns.english` 与 `affix_segmentor@english` 是否成对；②`lua_translator` 是否带 `*`（须 `@*english`）；③`lua\english.lua` 软链接是否建；④`english.tag` 是否在位。见第十三节 |
| 英文回显成 `` `abc ``（带反引号） | `english.prefix`/`english.tag` 配置块缺失 → affix 没剥前缀 |
| 英文字母串第 4 位被截断 | `recognizer.patterns.english` 被删/改坏 → 拆散了成对，该段退回 speller、第 4 码被 auto_select 顶掉 |
| 五笔/拼音候选框混入「原样回显」项 | lua 的 `seg:has_tag("english")` 守卫被删 → 对所有段都 yield |
| 五笔四码不自动上屏 | `speller.auto_select` 是否为 `true` |
| **一个字都打不出来** | lua 过滤器取不到模块（挂载缺 `*` 或函数名非 `M.func`，或 lua 软链接未建）。查 `%TEMP%\rime.weasel\` 下 `*.log.ERROR.*.log`，见 12.7 |
| 改完没反应 | 是否重新部署；`build\` 时间戳是否刷新 |
| **新加的词 / 换过的词库打不出** | Rime 按**时间戳**增量编译：若词库源 mtime **早于** `build\wubi86_jidian.table.bin`，它认为"没变"会**跳过重建**（从别处拷来的词库常踩此坑）。解法：`touch` 词库文件刷新 mtime，或删 `build\` 整个文件夹后重新部署 |
| 什么都不出、只出英文字母 | 引擎崩溃缓存。**删除 `%AppData%\Rime\build\` 整个文件夹**后重新部署，会自动重建 |
| 部署报错 | 看 `%TEMP%\rime.weasel\` **目录**下的 `*.log.ERROR.*.log`（`rime.weasel` 是目录，不是文件名前缀） |

---

## 九、回滚

备份位置：`%AppData%\Rime\backup_20261008\`（4 个文件：
`wubi86_jidian.schema.yaml`、`default.custom.yaml`、`weasel.custom.yaml`、`wubi86_jidian_pinyin.schema.yaml`）。

还原：把其中 `wubi86_jidian.schema.yaml`、`default.custom.yaml` 拷回 `%AppData%\Rime\`，重新部署。

> 说明：20261007 版记载的 `backup_20261007\` **实际不存在**（本版修订记录 #2）。
> `backup_20261008\` 是 2026-10-08 对齐前建立的、真实存在的备份。

---

## 十、文件地图

| 路径 | 作用 |
|---|---|
| `%AppData%\Rime\` | 部署目录，Rime 实际读取处 |
| **`<本仓库根目录>\`** | **全套方案（git 管理，当前权威）**：指南 + `config\` 配置源 + 词库 + skill + 算码器 + 屏蔽黑名单，见第十二节 |
| `<本仓库根目录>\config\` | **配置源**，改这里再同步到 `%AppData%\Rime\` |
| `<本仓库根目录>\lua\english.lua` | 反引号英文回显 translator（软链接到 `%AppData%\Rime\lua\`） |
| `<本仓库根目录>\lua\cand_blocker.lua` | 候选词屏蔽黑名单（软链接） |
| `<本仓库根目录>\*.md` | 指南（本文件即在其中） |
| `rime-wubi86-jidian-master.zip` | 上游极点五笔配置包（KyleBing） |
| `weasel-0.17.4.0-installer.exe` | Weasel 安装包 |
| `%AppData%\Rime\build\` | 编译产物，可安全删除（会重建），其时间戳是部署是否发生的证据 |
| `20260919=…指南.md` | 初版（纯五笔），历史参考 |
| `20260920=…指南.md` | 第二版，描述的是**已废弃的无前缀混输**方案，其第三节 `auto_select_pattern` 写法有坑，勿照抄 |
| `20261007=…指南.md` | 第三版（z 引导方案），但其「本机状态」描述与实际不符，见 20261008 修订记录 |
| `20261008=…指南.md` | 上一权威：z 引导方案 + 软链接断链修复 |
| 本文件 | **当前权威**：z 引导 + 反引号引导英文（2026-10-17 版） |

### 10.1 两处素材的关系（易混，务必分清）

- **方案文件**（`wubi86_jidian.schema.yaml`）**不是**软链接 → 改完必须**双写**源与部署目录。
- **词库**（`wubi86_jidian_user.dict.yaml`）、**lua 黑名单**（`cand_blocker.lua`）、**英文回显**（`english.lua`）**是**软链接 → 只改 git 包源一处。

### 10.2 软链接建立 / 重建命令（改名或迁移后必做）

三条软链接指向 git 包；**git 包一旦改名或移动，链接即断**（表现为词库丢失、屏蔽失效、英文失效）。
**以管理员身份**打开终端（Win+X → 终端(管理员)），逐行运行：

```bat
:: 1) 词库：先删旧链接，再指向 git 包
del "%AppData%\Rime\wubi86_jidian_user.dict.yaml"
cmd /c mklink "%AppData%\Rime\wubi86_jidian_user.dict.yaml" "<本仓库根目录>\dict\wubi86_jidian_user.dict.yaml"

:: 2) lua 屏蔽黑名单：目录不存在则先建
if not exist "%AppData%\Rime\lua" mkdir "%AppData%\Rime\lua"
cmd /c mklink "%AppData%\Rime\lua\cand_blocker.lua" "<本仓库根目录>\lua\cand_blocker.lua"

:: 3) lua 反引号英文回显（2026-10-17 新增）
cmd /c mklink "%AppData%\Rime\lua\english.lua" "<本仓库根目录>\lua\english.lua"
```

**推荐**：直接右键运行 `<本仓库根目录>\dict\setup-symlinks.cmd`（管理员），
它自动完成上面三步并核对结果，可重复运行。

完成后：`dir /AL "%AppData%\Rime\wubi86_jidian_user.dict.yaml" "%AppData%\Rime\lua\cand_blocker.lua" "%AppData%\Rime\lua\english.lua"`
应显示三条 `<SYMLINK>`，目标均在 `<本仓库根目录>\` 下。

> ⚠️ 顺序：**先建 lua 链接，再重新部署**。schema 挂了 `lua_filter@*cand_blocker`，
> lua 取不到会导致输入法完全打不出字（见 12.7）。

---

## 十一、长句指令与词库（重要）

**长句指令（如 `tdyw`）由词库文件提供，不依赖 `custom_phrase.txt`。**

- 文件：`<本仓库根目录>\dict\wubi86_jidian_user.dict.yaml`
- 加载路径：由 `wubi86_jidian.dict.yaml` 的 `import_tables` 引入，**已验证生效**
- 格式：`词条<Tab>编码<Tab>权重`，权重填 `1000000` 即锁定第 1 候选位
- 当前内容示例：

```yaml
## 常用长句与快捷指令
先确认是否完全理解我的意思？先不执行，我确认后再执行。	tdyw	1000000
```

**2026-10-07 已清理的冗余文件**：`dict\custom_phrase.txt` 及其在部署目录下的软链接（已删除）。

清理依据：Rime **不会自动读取** `custom_phrase.txt`，必须在方案里显式挂载 `table_translator@custom_phrase`。
核查证据：`%AppData%\Rime\`（含 `build\`）与 `config\` 下所有 yaml 中 `grep custom_phrase` **均无结果** ——
该文件从未生效；其唯一词条 `tdyw` 在词库里也有一份且权重更高，属纯冗余。

**若日后要改用 `custom_phrase` 机制**（而非走词库），在 `wubi86_jidian.schema.yaml` 加：

```yaml
engine:
  translators:
    - table_translator@custom_phrase    # 排在五笔主翻译器之前
    - table_translator
custom_phrase:
  dictionary: ""
  user_dict: custom_phrase
  db_class: stabledb
  enable_completion: false
  enable_sentence: false
  initial_quality: 99
```

**当前不使用此机制** —— 长句一律走词库，保持单一真相源。同一句话在两处各写一份正是本次清理的原因。

---

## 十二、词库维护（词库源在 git 包内）

### 12.0 仓库分工（2026-10-08 调整）

| 内容 | 存放位置 | 同步方式 |
|---|---|---|
| **指南 + 配置源 + skills + 词库 + 脚本（全套方案）** | `<本仓库根目录>\` | **git** |
| 安装包 + 上游配置包（zip） | 本地安装素材目录（自行保管） | 本地 |

**词库源 = `<本仓库根目录>\dict\wubi86_jidian_user.dict.yaml`**
（旧副本已清理。）

```
<本仓库根目录>\dict\wubi86_jidian_user.dict.yaml   ← 词库源，AI 改这里
        ↓ mklink 软链接
%AppData%\Rime\wubi86_jidian_user.dict.yaml                      ← Rime 实际读取
        ↓ 用户重新部署
新词生效
```

**每次加词的完整链路**：

```
AI 改 git 包里的 yaml  →  （用户自行 git 提交）  →  用户重新部署  →  新词生效
```

> **AI 职责边界**：加词只做「改 yaml」这一步，**到此为止**。
> git 提交是用户自己的事——**不要向用户提 git、不要给 git 命令、不要提醒提交**。

（对比：方案文件 `wubi86_jidian.schema.yaml` **不是**软链接，改完必须双写源与部署目录；
词库是软链接，只改源一处。）

### 12.1 加词流程（AI 执行）

1. **算码**：`python "<本仓库根目录>\scripts\wubi_code.py" 新词1 新词2`
2. **选分组**：追加到 `## 常用长句与快捷指令` / `## 企业与常用专有名词` / `## 技术与日常词汇`
   之一，或新建 `## 组名`
3. **追加一行**到 `<本仓库根目录>\dict\wubi86_jidian_user.dict.yaml`：
   `词条<Tab>编码<Tab>1000000`
   - **必须用 Tab 分隔**（不能用空格）；权重 `1000000` = 锁定第 1 候选位
4. **提醒用户重新部署** —— 右键托盘「重新部署」。**到此结束，不提 git。**

### 12.2 编码规则（出处：`wubi86_jidian.dict.yaml` 的 `encoder.rules`）

| 词长 | 规则 | 示例 |
|---|---|---|
| 2 字 | 第1字前2码 + 第2字前2码 | 核岛 = 核(sy)+岛(qy) → `syqy` |
| 3 字 | 第1字首码 + 第2字首码 + 第3字前2码 | 示例甲 → `ailg`（演示专名，用户指定码） |
| 4–10 字 | 第1、2、3 字首码 + 末字首码 | 演示科技 → `drtl`（规则示例；实际词库可用用户指定码） |

### 12.3 规则算不了的情况 → 由用户指定编码

- 含标点 / 数字 / 英文的长句（如 `tdyw`、`mdzl`、`mgsz`）
- 超过 10 字
- 长公司名 / 专名 —— 用户惯例是**取关键词的拼音首字母**（`whsz` = 演示…深圳、`whhw` = 演示科技）

**这类不要用五笔规则硬算，等用户给码。**

**专名尤其如此**：即使字数落在规则范围内（如 4 字的「演示科技」，规则算出 `drtl`），
用户实际用的是拼音首字母 `whhw`。所以 **AI 算出的码要展示给用户确认，专名默认先问再写**。

### 12.4 已知人工差异（保留，不要"纠正"）

`分公司` 实际 `fwng`（规则算 `wwng`）、`示例乙` 实际 `fggd`（规则算 `fgga`）。
用户手写的码优先于规则计算结果。

### 12.5 校验命令

```bash
python "<本仓库根目录>\scripts\wubi_code.py" --check    # 列出全部不合规词条
python "<本仓库根目录>\scripts\wubi_code.py" --list     # 列出全部词条
```

---

### 12.6 实操案例（已验证 2026-10-07）

| 词 | 编码 | 结果 |
|---|---|---|
| 示例丁 | `tkri` | ✓ 生效（权重 1000000，锁定第 1 候选位） |
| 清理无效或临时文件，只保留有用的。先出清单，我确认后再删。 | `igwq` | ✓ 生效 |

**经验（实测）**：加词后重新部署，**若未立即生效，再部署一次或切换一次输入法即可**——
首次部署有时不会马上反映新词。判定部署是否发生的客观证据：`build\wubi86_jidian.table.bin`
的修改时间与体积（加词后会增大）。

---

### 12.7 屏蔽候选词（lua_filter，2026-10-07 建立）

**用途**：把不想看到的候选词从候选框里隐藏掉，**不修改任何词库文件**（上游码表保持原样）。

**一个文件搞定**——黑名单直接内嵌在脚本里：

```
<本仓库根目录>\lua\cand_blocker.lua   ← 唯一需要维护的文件
        ↓ mklink 软链接
%AppData%\Rime\lua\cand_blocker.lua                  ← Rime 读取处
```

**当前黑名单**（2026-10-08 核对）：`程朱`、`濔`、`血仇`。

**怎么用**：打开 `cand_blocker.lua`，把要屏蔽的词加进顶部的 `blocked_list`：

```lua
local blocked_list = {
  "程朱",
  "濔",
  "血仇",
  -- "下一个要屏蔽的词",
}
```

保存 → 重新部署 → 生效。**不用动词库，不用改 schema。**

**一次性挂载**（已完成，勿重复）：`wubi86_jidian.schema.yaml` 的 `engine.filters` 首行加

```yaml
    - lua_filter@*cand_blocker
```

放在 `filters` 最前，让它尽早过滤。**注意 `*` 不能漏**（原因见下方踩坑）。

**注意**：lua 过滤器依赖 librime-lua 插件（小狼毫自带）；若加载失败，`build\` 日志会记录，
表现为该过滤器静默失效，其余功能不受影响。

> ⚠️ **踩坑（2026-10-07 实测，已双代理核实）**：lua 过滤器有两处**必须写对**，错一处就出不来字。
>
> 1. **挂载要带 `*`**：`engine.filters` 里写 `- lua_filter@*cand_blocker`。
>    不带 `*` 时 librime-lua 走 `lua_getglobal` 去找同名**全局变量**，
>    而本机没有 `rime.lua`，全局不存在 → 取不到模块。带 `*` 才走 `require`。
> 2. **入口函数名必须是 `M.func`**（不能写 `M.filter`）：
>    librime-lua 源码 `src/lua_gears.cc` 的 `raw_init()` 只查 `"func"` 字段。
>
> **症状**：日志报 `func type: nil ... func type error expect function`，
> 该过滤器取到 nil、输出为空 → 候选流为空 → **输入法一个字都打不出来**
> （旧版 librime-lua 无空函数保护；新版只静默禁用该过滤器，其余功能正常）。
>
> **另有一个前置条件**：lua 文件本身必须能取到（软链接已建）。
> 若软链接未建而 schema 已挂 `lua_filter@*cand_blocker`，同样会命中上述症状。
> **所以务必先建 lua 软链接，再重新部署。**
>
> **排查入口**：`%TEMP%\rime.weasel\` 目录下的 `*.log.ERROR.*.log`
> （注意 `rime.weasel` 是**目录**，不是文件名前缀）。
>
> **参考**：hchunhui/librime-lua `src/lua_gears.cc`；iDvel/rime-ice `lua/long_word_filter.lua`
> 用 `M.func`、挂载写作 `lua_filter@*cold_word_drop.filter`。

---

### 12.8 删词（2026-10-07 补）

**先判断词在哪**——这决定方法：

| 词来自哪 | 怎么处理 | 说明 |
|---|---|---|
| `<本仓库根目录>\dict\wubi86_jidian_user.dict.yaml`（自己加的） | **直接删掉那一行** | 重新部署即消失 |
| 上游主码表 `wubi86_jidian.dict.yaml`（原生词，如「程朱」） | **删不掉，改用黑名单屏蔽**（见 12.7） | 上游文件重新下载会覆盖，删了白删 |

**定位词属于哪个文件**：

```bash
grep -n "tkri" "%APPDATA%\Rime\wubi86_jidian.dict.yaml"
```

**改词**（改编码或权重）：在词库里直接改那一行，等同「删旧 + 加新」。

---

## 十三、反引号引导英文（2026-10-17 新增）

**需求**：打 `` ` `` 不上屏 → 随后英文字母原样回显 → 空格整串原样上屏 → 打完自动回五笔。
（附带：数字/符号也会被原样收编，如 `` `ppjfeq*##&840 `` 整串输出——白赚，非需求但无害。）

**机制（完全照搬 z 引导拼音的 affix 结构，触发键换成反引号）**：

1. `recognizer.patterns.english: "^`.*$"` —— recognizer 处理器命中后 `PushInput` + `kAccepted`，
   **反引号由此进入合成串**（不是靠 `speller.alphabet`！），且引擎断链使 `speller` 的 auto_select 不运行
   （→ 英文免疫四码顶字，可打任意长度，见第二节机制更正）。
2. `matcher` 据该 pattern 给段打 `english` 标签。
3. `affix_segmentor@english` 据 `english.prefix: "`"` 剥掉反引号，剩余字母段带 `english` 标签交下游。
4. `lua_translator@*english` → `lua/english.lua` 把该段**原样回显**为唯一候选；空格确认即整串上屏；
   `Commit → Clear` 后自动回五笔。

**配置（`wubi86_jidian.schema.yaml` 4 处 + 1 块 + 1 lua）**：

```yaml
engine:
  segmentors:
    - affix_segmentor@english          # 放在 affix_segmentor@pinyin_hint 之后、abc_segmentor 之前
  translators:
    - lua_translator@*english          # ★必须带 *，否则 lua_getglobal 找不到模块、英文静默失效
recognizer:
  patterns:
    english: "^`.*$"                   # ★与 affix_segmentor@english 成对，缺一即失效
english:
  tag: english                         # ★缺此行 affix 找不到 english 段、不剥前缀
  prefix: "`"
  tips: 〔英文〕
```

`lua/english.lua`：

```lua
local M = {}
function M.func(input, seg, env)
    if not seg:has_tag("english") then return end   -- ★守卫：否则污染所有段的候选框
    if input == nil or input == "" then return end
    yield(Candidate("english", seg.start, seg._end, input, ""))
end
return M
```

**三个承重点（缺一即坏，均经源码级 + 三子代理盲核证实）**：

- `lua_translator@*english` 的 `*`：走 `require` 加载模块；漏星则 `func_ = nil`、英文 100% 静默失效（同 12.7 cand_blocker 的坑，translator 同理）。
- `recognizer.patterns.english` 与 `affix_segmentor@english` **成对**；`english.tag: english` 在位。
- lua 的 `seg:has_tag("english")` 守卫：缺它会对五笔/拼音每段都产出回显候选，污染候选框。

**为什么触发键用反引号（而非字母）**：字母 a–y 全是五笔码首字母（会撞码），`z` 被拼音占用；
反引号在五笔码表里是空集（同 `z`，零冲突），且作标点用得最少。反引号进合成靠 recognizer
（pattern 命中即收编），**不需要**改 `speller.alphabet`——改了反而让"编码中途反引号"卡进合成、需退格，零收益有回归。

**已知代价（务必知晓）**：

- 反引号不能再当标点 `` ｀ `` / `` ` `` 打（被英文 recognizer 收编）。
- `` ` `` 后直接按空格 → 吐出反引号本身（与 `z` + 空格出 `z` 同理，Esc 取消）。
- 大写用"按住 Shift + 字母"；**CapsLock 会清合成**（`ascii_composer` 的 `Caps_Lock: clear`，Rime 对所有合成的固有行为），打英文别按 CapsLock。
- 英文串中不能含空格（空格即上屏）。

**部署**：`lua/english.lua` 入 git 包 `lua\`，建第 3 条软链接（`setup-symlinks.cmd` 已含，管理员运行），再重新部署。
顺序：**先建 lua 链接，再重新部署**（translator 取不到模块只会英文失效、不殃及其它，但仍应守序）。

---

## 十四、版权与致谢

本方案是**多上游衍生产品**，公开发布须遵守各上游许可证并致谢。完整清单与合规要求见同目录
**`致谢与版权.md`**（该文件随代码一同发布）。

要点速览：

- **直接来源（Apache-2.0）**：`gnfy/rime-wubipinyin`（z 引导拼音结构/设计）、`KyleBing/rime-wubi86-jidian`（极点五笔86 码表）。再分发须保留其版权声明，并注明本方案修改。
- **运行依赖（GPL-3.0 / LGPL-3.0 / BSD-3-Clause）**：`rime/weasel`（前端）、`rime/librime`（核心）、`rime/plum`（配方）、`hchunhui/librime-lua`（Lua 引擎）、`rime/rime-wubi`（五笔方案参考）。本方案仅使用、未改其源码，按许可证致谢即可。
- **本方案自身**：以 **Apache-2.0** 发布（与两大直接来源一致），发布时建议同目录放置 `LICENSE` 文件。

> ⚠️ 发布前务必先读 `致谢与版权.md` 的「合规要求」一节，保留上游版权声明。

## 附：设计出处

本方案的核心结构取自 [gnfy/rime-wubipinyin](https://github.com/gnfy/rime-wubipinyin)
（基于 KyleBing/rime-wubi86-jidian 码表重构，Apache-2.0），其 `docs/design.md` 有完整的
「为什么不能无前缀混输」论证与 `tools/collision_check.py` 复现脚本。
