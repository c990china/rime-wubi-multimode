-- 反引号引导英文：原样回显为唯一候选，空格上屏，打完自动回五笔
-- 挂载：wubi86_jidian.schema.yaml -> engine.translators -> lua_translator@*english
-- 前提：recognizer.patterns.english + affix_segmentor@english 已剥掉反引号，input 即纯英文串
-- 规范：入口必须是 M.func（librime-lua 只认 "func" 字段）；带 * 走 require，见指南 12.7 同款坑
local M = {}

function M.func(input, seg, env)
    -- 只处理英文段；缺此守卫会对所有段产出回显候选，污染候选框
    if not seg:has_tag("english") then
        return
    end
    if input == nil or input == "" then
        return
    end
    -- 原样回显：唯一候选，文本 = 输入串；空格即确认上屏
    yield(Candidate("english", seg.start, seg._end, input, ""))
end

return M
