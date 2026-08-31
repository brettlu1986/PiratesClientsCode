-----------------------------------------------------
--File Name    : GuideActionDelayClickAnywhere.lua
--Author       : Edward J
--Create Time  : 2019-09-03
--Description  : 延迟触发clickanywhere
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionDelayClickAnywhere = luaclass("GuideActionDelayClickAnywhere", GuideActionFunctional)
-----------------------------------------------------
local nDelayTime = 0
-----------------------------------------------------

function GuideActionDelayClickAnywhere:DoAction(tbTemplate)
    GuideActionDelayClickAnywhere.super.DoAction(self, tbTemplate)
    self:DebugLog(" GuideActionDelayClickAnywhere OnDelayTimerFunc")
    local tbParam = tbTemplate.tbParam
    if tbParam and tbParam[1] then
        nDelayTime = tonumber(tbParam[1])
    end
    self:CallDelayClickAnyWhere(nDelayTime)
end

return GuideActionDelayClickAnywhere
