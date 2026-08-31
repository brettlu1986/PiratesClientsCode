-----------------------------------------------------
--File Name    : LobbyCaptainShortCutOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainShortCutOperator = luaclass("LobbyCaptainShortCutOperator")

local ItemSourceDataTable = require("ItemSourceDataTable")
local ShopSystem = require("ShopSystem")
local ClientEventDef = require("ClientEventDef")

LobbyCaptainShortCutOperator.tbOwner = nil
LobbyCaptainShortCutOperator.nTemplateId = nil
LobbyCaptainShortCutOperator.ClickDelegate = nil

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

local function OnClicked(self)
    local EventHelper = GetEventHelper(self)
    EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_BUY_ITEM, self.nTemplateId)
    ShopSystem:OnBuyButtonClickByTemplateId(self.nTemplateId)
end

function LobbyCaptainShortCutOperator:BindEventOnActivate()
    local pWidgetRef = GetPrefabWidget(self)
    local EventHelper = GetEventHelper(self)
    self.ClickDelegate = EventHelper:RegisterCppDelegate(pWidgetRef.btnConfirm.OnClicked, self, OnClicked)
end

function LobbyCaptainShortCutOperator:UnbindEventOnDeactivate()
    if self.ClickDelegate then
        local EventHelper = GetEventHelper(self)
        EventHelper:UnregisterCppDelegate(self.ClickDelegate)
    end
end

function LobbyCaptainShortCutOperator:ShowShortcut(tbItemTemplate)
    self.nTemplateId = tbItemTemplate.nId
    local nSourceType = tbItemTemplate.nSourceType
    local pWidgetRef = self.tbOwner.pWidgetRef
    if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
        pWidgetRef.bdrUnlock:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.kmtxtUnlockDesc:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnConfirm:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.bdrUnlock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.kmtxtUnlockDesc:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.btnConfirm:SetVisibility(ESlateVisibility.Collapsed)
        local l10nToastDesc = ItemSourceDataTable:GetSourceDesc(nSourceType)
        pWidgetRef.kmtxtUnlockDesc:SetText(l10nToastDesc)
    end
end

function LobbyCaptainShortCutOperator:HideShortCut()
    local pWidgetRef = self.tbOwner.pWidgetRef
    pWidgetRef.bdrUnlock:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.kmtxtUnlockDesc:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnConfirm:SetVisibility(ESlateVisibility.Collapsed)
end

function LobbyCaptainShortCutOperator:Init(tbOwner)
    self.tbOwner = tbOwner
    self:HideShortCut()
end

function LobbyCaptainShortCutOperator:Uninit()
    self.tbOwner = nil
end


return LobbyCaptainShortCutOperator