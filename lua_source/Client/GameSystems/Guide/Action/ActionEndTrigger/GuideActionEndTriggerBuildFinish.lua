-----------------------------------------------------
--File Name    : GuideActionEndTriggerBuildFinish.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerBuildFinish      = luaclass("GuideActionEndTriggerBuildFinish", GuideActionEndTriggerBase)

local ClientEventDef            = require("ClientEventDef")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local BattleItemDataTable       = require("BattleItemDataTable")
local GameObjectTypeDef         = require("GameObjectTypeDef")
-----------------------------------------------------

local function OnBuildFinish(self, tbPlayer, nItemInstanceId, nItemTemplateId)
    if tbPlayer and tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbItemTemplate == nil then
            self:LogError("error! tbItemTemplate is nil")
        end
        local szPickUpType = self.tbParam[1]
        if szPickUpType == "weapon" and tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON then
            self:Triggered()
        end

        if szPickUpType == "humanweapon" and tbItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
            self:Triggered()
        end

        if szPickUpType == "ship" and tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP then
            self:Triggered()
        end
    end
end

function GuideActionEndTriggerBuildFinish:BindEvent(tbParam)
    GuideActionEndTriggerBuildFinish.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_BUILD_FINISH_CLIENT, self, OnBuildFinish)
end

return GuideActionEndTriggerBuildFinish
