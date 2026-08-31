-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-15
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerPartnerBagEmpty   = luaclass("GuideTriggerPartnerBagEmpty",GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
-----------------------------------------------------
--override
function GuideTriggerPartnerBagEmpty:CheckPartnerBagIsEmpty()
    local PartnerComponent = GamePlayerSelfHelper:Get().PartnerComponent
    local bOwned = true
    local tbPartnerData = PartnerComponent:GetPartnerList(bOwned)
    local bEmpty = #tbPartnerData <= 0
    self:DebugLog("tbPartnerData =" .. #tbPartnerData)
    if not self.tbTemplate.bIsEnable then
        bEmpty = not bEmpty
    end
    return bEmpty
end

function GuideTriggerPartnerBagEmpty:Begin()
    GuideTriggerPartnerBagEmpty.super.Begin(self)
    local bResult = self:CheckPartnerBagIsEmpty()
    self:DebugLog("CheckPartnerBagIsEmpty() = " .. tostring(bResult) .. type(bResult))
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerPartnerBagEmpty