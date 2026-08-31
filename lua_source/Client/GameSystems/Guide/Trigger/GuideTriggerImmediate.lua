-----------------------------------------------------
--File Name    : GuideTriggerImmediate.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerImmediate = luaclass("GuideTriggerImmediate",GuideTrigger)



--override
function GuideTriggerImmediate:Begin()
    GuideTriggerImmediate.super.Begin(self)
    self:Trigger()
end

return GuideTriggerImmediate

