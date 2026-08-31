-----------------------------------------------------
--File Name    : LobbyCaptainHumanFashionFlagOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainHumanFashionFlagOperator = luaclass("LobbyCaptainHumanFashionFlagOperator")

local ClientEventDef = require("ClientEventDef")
local ItemSystem = require("ItemSystem")
local HumanAvatarHelper = require("HumanAvatarHelper")
local HumanAvatarDef = require("HumanAvatarDef")

LobbyCaptainHumanFashionFlagOperator.nFashionType = nil
LobbyCaptainHumanFashionFlagOperator.FashionOverrideDelegate = nil
local FashionType = HumanAvatarDef.FashionType

local function GetOwnerPrefab(self)
    return self.tbOwner
end

local function GetEventHelper(self)
    local tbOwner = GetOwnerPrefab(self)
    return tbOwner.EventHelper
end

local function GetPrefabWidget(self)
    local tbOwner = GetOwnerPrefab(self)
    assert(tbOwner)
    return tbOwner.pWidgetRef
end

local function OnFlagModified(self)
    self:UpdateFashionType(self.nFashionType)
    local EventHelper = GetEventHelper(self)
    EventHelper:FireEvent(ClientEventDef.EV_NOTIFY_FASHION_FLAG_CHANGED, self.nFashionType)
end


local function OnCheckStateChanged(self, bChecked)
    local nValue = ItemSystem:GetHumanFashionFlag()
    local nResult = HumanAvatarHelper.ModifyFlagValue(nValue, self.nFashionType, bChecked)
    ItemSystem:RequestToModifyFashionFlag(nResult)
end

function LobbyCaptainHumanFashionFlagOperator:BindEventOnActivate()
    local pWidgetRef = GetPrefabWidget(self)
    local EventHelper = GetEventHelper(self)
    self.FashionOverrideDelegate = EventHelper:RegisterCppDelegate(pWidgetRef.chboxFashionOverride.OnCheckStateChanged, self, OnCheckStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_FASHION_FLAG_MODIFIED, self, OnFlagModified)
end

function LobbyCaptainHumanFashionFlagOperator:UnbindEventOnDeactivate()
    local EventHelper = GetEventHelper(self)
    if self.FashionOverrideDelegate then
        EventHelper:UnregisterCppDelegate(self.FashionOverrideDelegate)
    end
    EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_FASHION_FLAG_MODIFIED, self, OnFlagModified)
end

function LobbyCaptainHumanFashionFlagOperator:UpdateFashionType(nFashionType)
    self.nFashionType = nFashionType
    local pWidgetRef = GetPrefabWidget(self)
    if nFashionType == FashionType.Basic then
        pWidgetRef.chboxFashionOverride:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.bdrOvrride:SetVisibility(ESlateVisibility_Collapsed)
    else
        pWidgetRef.chboxFashionOverride:SetVisibility(ESlateVisibility_Visible)
        local bOverride = self:IsOverrideByBasic(nFashionType)
        pWidgetRef.chboxFashionOverride:SetIsChecked(bOverride)
        if bOverride then
            pWidgetRef.bdrOvrride:SetVisibility(ESlateVisibility_Visible)
        else
            pWidgetRef.bdrOvrride:SetVisibility(ESlateVisibility_Collapsed)
        end
    end

end


function LobbyCaptainHumanFashionFlagOperator:IsOverrideByBasic(nFashionType)
    local nValue = ItemSystem:GetHumanFashionFlag()
    local bOverride = HumanAvatarHelper.IsOverrideByBasicFashion(nValue, nFashionType)
    return bOverride
end

function LobbyCaptainHumanFashionFlagOperator:Init(tbOwner)
    self.tbOwner = tbOwner
end

function LobbyCaptainHumanFashionFlagOperator:Uninit()
    local pWidgetRef = GetPrefabWidget(self)
    pWidgetRef.bdrOvrride:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.chboxFashionOverride:SetVisibility(ESlateVisibility_Collapsed)
    self.tbOwner = nil
end



return LobbyCaptainHumanFashionFlagOperator