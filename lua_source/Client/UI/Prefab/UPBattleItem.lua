local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBattleItem = luaclass("UPBattleItem", PrefabBase)

local BattleItemSystemClient = require("BattleItemSystemClient")
local ClientEventDef = require("ClientEventDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local UIDragDropUtils = require("UIDragDropUtils")

UPBattleItem.nItemInstanceId = 0
UPBattleItem.nSlotIndex = 0
UPBattleItem.nLimitItemCategory = 0
UPBattleItem.bEnableClickUnequip = false
UPBattleItem.bEnabled = false
UPBattleItem.bDragEventBinded = false

function UPBattleItem:OnLoad()
    --self:SetItem(0)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

function UPBattleItem:OnClicked()
    if self.nItemInstanceId and self.nItemInstanceId > 0 then
        log("unenquipped item instance ", self.nItemInstanceId)
        BattleItemSystemClient:RequestUnEquipItem(self.nItemInstanceId)
    end
end

local function OnClickedBtn(self)
    if self.bEnableClickUnequip then
        self:OnClicked()
    end
end

local function OnItemPropertyChanged(self, Item)
    local nItemInstanceId = Item:GetInstanceId()
    if nItemInstanceId == self.nItemInstanceId then
        self:SetItem(nItemInstanceId)
    end
end

local function OnCreateVisual(self, pVisualWidget)
    if self.nItemInstanceId > 0 then
        local tbItem = BattleItemSystemClient:GetItem(self.nItemInstanceId)
        if tbItem then
            local tbRes = BattleItemResDataTable:GetTemplate(tbItem.tbTemplate.nResId)
            if not tbRes then
                logerror("UPBattleItem OnCreateVisual: invalid res id ", tbItem.tbTemplate.nResId)
                return
            end
            local szItemIconPath = tbRes.szIconPath
            local IconObj = szItemIconPath:load()
            if(IconObj == nil)then
                logwarning("UPBattleItem OnCreateVisual: icon is not found,path="..tostring(szItemIconPath))
                return
            end
            local pWidgetRef = self.pWidgetRef
            UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
        end
    end
end


function UPBattleItem:SetEnable(bEnabled)
    self.bEnabled = bEnabled
    if not bEnabled then
        self.bDragEventBinded = false
        self.EventHelper:UnregisterAll()
    end
end


function UPBattleItem:RegisterDragEvent()
    if not self.bDragEventBinded and self.bEnabled and self.nItemInstanceId > 0 then
        local EventHelper = self.EventHelper
        local pbDrag = self.pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnClicked, self, OnClickedBtn)
        EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
        EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemPropertyChanged)
        UIDragDropUtils.FireEventWhenItemDragged(EventHelper, pbDrag)
        self.bDragEventBinded = true
    end
end


function UPBattleItem:OnBindEvent(EventHelper)

end

function UPBattleItem:SetSlotId(nSlotIndex)
    self.nSlotIndex = nSlotIndex
    self:SetItem(0)
end

function UPBattleItem:SetItem(nItemInstanceId)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.nItemInstanceId = nItemInstanceId
    local tbItemObject = BattleItemSystemClient:GetItem(nItemInstanceId)
    if tbItemObject and self:CanEquip(tbItemObject) then
        self.pWidgetRef.bEnableDrag = true
        self:OnEquiped(tbItemObject)
        self:RegisterDragEvent()
    else
        self.nItemInstanceId = 0
        self.pWidgetRef.bEnableDrag = false
        self:OnUnequipped()
    end
end


function UPBattleItem:OnEquiped(tbItemObject)

end


function UPBattleItem:OnUnequipped()

end

function UPBattleItem:CanEquip(tbItemObject)
    if tbItemObject and self.nLimitItemCategory > 0 and self.nLimitItemCategory == tbItemObject.tbTemplate.nCategory then
        return true
    end
    return false
end

function UPBattleItem:OnExit()
    self.bDragEventBinded = false
end

return UPBattleItem