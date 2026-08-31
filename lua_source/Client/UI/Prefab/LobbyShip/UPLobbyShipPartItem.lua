-----------------------------------------------------
--File Name    : UPLobbyShipPartItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 舰船零件页面零件Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipPartItem = luaclass("UPLobbyShipPartItem", ListItemBase)

local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ItemSystem = require("ItemSystem")

local function OnClickedItem(self)
    self:ToogleSelectItem()
end

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

function UPLobbyShipPartItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedItem)
end

function UPLobbyShipPartItem:OnRefresh(tbData)
    local nPartId = tbData.nId
    self.pWidgetRef.imgSelected:SetVisibility(self:IsSelected() and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    self.pWidgetRef.txtName:SetText(tbData.l10nName)
    self.pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_PART_DESC_FORMAT"), ItemSystem:GetItemIntro(nPartId)))

    local nActivePartId = GetPreparationComponent():GetActivePartId(tbData.nSubCategory)
    local bActive = nActivePartId == nPartId
    local bLastActive = self.ListHelper.tbExtraDatas.tbActiveStates[nPartId]
    local pbFx = self.pWidgetRef.pbFx
    if bActive then
        self.pWidgetRef.txtActive:SetVisibility(ESlateVisibility.HitTestInvisible)
        local nStartTime = (bLastActive == false) and 0 or pbFx.animActiveFx:GetEndTime()
        self:StopAnimationWithUserWidget(pbFx, "animInactiveFx")
        self:PlayAnimationWithUserWidget(pbFx, "animActiveFx", nStartTime, 1, EUMGSequencePlayMode.Forward, 1)
    else
        self.pWidgetRef.txtActive:SetVisibility(ESlateVisibility.Collapsed)
        local nStartTime = (bLastActive == true) and 0 or pbFx.animInactiveFx:GetEndTime()
        self:StopAnimationWithUserWidget(pbFx, "animActiveFx")
        self:PlayAnimationWithUserWidget(pbFx, "animInactiveFx", nStartTime, 1, EUMGSequencePlayMode.Forward, 1)
    end
    self.ListHelper.tbExtraDatas.tbActiveStates[nPartId] = bActive

    local bUnlocked = GetPreparationComponent():IsItemUnlocked(nPartId)
    self.pWidgetRef.imgLock:SetVisibility((not bUnlocked) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    self.pWidgetRef.cvsDisplay:SetIsEnabled(bUnlocked)
end

return UPLobbyShipPartItem