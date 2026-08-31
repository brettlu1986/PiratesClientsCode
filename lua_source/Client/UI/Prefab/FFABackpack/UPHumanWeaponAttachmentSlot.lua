-----------------------------------------------------
--File Name    : UPHumanWeaponAttachmentSlot.lua
--Author       : WuJizhou
--Create Time  : 9/4/2018, 4:42:22 PM
--Description  : UPHumanWeaponAttachmentSlot
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UISetUtils = require("UISetUtils")
local BattleItemResDataTable = require("BattleItemResDataTable")

local UPHumanWeaponAttachmentSlot = luaclass("UPHumanWeaponAttachmentSlot", PrefabBase)
local BattleItemSystemClient = require("BattleItemSystemClient")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanWeaponAttachmentSlotDef = require("HumanWeaponAttachmentSlotDef")
local UIDragDropUtils = require("UIDragDropUtils")
local ClientEventDef = require("ClientEventDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

local tbAttachmentName = {
    UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_WEAPON_ATTACHMENT_MUZZLE"),
    UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_WEAPON_ATTACHMENT_HANDGUARD"),
    UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_WEAPON_ATTACHMENT_SIGHT"),
    UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_WEAPON_ATTACHMENT_STOCK"),
    UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_WEAPON_ATTACHMENT_MAGAZINE")
}

UPHumanWeaponAttachmentSlot.nSlotIndex = -1
UPHumanWeaponAttachmentSlot.nOwnerWeaponSlotIndex = -1
UPHumanWeaponAttachmentSlot.tbWeaponAttachment = nil
UPHumanWeaponAttachmentSlot.bEnabled = false
UPHumanWeaponAttachmentSlot.bDragEventBinded = false
UPHumanWeaponAttachmentSlot.bDropEventBinded = false

local function OnClicked(self)
    if not self.tbWeaponAttachment then
        return
    end
    BattleItemSystemClient:RequestUnEquipItem(self.tbWeaponAttachment:GetInstanceId())
end

local function OnCreateVisual(self, pVisualWidget)
    local tbItem = self.tbWeaponAttachment
    if tbItem then
        local nResId = tbItem:GetTemplate().nResId
        local tbRes = BattleItemResDataTable:GetTemplate(nResId)
        if not tbRes then
            logerror("UPHumanWeaponAttachmentSlot OnCreateVisual: invalid res id ", nResId)
            return
        end
        local szItemIconPath = tbRes.szIconPath
        local IconObj = szItemIconPath:load()
        if(IconObj == nil)then
            logwarning("UPHumanWeaponAttachmentSlot OnCreateVisual: icon is not found, path="..tostring(szItemIconPath))
            return
        end
        local pWidgetRef = self.pWidgetRef
        UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
    end
end

local function IsItemMatchSlot(self, nItemInstanceId)
    local tbItem = BattleItemSystemClient:GetItem(nItemInstanceId)
    if not tbItem then
        return false
    end
    local tbTemlate = tbItem.tbTemplate
    if tbTemlate.nCategory ~= BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        return false
    end
    local nWeaponSlotIdx = self.nOwnerWeaponSlotIndex

    if nWeaponSlotIdx <= 0 then
        return false
    end
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()

    local tbEquip = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nWeaponSlotIdx)
    if not tbEquip then
        return false
    end
    local bMatched = BattleItemSystemClient:CheckItemSlotCompatibility(tbEquip:GetInstanceId(), self.nSlotIndex, tbItem)
    return bMatched
end

local function OnAcceptAttachmentItemDropped(self, tbItem, nDragSourceCategory)
    local nHoveredAttachmentInstanceId = tbItem:GetInstanceId()
    local bMatched = IsItemMatchSlot(self, nHoveredAttachmentInstanceId) -- 移动的目的地是否匹配
    if not bMatched then
        return
    end

    local tbPlayer = GamePlayerSelfHelper:Get()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local nAttachmentSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbItem:GetAttachmentCategory())
    local nMoveToWeaponSlotIdx = self.nOwnerWeaponSlotIndex
    local tbMoveToEquip = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nMoveToWeaponSlotIdx)
    local nMoveToEquipInstanceId = tbMoveToEquip:GetInstanceId()
    if nDragSourceCategory == PackageDragCategoryDef.HUMAN_PACKAGE_ITEM then -- 从背包拖出
        BattleItemSystemClient:TryToRequestEquipItem(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
        return
    end

    if nDragSourceCategory ~= PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        return
    end

    --从别的武器上拖出
    --移动的目的地上的配件
    local tbMoveToAttachment = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nMoveToEquipInstanceId, nAttachmentSlotIndex)
    if not tbMoveToAttachment then
        BattleItemSystemClient:TryToRequestEquipItem(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
        return
    end

    local nMoveToAttachmentInstanceId = tbMoveToAttachment:GetInstanceId()
    if nMoveToAttachmentInstanceId == nHoveredAttachmentInstanceId then
        return
    end
    -- 检验目的地的配件是否可以装备到来源地
    local nMoveFromEquipInstanceId = tbItem:GetStorageLocation().nOwnerInstanceId
    local bAvailable = BattleItemSystemClient:CheckItemSlotCompatibility(nMoveFromEquipInstanceId, self.nSlotIndex, tbMoveToAttachment)
    if bAvailable then
        BattleItemSystemClient:RequestExchangeStorageLocation(nHoveredAttachmentInstanceId, nMoveToAttachmentInstanceId)
    else
        BattleItemSystemClient:TryToRequestEquipItem(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
    end
end

local function OnAcceptDrop(self, nDragSourceCategory, nDragSourceId)

    local tbItem = BattleItemSystemClient:GetItem(nDragSourceId)
    local nCategory = tbItem:GetCategory()
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        OnAcceptAttachmentItemDropped(self, tbItem, nDragSourceCategory)
    end
end

local function OnDragStart(self, nDragSourceCategory, nDragSourceId)
    if nDragSourceCategory == PackageDragCategoryDef.HUMAN_PACKAGE_ITEM or
        nDragSourceCategory == PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        local bMatched = IsItemMatchSlot(self, nDragSourceId)
        if bMatched then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function OnDragEnd(self, nDragSourceCategory, nDragSourceId)
    self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnListItemSelected(self, nItemInstanceId, bSelected)
    if bSelected then
        local bMatched = IsItemMatchSlot(self, nItemInstanceId)
        if bMatched then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
        end
    else
        self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
    end
end

----------public function------
function UPHumanWeaponAttachmentSlot:SetSlotIndex(nSlotIndex)
    self.nSlotIndex = nSlotIndex
end

function UPHumanWeaponAttachmentSlot:SetOwnerWeaponSlotIndex(nOwnerWeaponSlotIndex)
    self.nOwnerWeaponSlotIndex = nOwnerWeaponSlotIndex
end

function UPHumanWeaponAttachmentSlot:ShowAttachment(tbWeaponAttachment, szSlotName)
    local pWidgetRef = self.pWidgetRef
    self.tbWeaponAttachment = tbWeaponAttachment

    -- local tbTemplate = tbHumanWeaponItem:GetTemplate()
    -- local szSlotName = tbTemplate.tbAttachmentSlotNames[self.nSlotIndex]
    if szSlotName == nil then
        szSlotName = tbAttachmentName[self.nSlotIndex]
    end
    pWidgetRef.txtName:SetText(szSlotName)

    local pbDrag = pWidgetRef
    pbDrag:SetVisibility(ESlateVisibility.Visible)
    if tbWeaponAttachment ~= nil then
        self:RegisterDragEvent()
        pbDrag.bEnableDrag = true
        pbDrag.bEnableDrop = true
        pbDrag.DragId = tbWeaponAttachment:GetInstanceId()
        pbDrag.DragCategory = PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT
        --设置图标
        pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        local tbTemplate = tbWeaponAttachment:GetTemplate()
        local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
        local szRes = tbResTemplate.szIconPath
        local pRes = szRes:load()
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, pRes)
        pWidgetRef.txtName:SetVisibility(ESlateVisibility.Hidden)

        pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local nItemTemplateId = tbWeaponAttachment:GetTemplateId()
        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
    else
        pbDrag.bEnableDrag = false
        pbDrag.bEnableDrop = true
        pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end


function UPHumanWeaponAttachmentSlot:SetVisibility(Visibility)
    self.pWidgetRef:SetVisibility(Visibility)
end

----------life cycle----------
-- function UPHumanWeaponAttachmentSlot:OnCreate()
-- end

-- function UPHumanWeaponAttachmentSlot:OnDestroy()
-- end

-- function UPHumanWeaponAttachmentSlot:OnLoad()
-- end

-- function UPHumanWeaponAttachmentSlot:OnUnload()
-- end

-- function UPHumanWeaponAttachmentSlot:OnEnter()
-- end

-- function UPHumanWeaponAttachmentSlot:OnShow()
-- end

function UPHumanWeaponAttachmentSlot:OnExit()
    self.bDragEventBinded = false
    self.bDropEventBinded = false
end

function UPHumanWeaponAttachmentSlot:OnBindEvent( EventHelper )

end

-- function UPHumanWeaponAttachmentSlot:OnUnbindEvent( EventHelper )
-- end

function UPHumanWeaponAttachmentSlot:RegisterDragEvent()
    if not self.bDragEventBinded and self.bEnabled and self.tbWeaponAttachment then
        local EventHelper = self.EventHelper
        local pWidgetRef = self.pWidgetRef
        local pbDrag = pWidgetRef
        UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pbDrag)
        EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
        EventHelper:RegisterCppDelegate(pbDrag.OnClicked, self, OnClicked)
        self.bDragEventBinded = true
    end
end

function UPHumanWeaponAttachmentSlot:RegisterDropEvent()
    if not self.bDropEventBinded and self.bEnabled then
        local EventHelper = self.EventHelper
        local pWidgetRef = self.pWidgetRef
        local pbDrag = pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnAcceptDrop, self, OnAcceptDrop)
        EventHelper:RegisterEvent(ClientEventDef.EV_BACKPACK_LISTITEM_SELECTED, self, OnListItemSelected)
        EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_START, self, OnDragStart)
        EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_END, self, OnDragEnd)
        self.bDropEventBinded = true
    end
end

function UPHumanWeaponAttachmentSlot:SetEnable(bEnabled)
    self.bEnabled = bEnabled
    if not bEnabled then
        self.bDragEventBinded = false
        self.bDropEventBinded = false
        self.EventHelper:UnregisterAll()
    end
end


return UPHumanWeaponAttachmentSlot