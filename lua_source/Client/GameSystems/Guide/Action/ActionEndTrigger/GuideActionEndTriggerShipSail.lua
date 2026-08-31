-----------------------------------------------------
--File Name    : GuideActionEndTriggerShipSail.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerShipSail             = luaclass("GuideActionEndTriggerShipSail", GuideActionEndTriggerBase)

local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideActionEndTriggerShipSail:ShipSail()
    self:DebugLog("ShipSail")
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf:IsHuman() then
        self:DebugLog("ShipSail is human force end group")
        self:Triggered()
    else
        local nRequirePosture = self.tbParam[1]
        local nCurPosture = tbPlayerSelf.BattleShipMovementComponent:GetPosture()
        if nCurPosture ~= nRequirePosture then
            self:DebugLog("ShipSail requreposture="..nRequirePosture.." curposture="..nCurPosture)
            self:Triggered()
        end
    end    

end

function GuideActionEndTriggerShipSail:BindEvent(tbParam)
    GuideActionEndTriggerShipSail.super.BindEvent(self, tbParam)
    self:ShipSail()
end

return GuideActionEndTriggerShipSail
