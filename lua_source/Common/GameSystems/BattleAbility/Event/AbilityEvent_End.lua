-----------------------------------------------------
--File Name    : AbilityEvent_End.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-22
--Description  : 在事件Deactivate时执行TriggerDo
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_End = luaclass("AbilityEvent_End", AbilityEventBaseClass)

function AbilityEvent_End:OnDeactivate()
    self:TriggerDo()
end

return AbilityEvent_End
