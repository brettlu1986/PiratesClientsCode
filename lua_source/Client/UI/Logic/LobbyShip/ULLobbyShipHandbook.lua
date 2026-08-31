-----------------------------------------------------
--File Name    : ULLobbyShipHandbook.lua
--Author       : chenyixin
--Description  : 舰船图鉴和商城舰船展示通用逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipHandbook = luaclass("ULLobbyShipHandbook", UILogicBase)

local LobbyShipDef = require("LobbyShipDef")

local ShipOwningStateDef = LobbyShipDef.OwningStateDef

ULLobbyShipHandbook.bIsDrag = false
ULLobbyShipHandbook.nLastPosX = 0
ULLobbyShipHandbook.nActorIndex = 1

---------------------------------------
-- Widget事件
---------------------------------------
local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    self.bIsDrag = true
    self.nLastPosX = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent).X
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if self.bIsDrag then
        local nCurrentPosX = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent).X
        self.OwnerSub:RotateActorByIndex(self.nActorIndex, nCurrentPosX - self.nLastPosX)
        self.nLastPosX = nCurrentPosX
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = false
    return WidgetBlueprintLibrary.Handled()
end

---------------------------------------
-- life cycle
---------------------------------------
function ULLobbyShipHandbook:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function ULLobbyShipHandbook:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

function ULLobbyShipHandbook:OnShow()
    self.Owner.tbShipDetail:SetShowDetailedInfo(false)
end

---------------------------------------
-- 接口
---------------------------------------
function ULLobbyShipHandbook:GetShipData(tbShipTemplate, ShipPreparationComponent)
    local tbData = {}
    tbData.nShipItemId = tbShipTemplate.nId
    tbData.nGrade = tbShipTemplate.nGrade
    tbData.nLevel = tbShipTemplate.nLevel
    tbData.nSubCategory = tbShipTemplate.nSubCategory
    tbData.tbTemplate = tbShipTemplate
    local nShipOwningState = 1
    if ShipPreparationComponent:IsItemUnlocked(tbShipTemplate.nId) then
        if ShipPreparationComponent:IsShipItemPurchased(tbShipTemplate.nId) then
            nShipOwningState = ShipOwningStateDef.Owned
        else
            nShipOwningState = ShipOwningStateDef.Experience
        end
    else
        nShipOwningState = ShipOwningStateDef.Locked
    end
    tbData.nShipOwningState = nShipOwningState
    tbData.nSortIndex = tbShipTemplate.nSortIndex
    return tbData
end

function ULLobbyShipHandbook:UpdateShipDisplay(nShipId, tbShipData, nActorIndex)
    if not self.Owner:IsVisible() then
        return
    end

    self.Owner.tbShipDetail:SetShipTemplateId(tbShipData.tbTemplate.nBattleItemId)
    self.Owner.tbShipTitle:SetData(tbShipData)
    self.nActorIndex = nActorIndex and nActorIndex or 1
end

return ULLobbyShipHandbook