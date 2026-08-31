-----------------------------------------------------
--File Name    : UPLobbyShipWeaponItem.lua
--Author       : chenyixin
--Description  : 船战备舰船武器分页每行中具体武器Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipWeaponItem = luaclass("UPLobbyShipWeaponItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UPLobbyShipWeaponItem.tbTemplate = nil
UPLobbyShipWeaponItem.fnOnClickedItemCallback = nil
UPLobbyShipWeaponItem.fnOnSelectItemCallback = nil
UPLobbyShipWeaponItem.bNew = false

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function OnClickedBtnItem(self)
    if self.fnOnClickedItemCallback then
        self.fnOnClickedItemCallback(self)
    end
end

local function OnReceiveActivateWeaponResult(self, nPartCategory, nTemplateId)
    if nTemplateId == self.tbTemplate.nId then
        self:PlayAnimation("anim_LobbyItemWeaponEnable", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
end

function UPLobbyShipWeaponItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnselect.OnClicked, self, OnClickedBtnItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_WEAPON_RESULT, self, OnReceiveActivateWeaponResult)
end

function UPLobbyShipWeaponItem:SetWeaponTemplate(tbTemplate)
    self.tbTemplate = tbTemplate
    local ShipPreparationComponent = GetPreparationComponent()
    local pWidgetRef = self.pWidgetRef

    local nBattleItemId = tbTemplate.nBattleItemId
    local tbBattleResTemplate = BattleItemDataTable:GetResTemplate(nBattleItemId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgWeapon, tbBattleResTemplate.szEquipmentDisplayPath:load())

    local nWeaponId = tbTemplate.nId
    local nActiveWeaponId = ShipPreparationComponent:GetActiveWeaponId(tbTemplate.nSubCategory)
    pWidgetRef.txtUse:SetVisibility((nActiveWeaponId == nWeaponId) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.imgFxBgFlow:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.imgFxBgFlow:SetRenderOpacity((nActiveWeaponId == nWeaponId) and 1 or 0)

    local bUnlocked = ShipPreparationComponent:IsItemUnlocked(nWeaponId)
    pWidgetRef.imgLock:SetVisibility((not bUnlocked) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)

    local bNew = ShipPreparationComponent:IsNewShipItem(nWeaponId)
    pWidgetRef.imgIconTips:SetVisibility(bNew and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    self.bNew = bNew
end

function UPLobbyShipWeaponItem:GetWeaponTemplate()
    return self.tbTemplate
end

function UPLobbyShipWeaponItem:GetWeaponId()
    return self.tbTemplate and self.tbTemplate.nId
end

function UPLobbyShipWeaponItem:SetCallback(fnOnClickedItemCallback, fnOnSelectItemCallback)
    self.fnOnClickedItemCallback = fnOnClickedItemCallback
    self.fnOnSelectItemCallback = fnOnSelectItemCallback
end

function UPLobbyShipWeaponItem:SelectItem()
    self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.HitTestInvisible)
    if self.fnOnSelectItemCallback then
        self.fnOnSelectItemCallback(self)
    end
end

function UPLobbyShipWeaponItem:UnselectItem()
    self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Collapsed)
end

function UPLobbyShipWeaponItem:TriggerSelectItem()
    OnClickedBtnItem(self, false)
end

function UPLobbyShipWeaponItem:Activate()
    -- self:PlayAnimationWithUserWidget(self.pWidgetRef.pbFx, "animActiveFx", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPLobbyShipWeaponItem:IsNew()
    return self.bNew
end

return UPLobbyShipWeaponItem