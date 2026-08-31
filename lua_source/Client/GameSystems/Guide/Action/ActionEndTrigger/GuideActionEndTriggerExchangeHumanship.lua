-----------------------------------------------------
--File Name    : GuideActionEndTriggerExchangeHumanship.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerExchangeHumanship    = luaclass("GuideActionEndTriggerExchangeHumanship", GuideActionEndTriggerBase)

local CommonEventDef        = require("CommonEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function CheckChangeToShip(self, tbGameObject)
    local nInsId = tbGameObject:GetServerInstanceId()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if nInsId == nCharacterInstanceId then  
        self:Triggered()
    end
end

function GuideActionEndTriggerExchangeHumanship:BindEvent(tbParam)
    GuideActionEndTriggerExchangeHumanship.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, CheckChangeToShip)
end

return GuideActionEndTriggerExchangeHumanship
