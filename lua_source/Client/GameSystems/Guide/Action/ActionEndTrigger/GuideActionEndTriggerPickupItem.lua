-----------------------------------------------------
--File Name    : GuideActionEndTriggerPickupItem.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerPickupItem       = luaclass("GuideActionEndTriggerPickupItem", GuideActionEndTriggerBase)

local ClientEventDef            = require("ClientEventDef")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local BattleItemDataTable       = require("BattleItemDataTable")
-----------------------------------------------------

local function OnPickupFinish(self, nInstanceId, nItemTemplateId, bSuccess)
    if not bSuccess then
        return
    end
    self:DebugLog("OnPickupFinish, nInstanceId = " .. tostring(nInstanceId) .. " nItemTemplateId = " .. tostring(nItemTemplateId))
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        self:LogError("error! tbItemTemplate is nil")
    end
    local tbParam = self.tbParam
    local szPickUpType = tbParam[1]
    self:DebugLog("nItemTemplateId = " .. tostring(nItemTemplateId) .. " Category = " .. tostring(tbItemTemplate.nCategory))
    if szPickUpType == "material" and (tbItemTemplate.nCategory == BattleItemCategoryDef.MATERIAL or tbItemTemplate.nCategory == BattleItemCategoryDef.CONVERTIBLE_ITEM) then
        local szTemplateId = tbParam[2]
        if tonumber(szTemplateId) == nItemTemplateId then
            self:Triggered()
            return
        end
    end
    if szPickUpType == "buildkey" and tbItemTemplate.nCategory == BattleItemCategoryDef.BUILD_KEY_ITEM then
        self:Triggered()
        return
    end
    if szPickUpType == "humanweapon" and tbItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        self:Triggered()
        return
    end
end

function GuideActionEndTriggerPickupItem:BindEvent(tbParam)
    GuideActionEndTriggerPickupItem.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PICK_UP_FINISH, self, OnPickupFinish)
end

return GuideActionEndTriggerPickupItem
