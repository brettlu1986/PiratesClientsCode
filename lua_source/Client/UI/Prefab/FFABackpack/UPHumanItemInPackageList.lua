-----------------------------------------------------
--File Name    : UPHumanItemInPackageList.lua
--Author       : WuJizhou
--Create Time  : 9/5/2018, 1:10:34 PM
--Description  : UPHumanItemInPackageList
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPHumanItemInPackageList = luaclass("UPHumanItemInPackageList", ListItemBase)
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local HumanWeaponAttachmentSlotDef = require("HumanWeaponAttachmentSlotDef")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local UIDragDropUtils = require("UIDragDropUtils")
local ClientEventDef = require("ClientEventDef")
local UITextDef = require("UITextDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPHumanItemInPackageList.tbItem = nil

local function CheckWeaponAttachmentUsable(tbAttachment)
    local bResult = false
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local tbEquips = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId)
    local nSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbAttachment:GetAttachmentCategory())
    local nAttachmentId = tbAttachment:GetTemplateId()
    for k, v in pairs(tbEquips) do
        local tbEquipTemplate = v:GetTemplate()
        local tbMatchedAttachmentIds = tbEquipTemplate.tbAttachmentSlots[nSlotIndex]
        for _, nId in ipairs(tbMatchedAttachmentIds) do
            if nId == nAttachmentId then
                bResult = true
                break
            end
        end
        if bResult then
            break
        end
    end
    return bResult
end

local function RequestEquipAttachment(tbAttachment)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local tbEquips = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId)

    local nSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbAttachment:GetAttachmentCategory())
    local nAttachmentId = tbAttachment:GetTemplateId()
    local tbCandidateEquipSlots = {}
    for k, v in pairs(tbEquips) do
        local tbEquipTemplate = v:GetTemplate()
        local tbMatchedAttachmentIds = tbEquipTemplate.tbAttachmentSlots[nSlotIndex]
        for _, nId in ipairs(tbMatchedAttachmentIds) do
            if nId == nAttachmentId then
                table.insert(tbCandidateEquipSlots, k)
                break
            end
        end
    end
    if #tbCandidateEquipSlots <= 0 then  -- 没有匹配的
        return false
    end
    table.sort(tbCandidateEquipSlots)
    local tbCandidatesForEmpty = {}
    local nCurrentWeaponId = nil

    for _, nSlot in ipairs(tbCandidateEquipSlots) do
        local tbWeapon = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlot)
        local nId = tbWeapon:GetInstanceId()
        local tbAttach = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nId, nSlotIndex)
        if tbWeapon:IsCurrentWeapon() then
            if tbAttach == nil then
                BattleItemSystemClient:TryToRequestEquipItem(nId, nSlotIndex, tbAttachment)
                return true
            end
            nCurrentWeaponId = nId
        else
            if tbAttach == nil then
                table.insert(tbCandidatesForEmpty, nId)
            end
        end
    end
    if #tbCandidatesForEmpty > 0 then
        BattleItemSystemClient:TryToRequestEquipItem(tbCandidatesForEmpty[1], nSlotIndex, tbAttachment)
        return true
    elseif nCurrentWeaponId~= nil then
        BattleItemSystemClient:TryToRequestEquipItem(nCurrentWeaponId, nSlotIndex, tbAttachment)
        return true
    else
        local tbWeapon = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, tbCandidateEquipSlots[1])
        local nId = tbWeapon:GetInstanceId()
        BattleItemSystemClient:TryToRequestEquipItem(nId, nSlotIndex, tbAttachment)
        return true
    end
end

local function Equip(self)
    local tbItem = self.tbItem
    if tbItem:GetCategory() ~= BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        return
    end

    local bRequest = RequestEquipAttachment(tbItem)
    if not bRequest then
        logerror("not match")
    end
end

local function DiscardSome(self)
    self.pbDiscardPart:ShowView(self.tbItem)
end

local function DiscardAll(self)
    local tbItem = self.tbItem
    if not tbItem then
        return
    end
    BattleItemSystemClient:RequestThrowAwayItem(tbItem:GetInstanceId(), tbItem.nStackCount)
    self.EventHelper:FireEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM)
end

local function Use(self)
    local tbItem = self.tbItem
    if tbItem then
        if tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_CONSUMABLE then
            BattleItemSystemClient:RequestConsumeItem(self.tbItem:GetInstanceId())
        end
    end
end

local function OnSelected(self)
    self:ToogleSelectItem()
    if self:IsSelected() then
        local tbItem = self.tbItem
        local tbTemplate = tbItem:GetTemplate()
        local nCount = tbItem:GetStackCount()
        self.pbDetail:ShowDetail(tbTemplate, nCount)
    else
        self.pbDetail:HideDetail()
    end
end


local function OnCreateVisual(self, pVisualWidget)
    local tbItem = self.tbItem
    if tbItem then
        local nResId = tbItem:GetTemplate().nResId
        local tbRes = BattleItemResDataTable:GetTemplate(nResId)
        if not tbRes then
            logerror("UPHumanItemInPackageList OnCreateVisual: invalid res id ", nResId)
            return
        end
        local szItemIconPath = tbRes.szIconPath
        local IconObj = szItemIconPath:load()
        if(IconObj == nil)then
            logwarning("UPHumanItemInPackageList OnCreateVisual: icon is not found, path="..tostring(szItemIconPath))
            return
        end
        local pWidgetRef = self.pWidgetRef
        UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
    end
end

function UPHumanItemInPackageList:OnLoad()
    self.pWidgetRef.btnSelect:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end


function UPHumanItemInPackageList:SetSelected(bSelected)
    local Visible = ESlateVisibility_Visible
    local Collapsed = ESlateVisibility_Collapsed
    local pWidgetRef = self.pWidgetRef
    if bSelected then
        pWidgetRef.vboxOperate:SetVisibility(Visible)
        pWidgetRef.csvOperate1:SetVisibility(Visible)
    else
        pWidgetRef.vboxOperate:SetVisibility(Collapsed)
        pWidgetRef.csvOperate1:SetVisibility(Collapsed)
    end
    if self.tbItem then
        self.EventHelper:FireEvent(ClientEventDef.EV_BACKPACK_LISTITEM_SELECTED, self.tbItem:GetInstanceId(), bSelected)
    end
end

function UPHumanItemInPackageList:OnRefresh(tbData)
    if not tbData then
        logerror("tbData is nil!", debug.traceback())
        return
    end
    self.tbItem = tbData.tbItem
    self.pbDiscardPart = tbData.pbDiscardPart
    self.pbDetail = tbData.pbDetail

    local tbItem = self.tbItem
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.Visible
    local Collapsed = ESlateVisibility.Collapsed

    -- 设置拖拽
    local pbDrag = pWidgetRef
    pbDrag:SetVisibility(ESlateVisibility.Visible)
    pbDrag.bEnableDrag = true
    pbDrag.bEnableDrop = false
    pbDrag.DragId = tbItem:GetInstanceId()
    pbDrag.DragCategory = PackageDragCategoryDef.HUMAN_PACKAGE_ITEM
    -- 显示图标
    local tbTemplate = tbItem:GetTemplate()
    local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, pRes)

    -- 显示颜色等级
    local nItemTemplateId = tbItem:GetTemplateId()
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    -- 显示名字
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    -- pWidgetRef.txtDesc:SetText(tbTemplate.l10nDesc)
    pWidgetRef.txtDesc:SetVisibility(ESlateVisibility.Hidden)

    --根据item类型决定按钮显示
    local nCategory = tbTemplate.nCategory
    if nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE then
        pWidgetRef.btnUse:SetVisibility(Visible)
    else
        pWidgetRef.btnUse:SetVisibility(Collapsed)
    end

    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        pWidgetRef.btnDiscard1:SetVisibility(Collapsed)
        pWidgetRef.btnDiscardAll:SetVisibility(Visible)
        pWidgetRef.btnEquipment:SetVisibility(Visible)
        if CheckWeaponAttachmentUsable(self.tbItem) then
            pWidgetRef.imgForbid:SetVisibility(Collapsed)
            pWidgetRef.btnEquipment:SetIsEnabled(true)
            pWidgetRef.txtEquipment:SetText(UITextDef.UI_BACKPACK_EQUIPMENT_ENABLE)
        else
            pWidgetRef.imgForbid:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.btnEquipment:SetIsEnabled(false)
            pWidgetRef.txtEquipment:SetText(UITextDef.UI_BACKPACK_EQUIPMENT_DISABLE)
        end
    else
        pWidgetRef.btnDiscard1:SetVisibility(Visible)
        pWidgetRef.btnDiscardAll:SetVisibility(Visible)
        pWidgetRef.btnEquipment:SetVisibility(Collapsed)
        pWidgetRef.imgForbid:SetVisibility(Collapsed)
    end

    local nCount = tbItem:GetStackCount()
    if nCount > 1 then
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.btnDiscard1:SetVisibility(Visible)
        pWidgetRef.txtCount:SetText(nCount)
    else
        pWidgetRef.txtCount:SetVisibility(Collapsed)
        pWidgetRef.btnDiscard1:SetVisibility(Collapsed)
    end

    local bSelected = self:IsSelected()
    self:SetSelected(bSelected)
    self.pbDiscardPart:HideView()
end

----------life cycle----------
-- function UPHumanItemInPackageList:OnCreate()
-- end

-- function UPHumanItemInPackageList:OnDestroy()
-- end

-- function UPHumanItemInPackageList:OnLoad()
-- end

-- function UPHumanItemInPackageList:OnUnload()
-- end

-- function UPHumanItemInPackageList:OnEnter()
-- end

-- function UPHumanItemInPackageList:OnShow()
-- end

-- function UPHumanItemInPackageList:OnHide()
-- end

-- function UPHumanItemInPackageList:OnExit()
-- end

function UPHumanItemInPackageList:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterCppDelegate(pWidgetRef.btnUse.OnClicked, self, Use)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiscard1.OnClicked, self, DiscardSome)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiscardAll.OnClicked, self, DiscardAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnEquipment.OnClicked, self, Equip)

    local pbDrag = pWidgetRef
    EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
    EventHelper:RegisterCppDelegate(pbDrag.OnClicked, self, OnSelected)
    UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pbDrag)
end

-- function UPHumanItemInPackageList:OnUnbindEvent( EventHelper )
-- end

return UPHumanItemInPackageList