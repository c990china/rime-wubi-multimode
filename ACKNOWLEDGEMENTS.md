# 致谢与版权（Acknowledgements & License）

本仓库 `rime-wubi-multimode` 是一套基于多个开源项目的 Rime 小狼毫
「极点五笔86 + z 引导拼音 + 反引号引导英文」增强方案。

## 许可证

本仓库整体以 **Apache-2.0** 许可证发布（与两大直接上游一致）。
全文见 `LICENSE`。

## 上游版权方与许可证

| 项目 | 仓库 | 许可证 | 在本方案中的角色 |
|---|---|---|---|
| gnfy | rime-wubipinyin | Apache-2.0 | z 引导拼音的结构 / 设计来源 |
| KyleBing | rime-wubi86-jidian | Apache-2.0 | 极点五笔86 码表基础 |
| rime（组织） | weasel | GPL-3.0 | 输入法前端（小狼毫） |
| rime（组织） | librime | BSD-3-Clause | 核心引擎 |
| rime（组织） | plum | LGPL-3.0 | 配方集合 |
| hchunhui | librime-lua | BSD-3-Clause | Lua 引擎（english.lua / cand_blocker.lua 运行其上） |
| rime（组织） | rime-wubi | LGPL-3.0 | 五笔方案参考 |
| rime（组织） | home | MIT | 官方文档 |

## 再分发要求

- 保留上述各上游的版权声明与许可证文件；
- 若修改了上游文件，须显著注明修改；
- 本方案自身的修改以 Apache-2.0 发布，可自由使用、修改、再分发。

## 免责声明

本方案按「现状」提供，不保证适用于所有环境。使用前请自行备份
`%AppData%\Rime\` 并在测试环境验证。
