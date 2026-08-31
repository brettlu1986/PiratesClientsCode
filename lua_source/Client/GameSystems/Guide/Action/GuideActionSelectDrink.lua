-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectDrink        = luaclass("GuideActionSelectDrink", GuideActionSelectWidget)

local ConsumableItemDef             = require("ConsumableItemDef")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local BattleItemDataTable           = require("BattleItemDataTable")
local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
local ClientEventDef                = require("ClientEventDef")
-----------------------------------------------------
GuideActionSelectDrink.nSelectIndex = 0
GuideActionSelectDrink.nSubCategory = nil
-----------------------------------------------------
function GuideActionSelectDrink:GetSelectWidgets()
    self:DebugLog(" GuideActionSelectDrink:GetSelectWidgets")
    local Widget = nil
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError(" GuideActionSelectDrink:GetSelectWidgets Wnd is nil")
        return Widget
    end

    local ulItemPanel = Wnd.ulFFAItemPanel
    local tbItemInfoList = ulItemPanel.tbItemInfoList
    local nIndex = -1
    for i, v in ipairs(tbItemInfoList) do
        local tbTemplate = BattleItemDataTable:GetTemplate(v.nTemplateId)
        if tbTemplate then
            if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE 
                and (self.nSubCategory < 0 or tbTemplate.nSubCategory == self.nSubCategory) then
                self:DebugLog("WidgetName = " .. "pbShortcutMenuItem0".. i)
                --Widget = Wnd.pWidgetRef["pbShortcutMenuItem0"..i].btnItem
                nIndex = i
                break
            end
        end
    end
    if nIndex == -1 then
        self:LogError("GuideActionSelectDrink:GetSelectWidgets nIndex = -1")
        self:EndAction()
    end
    self.nSelectIndex = nIndex
    local pOwner = self.Owner
    local nStep = pOwner.tbTemplate.nStep
    if nIndex == 1 then
        Widget = Wnd.pWidgetRef["pbShortcutMenuItem0" .. nIndex].btnItem
        --skip next step
        self:DebugLog("GuideActionSelectDrink:GetSelectWidgets111")
        pOwner.Owner:SkipStep(nStep + 1)
        pOwner.Owner:SkipStep(nStep + 2)
    else
        if ulItemPanel.bListExpanded then
            self:DebugLog("GuideActionSelectDrink:GetSelectWidgets222")
            Widget = Wnd.pWidgetRef["pbShortcutMenuItem0" .. nIndex].btnItem
        else
            self:DebugLog("GuideActionSelectDrink:GetSelectWidgets333")
            Widget = Wnd.pWidgetRef["btnConsumableMiniArrow"]
        end
    end
    self:DebugLog("GuideActionSelectDrink Widget = " .. tostring(Widget) .. ", SelectIndex = ".. self.nSelectIndex)
    local tbTemp ={}
    table.insert(tbTemp, Widget)
    return tbTemp
end

function GuideActionSelectDrink:OnClickItem(nIndex)
    if nIndex ~= self.nSelectIndex then
        self:ForceEndCurrentGroup()
    end
end

--override
function GuideActionSelectDrink:Begin()
    GuideActionSelectDrink.super.Begin(self)
    self:DebugLog(" GuideActionSelectDrink:Begin")
    
    local tbParam = self.tbTemplate.tbParam
    local szSubCategory = tbParam and tbParam[1]
    self.nSubCategory = -1
    if szSubCategory ~= nil then
        if szSubCategory == "drink" then
            self.nSubCategory = ConsumableItemDef.ConsumableSubType.FOOD_AND_DRINK
        elseif szSubCategory == "medic" then
            self.nSubCategory = ConsumableItemDef.ConsumableSubType.MEDICINE
        end
    end
    
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ON_ITEM_PANLE_CLICKED, self, self.OnClickItem)
end

function GuideActionSelectDrink:DoAction(tbTemplate)
    self:DebugLog(" GuideActionSelectDrink:DoAction")
    GuideActionSelectDrink.super.DoAction(self, tbTemplate)
end

function GuideActionSelectDrink:OnTimerFunc()
    GuideActionSelectDrink.super.OnTimerFunc(self)
    self:ForceEndCurrentGroup()
end

return GuideActionSelectDrink
