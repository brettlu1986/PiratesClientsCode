-----------------------------------------------------
--File Name    : UPHumanArmorSlot.lua
--Author       : WuJizhou
--Create Time  : 9/11/2018, 7:51:33 PM
--Description  : UPHumanArmorSlot
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHumanArmorSlot = luaclass("UPHumanArmorSlot", PrefabBase)

local HumanArmorDef = require("HumanArmorDef")
local UISetUtils = require("UISetUtils")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local BattleItemSystemClient = require("BattleItemSystemClient")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local UIDragDropUtils = require("UIDragDropUtils")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local tbArmorSlotNames = {}
if GlobalVariableSystem.bUseNewBattleItem then
    tbArmorSlotNames[HumanArmorDef.ArmorCategory.All] = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_ARMOR_ALL")
else
    tbArmorSlotNames[HumanArmorDef.ArmorCategory.Head] = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_ARMOR_HEAD")
    tbArmorSlotNames[HumanArmorDef.ArmorCategory.Body] = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_ARMOR_BODY")
end

UPHumanArmorSlot.nSlotIndex = nil
UPHumanArmorSlot.nArmorInstanceId = 0
UPHumanArmorSlot.bLazyEventBinded = false
UPHumanArmorSlot.bEnabled = false

-- local function Unequip(self)
--     if not self.nArmorInstanceId then
--         return
--     end
--     BattleItemSystemClient:RequestUnEquipItem(self.nArmorInstanceId)
-- end


---------public---------

function UPHumanArmorSlot:ShowArmor(tbArmor)
    local Visibility = ESlateVisibility_SelfHitTestInvisible
    local Hidden = ESlateVisibility_Collapsed
    local pWidgetRef = self.pWidgetRef
    if tbArmor == nil then
        pWidgetRef.cvsDuration:SetVisibility(Hidden)
        pWidgetRef.pgbDurability:SetVisibility(Hidden)
        pWidgetRef.btnBlueprintItem:SetVisibility(Hidden)
        pWidgetRef.imgColour:SetVisibility(Hidden)
        pWidgetRef.txtName:SetVisibility(Visibility)
        pWidgetRef.imgLevel:SetVisibility(Hidden)
        self.pWidgetRef:SetVisibility(Visibility)
        self.pWidgetRef.bEnableDrag = false
        return
    end
    self.nArmorInstanceId = tbArmor:GetInstanceId()
    self:RegisterEvent()
    self.pWidgetRef.bEnableDrag = true
    self.pWidgetRef:SetVisibility(ESlateVisibility_Visible)
    self.pWidgetRef.DragId = self.nArmorInstanceId
    self.pWidgetRef.DragCategory = PackageDragCategoryDef.HUMAN_ARMOR

    pWidgetRef.cvsDuration:SetVisibility(Visibility)
    pWidgetRef.pgbDurability:SetVisibility(Visibility)
    pWidgetRef.btnBlueprintItem:SetVisibility(Visibility)
    pWidgetRef.imgColour:SetVisibility(Visibility)
    local tbTemplate = tbArmor:GetTemplate()
    local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, pRes)

    pWidgetRef.txtName:SetVisibility(Visibility)
    self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)

    local nItemTemplateId = tbArmor:GetTemplateId()
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    local nTotalDurability = tbTemplate.nDurability
    local nCurrentDurability = tbArmor:GetDurability()

    local nPercent = nCurrentDurability / nTotalDurability
    pWidgetRef.pgbDurability:SetPercent(1 - nPercent)
    pWidgetRef.txtDuration:SetText(tbArmor:GetDurabilityPercentageString())
    pWidgetRef.imgLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbTemplate.nGrade)
end

function UPHumanArmorSlot:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
    local nCategory = HumanArmorSlotDef.ArmorSlots[nIdx]
    local szText = tbArmorSlotNames[nCategory]
    self.pWidgetRef.txtName:SetText(szText)
end



----------life cycle----------
-- function UPHumanArmorSlot:OnCreate()
-- end

-- function UPHumanArmorSlot:OnDestroy()
-- end

-- function UPHumanArmorSlot:OnLoad()
-- end

-- function UPHumanArmorSlot:OnUnload()
-- end

-- function UPHumanArmorSlot:OnEnter()
-- end

-- function UPHumanArmorSlot:OnShow()
-- end

-- function UPHumanArmorSlot:OnHide()
-- end

function UPHumanArmorSlot:OnExit()
    self.bLazyEventBinded = false
end

local function OnCreateVisual(self, pVisualWidget)
    if self.nArmorInstanceId > 0 then
        local tbItem = BattleItemSystemClient:GetItem(self.nArmorInstanceId)
        if tbItem then
            local tbRes = BattleItemResDataTable:GetTemplate(tbItem.tbTemplate.nResId)
            if not tbRes then
                logerror("UPHumanArmorSlot OnCreateVisual: invalid res id ", tbItem.tbTemplate.nResId)
                return
            end
            local szItemIconPath = tbRes.szIconPath
            local IconObj = szItemIconPath:load()
            if(IconObj == nil)then
                logwarning("UPHumanArmorSlot OnCreateVisual: icon is not found,path="..tostring(szItemIconPath))
                return
            end
            local pWidgetRef = self.pWidgetRef
            UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
        end
    end
end

function UPHumanArmorSlot:SetEnable(bEnabled)
    self.bEnabled = bEnabled
    if not bEnabled then
        self.bLazyEventBinded = false
        self.EventHelper:UnregisterAll()
    end
end

function UPHumanArmorSlot:RegisterEvent()
    if not self.bLazyEventBinded and self.bEnabled and self.nArmorInstanceId > 0 then
        local EventHelper = self.EventHelper
        local pWidgetRef = self.pWidgetRef
        local pbDrag = pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
        UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pbDrag)
        self.bLazyEventBinded = true
    end
end

function UPHumanArmorSlot:OnBindEvent( EventHelper )
--    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBlueprintItem.OnClicked, self, Unequip)

end

-- function UPHumanArmorSlot:OnUnbindEvent( EventHelper )
-- end

return UPHumanArmorSlot