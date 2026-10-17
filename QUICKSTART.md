# 安装说明（先读我）

本目录只有两个安装素材，其余全部在 git 包。

| 文件 | 是什么 | 怎么用 |
|---|---|---|
| `weasel-0.17.4.0-installer.exe` | **小狼毫（Weasel）输入法安装程序** | 双击，按向导装完；用户目录**保持默认** `%AppData%\Rime` |
| `rime-wubi86-jidian-master.zip` | **上游极点五笔86 配置包**（KyleBing）—— 含主码表与 `pinyin_simp`（z 引导拼音的依赖，**不能少**） | **必须解压**，取出里层文件放进 `%AppData%\Rime\` |

> **完整方案在本仓库根目录**：`<本仓库根目录>\`
> （指南 + `config\` 配置源 + 词库 + 屏蔽黑名单 + 算码器）

## 安装五步

1. **装输入法** —— 双击 `weasel-0.17.4.0-installer.exe`，按向导走完（用户目录保持默认 `%AppData%\Rime`）。
2. **铺上游文件** —— 解压 `rime-wubi86-jidian-master.zip`，⚠️ zip 内有顶层目录 `rime-wubi86-jidian-master\`，
   把**里面的文件取出来**放进 `%AppData%\Rime\`，别整个目录塞进去（否则 Rime 读不到）。
3. **覆盖方案文件** —— 用 git 包 `config\` 下的 `wubi86_jidian.schema.yaml`、`default.custom.yaml`、`weasel.custom.yaml`
   覆盖到 `%AppData%\Rime\` 同名文件。
4. **建软链接**（管理员）—— 右键运行 `<本仓库根目录>\dict\setup-symlinks.cmd` →「以管理员身份运行」。
   它会建两条链接（词库 + lua 屏蔽黑名单）并自动核对。
   ⚠️ **先建链接再部署**，否则输入法一个字都打不出来。
5. **重新部署** —— 右键任务栏右下角小狼毫托盘图标 →「重新部署」→ 等"部署成功"。

## 自检（部署后敲这些）

| 敲 | 预期 |
|---|---|
| `aaaa` | 候选第 1 位「工」 |
| `zdouyin` | 「抖音」，右侧标注 `ruuj` |
| `aaaa` 不按空格再敲 `b` | 「工」自动上屏 |
| `whsz` | 「演示科技深圳分公司」（演示词） |

## 下载地址（备用，若本目录文件丢失）

- Weasel 安装包：`https://github.com/rime/weasel/releases`
- 上游配置包：`https://github.com/KyleBing/rime-wubi86-jidian`

## 详细文档

完整步骤、排障、词库维护 → git 包根目录：
`README.md`（本仓库根目录）
