-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-17
--Description  : 指引触发
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTriggerPlayerHP      = require("GuideTriggerPlayerHP")
local GuideTriggerCheckConsume   = luaclass("GuideTriggerCheckConsume",GuideTriggerPlayerHP)

local BattleItemDataTable       = require("BattleItemDataTable")
local ConsumableItemDef         = require("ConsumableItemDef")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local UIManager                 = require("UIManager")
local UIDef                     = require("UIDef")
-----------------------------------------------------
GuideTriggerCheckConsume.szType = ""
-----------------------------------------------------

function GuideTriggerCheckConsume:CheckConsum()
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError("CheckConsum Wnd is nil")
        return false
    end
    local nSubCategory = ConsumableItemDef.ConsumableSubType.FOOD_AND_DRINK
    if self.szType == "drink" then
        nSubCategory = ConsumableItemDef.ConsumableSubType.FOOD_AND_DRINK
    elseif self.szType == "medic" then
        nSubCategory = ConsumableItemDef.ConsumableSubType.MEDICINE
    end
    local ulItemPanel = Wnd.ulFFAItemPanel
    local tbItemInfoList = ulItemPanel.tbItemInfoList
    for i, v in ipairs(tbItemInfoList) do
        local tbTemplate = BattleItemDataTable:GetTemplate(v.nTemplateId)
        if tbTemplate then
            if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE and tbTemplate.nSubCategory == nSubCategory then
                self:DebugLog("CheckConsum have ".. self.szType)
                return true
            end
        end
    end
    self:DebugLog("CheckConsum don't have ".. self.szType)
    return false
end

--override
function GuideTriggerCheckConsume:Execute()
    if self:CheckConsum() then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerCheckConsume:Begin()
    GuideTriggerCheckConsume.super.Begin(self)
    self.szType = self.tbTemplate.tbParam[3]
end

return GuideTriggerCheckConsume