-----------------------------------------------------
--File Name    : UPHumanBagSlot.lua
--Author       : WuJizhou
--Create Time  : 9/11/2018, 7:51:33 PM
--Description  : UPHumanBagSlot
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHumanBagSlot = luaclass("UPHumanBagSlot", PrefabBase)

local UISetUtils = require("UISetUtils")
local BattleItemResDataTable = require("BattleItemResDataTable")
local BattleItemSystemClient = require("BattleItemSystemClient")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local UIDragDropUtils = require("UIDragDropUtils")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

local szBagSlotName = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_BAG")

UPHumanBagSlot.nSlotIndex = nil
UPHumanBagSlot.nInstanceId = 0
UPHumanBagSlot.bLazyEventBinded = false
UPHumanBagSlot.bEnabled = false
-- local function Unequip(self)
--     if not self.nInstanceId then
--         return
--     end
--     BattleItemSystemClient:RequestUnEquipItem(self.nInstanceId)
-- end


---------public---------

function UPHumanBagSlot:ShowBag(tbItem)
    local Hidden = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsDuration:SetVisibility(Hidden)
    pWidgetRef.pgbDurability:SetVisibility(Hidden)
    if tbItem == nil then
        pWidgetRef.btnBlueprintItem:SetVisibility(Hidden)
        pWidgetRef.imgColour:SetVisibility(Hidden)
        pWidgetRef.txtName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.imgLevel:SetVisibility(Hidden)
        self.pWidgetRef:SetVisibility(Hidden)
        return
    end
    self:RegisterEvent()
    pWidgetRef.txtName:SetVisibility(Hidden)
    self.nInstanceId = tbItem:GetInstanceId()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.DragId = self.nInstanceId
    self.pWidgetRef.DragCategory = PackageDragCategoryDef.HUMAN_BAG_SLOT
    pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    local tbTemplate = tbItem:GetTemplate()
    local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, pRes)

    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local nItemTemplateId = tbItem:GetTemplateId()
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())


    pWidgetRef.imgLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbTemplate.nGrade)
end

function UPHumanBagSlot:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
    self.pWidgetRef.txtName:SetText(szBagSlotName)
end



----------life cycle----------
-- function UPHumanBagSlot:OnCreate()
-- end

-- function UPHumanBagSlot:OnDestroy()
-- end

-- function UPHumanBagSlot:OnLoad()
-- end

-- function UPHumanBagSlot:OnUnload()
-- end

-- function UPHumanBagSlot:OnEnter()
-- end

-- function UPHumanBagSlot:OnShow()
-- end

-- function UPHumanBagSlot:OnHide()
-- end

-- function UPHumanBagSlot:OnExit()
-- end

local function OnCreateVisual(self, pVisualWidget)
    if self.nInstanceId > 0 then
        local tbItem = BattleItemSystemClient:GetItem(self.nInstanceId)
        if tbItem then
            local tbRes = BattleItemResDataTable:GetTemplate(tbItem.tbTemplate.nResId)
            if not tbRes then
                logerror("UPHumanBagSlot OnCreateVisual: invalid res id ", tbItem.tbTemplate.nResId)
                return
            end
            local szItemIconPath = tbRes.szIconPath
            local IconObj = szItemIconPath:load()
            if(IconObj == nil)then
                logwarning("UPHumanBagSlot OnCreateVisual: icon is not found,path="..tostring(szItemIconPath))
                return
            end
            local pWidgetRef = self.pWidgetRef
            UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
        end
    end
end

function UPHumanBagSlot:SetEnable(bEnabled)
    self.bEnabled = bEnabled
end

function UPHumanBagSlot:RegisterEvent()
    if not self.bLazyEventBinded and self.bEnabled and self.nInstanceId > 0 then
        local EventHelper = self.EventHelper
        local pWidgetRef = self.pWidgetRef
        local pbDrag = pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
        UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pbDrag)
        self.bLazyEventBinded = true
    end
end


function UPHumanBagSlot:OnBindEvent( EventHelper )

end

-- function UPHumanBagSlot:OnUnbindEvent( EventHelper )
-- end

return UPHumanBagSlot