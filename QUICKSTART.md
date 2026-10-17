# 快速安装（5 步）

本仓库是一套 Rime 小狼毫「极点五笔86 + z 引导拼音 + 反引号引导英文」方案。安装需要两类素材：

- **安装包 + 上游配置包（zip）**：自行准备（下载地址见下）；
- **本仓库**：方案文件、词库、屏蔽脚本、算码器。

| 素材 | 是什么 |
|---|---|
| Weasel 安装包 | 小狼毫输入法（用户目录保持默认 `%AppData%\Rime`） |
| rime-wubi86-jidian-master.zip | 上游极点五笔86 配置包（含 `pinyin_simp`，z 引导拼音依赖，不能少） |

## 安装五步

1. **装输入法** —— 安装 Weasel，按向导走完（用户目录保持默认 `%AppData%\Rime`）。
2. **铺上游文件** —— 解压 `rime-wubi86-jidian-master.zip`，把里面文件取出放进 `%AppData%\Rime\`（注意 zip 内有顶层目录，别整目录塞入）。
3. **覆盖方案文件** —— 用本仓库 `config\` 下的 `wubi86_jidian.schema.yaml`、`default.custom.yaml`、`weasel.custom.yaml` 覆盖同名文件。
4. **建软链接（管理员）** —— 右键运行 `dict\setup-symlinks.cmd` →「以管理员身份运行」。会建三条链接（词库 + 候选屏蔽 + 英文回显）并自动核对。⚠️ 先建链接再部署，否则输入法打不出字。
5. **重新部署** —— 右键任务栏右下角小狼毫托盘图标 →「重新部署」→ 等"部署成功"。

## 自检

| 敲 | 预期 |
|---|---|
| `aaaa` | 候选第 1 位「工」 |
| `zdouyin` | 「抖音」，右侧标注 `ruuj` |
| `aaaa` 不按空格再敲 `b` | 「工」自动上屏 |
| `` `hello `` + 空格 | 上屏 `hello`，随后自动回五笔 |

## 下载地址（备用）

- Weasel：`https://github.com/rime/weasel/releases`
- 上游配置包：`https://github.com/KyleBing/rime-wubi86-jidian`

## 详细文档

完整步骤、配置详解、词库维护、排障 → `README.md`。
