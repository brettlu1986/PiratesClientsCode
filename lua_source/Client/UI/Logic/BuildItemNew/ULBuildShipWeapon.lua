-----------------------------------------------------
--File Name    : ULBuildShipWeapon.lua
--Author       : zhiyuan
--Create Time  : 2019-03-12
--Description  : 建造船武器的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuildShipWeapon = luaclass("ULBuildShipWeapon", UILogicBase)

local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local LuaDelegateClass = require("LuaDelegate")
local UIDef = require("UIDef")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

ULBuildShipWeapon.tbPbBuildShipWeapons = nil
ULBuildShipWeapon.OnBuildShipWeaponPressedDelegate = nil

local function GetEquippedWeapon(nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, nSlotIndex)
end

local function SetItemSelected(self, nPos1, nPos2)
    for i, v1 in pairs(self.tbPbBuildShipWeapons) do
        for j, v2 in pairs(v1) do
            if i == nPos1 and j == nPos2 then
                v2:SetSelected(true)
            else
                v2:SetSelected(false)
            end
        end
    end
end

local function SetAllItemUnSelected(self)
    for i, v1 in pairs(self.tbPbBuildShipWeapons) do
        for j, v2 in pairs(v1) do
            v2:SetSelected(false)
        end
    end
end

local function OnShipWeaponSelected(self, pbBuildItem)
    if pbBuildItem:IsSetSelected() then
        self.Owner:CloseTips()
        pbBuildItem:SetSelected(false)
    else
        self.Owner:ShowBuildItemTipsNew(pbBuildItem:GetTemplateId())
        SetItemSelected(self, pbBuildItem:GetPos1(), pbBuildItem:GetPos2())
    end
end

local function AddPbBuildShipWeapon(self, nSlotIndex, nIndex, pbBuildShipWeapon)
    local tbPbs = self.tbPbBuildShipWeapons[nSlotIndex]
    if tbPbs == nil then
        self.tbPbBuildShipWeapons[nSlotIndex] = {}
        tbPbs = self.tbPbBuildShipWeapons[nSlotIndex]
    end
    tbPbs[nIndex] = pbBuildShipWeapon
end

local function GetOrCreatePbBuildShipWeapon(self, nSlotIndex, nIndex)
    local tbPbs = self.tbPbBuildShipWeapons[nSlotIndex]
    if tbPbs == nil then
        self.tbPbBuildShipWeapons[nSlotIndex] = {}
        tbPbs = self.tbPbBuildShipWeapons[nSlotIndex]
    end
    local tbPb = tbPbs[nIndex]
    local pWidgetRef = self.pWidgetRef
    if tbPb == nil then
        tbPb = self.PrefabHelper:CreatePrefab(UIDef.UP_BUILD_ITEM)
        pWidgetRef["wboxShipWeapon"..nSlotIndex]:AddChild(tbPb.pWidgetRef)
        tbPb:SetOnItemPressedDelegate(self.OnBuildShipWeaponPressedDelegate, nSlotIndex, nIndex)
        tbPb:Collaped()
        AddPbBuildShipWeapon(self, nSlotIndex, nIndex, tbPb)
    end
    return tbPb
end

local function RefreshShipWeaponsOnOneSlot(self, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local tbItemTemplates = CheckCanBuildItemHelper.GetAvailableShipWeaponTemplates(nCharacterInstanceId, nSlotIndex, true)
    for i, v in ipairs(tbItemTemplates) do
        local pbBuildShipWeapon = GetOrCreatePbBuildShipWeapon(self, nSlotIndex, i)

        local bIsCurrent = false
        local EquippedWeapon = GetEquippedWeapon(nSlotIndex)
        local nTemplateId = v.nId
        if EquippedWeapon and EquippedWeapon:GetTemplateId() == nTemplateId then
            bIsCurrent = true
        end

        pbBuildShipWeapon:Refresh(v, bIsCurrent)
    end
end

local function RefreshShipWeapons(self)
    for i = ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        RefreshShipWeaponsOnOneSlot(self, i)
    end
end

function ULBuildShipWeapon:OnLoad()
    self.tbPbBuildShipWeapons = {}
    self.OnBuildShipWeaponPressedDelegate = LuaDelegateClass()
end

function ULBuildShipWeapon:OnUnload()

end

function ULBuildShipWeapon:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnBuildShipWeaponPressedDelegate, OnShipWeaponSelected, self)
end

function ULBuildShipWeapon:Refresh()
    self.Owner:CloseTips()
    RefreshShipWeapons(self)
    SetAllItemUnSelected(self)
end

return ULBuildShipWeapon