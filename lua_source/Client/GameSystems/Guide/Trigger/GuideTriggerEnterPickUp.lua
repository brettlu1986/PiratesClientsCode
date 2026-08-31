-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTrigger              = require("GuideTrigger")
local GuideTriggerEnterPickUp   = luaclass("GuideTriggerEnterPickUp", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
local BattlePickTypeDef         = require("BattlePickTypeDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerEnterPickUp:OnEnterPickUpTrigger(nPickType, nInstanceId)
    self:DebugLog("OnEnterPickUpTrigger, nPickType = " .. nPickType)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    local szPickType = tbParam[1]
    local bResult = false
    if szPickType == "item" then
        bResult = nPickType == BattlePickTypeDef.ITEM
    elseif szPickType == "box" then
        local bIsDead = PlayerSelf:IsDead()
        self:DebugLog(" player is dead = " .. tostring(bIsDead))
        if bIsDead then
            self:DebugLog("OnEnterPickUpTrigger player is dead")
            return
        end
        bResult = nPickType == BattlePickTypeDef.BOX
    end
    self:DebugLog("OnEnterPickUpTrigger, bResult = " .. tostring(bResult))
    if bResult then
        self:Execute()
    else
        self:Break()
    end
end

--override
function GuideTriggerEnterPickUp:Execute()
    self:Trigger()
end

function GuideTriggerEnterPickUp:Begin()
    GuideTriggerEnterPickUp.super.Begin(self)
end

function GuideTriggerEnterPickUp:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_ENTER, self, self.OnEnterPickUpTrigger)
end

return GuideTriggerEnterPickUp
