-- 候选词屏蔽过滤器（lua_filter）
--
-- 作用：把不想看到的候选词从候选框里隐藏掉，不修改任何词库文件。
--
-- 用法：想屏蔽哪个词，就把它加进下面的 blocked_list 里（每行一个，用引号包起来，逗号分隔），
--       然后重新部署即可生效。加完记得删掉行尾多余逗号。
--
-- 挂载（两处都不能错，已由 2026-10-07 双代理核实）：
--   1. schema 的 engine/filters 里写：  - lua_filter@*cand_blocker
--      ★ 必须带 * 号。不带 * 时 librime-lua 走 lua_getglobal 找同名全局变量，
--        而本机没有 rime.lua，全局不存在 → 取不到模块。带 * 才走 require("cand_blocker")。
--   2. 本文件必须位于 Rime 用户目录的 lua/ 子目录下。
--
-- ★★ 入口函数名必须是 M.func，不能写成 M.filter ★★
--   librime-lua 源码 src/lua_gears.cc 的 raw_init() 只查 "func" 字段，
--   写错会报 `func type: nil ... func type error expect function`，
--   该过滤器取到 nil，输出为空 → 候选流为空 → 输入法一个字都打不出来。
--   （旧版 librime-lua 无空函数保护，直接表现为无法输入；新版只静默禁用该过滤器。）
--
-- 参考：hchunhui/librime-lua  src/lua_gears.cc ；iDvel/rime-ice  lua/long_word_filter.lua

local M = {}

-- ============ 黑名单：想屏蔽的词写在这里 ============
local blocked_list = {
  "程朱",
  "濔",
  "血仇",
  -- "下一个要屏蔽的词",
  -- "再下一个",
}
-- ===================================================

local blocked = {}
for _, w in ipairs(blocked_list) do
  blocked[w] = true
end

-- 入口函数：名字必须是 func（librime-lua 约定）
function M.func(input, env)
  for cand in input:iter() do
    if not blocked[cand.text] then
      yield(cand)
    end
  end
end

-- 兼容别名：部分旧版 librime-lua 用 filter 作为入口名
M.filter = M.func

return M
