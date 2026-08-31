-----------------------------------------------------
--File Name    : LobbyCaptainTitleOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainTitleOperator = luaclass("LobbyCaptainTitleOperator")

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")


LobbyCaptainTitleOperator.ListHelper = nil
LobbyCaptainTitleOperator.tbTitleInfo = nil

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


local function ShowTip(self)
    local pWidgetRef = GetPrefabWidget(self)
    self:OnTipShow(self.tbTitleInfo)
    pWidgetRef.bgbDescTip:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
end

local function HideTip(self)
    local pWidgetRef = GetPrefabWidget(self)
    pWidgetRef.bgbDescTip:SetVisibility(ESlateVisibility_Collapsed)
end

local function OnCheckStateChanged(self, bChecked)
    if bChecked then
        ShowTip(self)
    else
        HideTip(self)
    end
end

local function CreateListHelper(self)
    self.ListHelper = SelfVerticalListHelper()
    local pWidgetRef = GetPrefabWidget(self)
    self.ListHelper:Init(GetOwnerPrefab(self), pWidgetRef.kmlistProperty, {}, UIDef.UP_LOBBY_CAPTAIN_WEAPON_DESC_ITEM)
end

local function DestroyListHelper(self)
    if self.ListHelper then
        self.ListHelper:Uninit()
    end
end

function LobbyCaptainTitleOperator:BindEventOnActivate()
    local pWidgetRef = GetPrefabWidget(self)
    local EventHelper = GetEventHelper(self)
    self.TitleCheckboxDelegate = EventHelper:RegisterCppDelegate(pWidgetRef.chboxTip.OnCheckStateChanged, self, OnCheckStateChanged)
    -- EventHelper:RegisterLuaDelegate(self.SelfVerticalListHelper.OnSelectedChangedDelegate, self.OnSelectedChangedDelegate, self)
end

function LobbyCaptainTitleOperator:UnbindEventOnDeactivate()
    if self.TitleCheckboxDelegate then
        local EventHelper = GetEventHelper(self)
        -- EventHelper:UnregisterLuaDelegate(self.SelfVerticalListHelper.OnSelectedChangedDelegate, self.OnSelectedChangedDelegate, self)
        EventHelper:UnregisterCppDelegate(self.TitleCheckboxDelegate)
    end
end

function LobbyCaptainTitleOperator:Init(tbOwner)
    self.tbOwner = tbOwner
    self.tbTitleInfo = nil
    CreateListHelper(self)
    HideTip(self)
end

function LobbyCaptainTitleOperator:Uninit()
    DestroyListHelper(self)
    self.tbTitleInfo = nil
    self.tbOwner = nil
end

function LobbyCaptainTitleOperator:SetTitleInfo(tbTitleInfo)
    self.tbTitleInfo = tbTitleInfo
    self:OnTitleInfoSet(tbTitleInfo)
    -- local pWidgetRef = GetPrefabWidget(self)
    -- pWidgetRef.chboxTip:SetIsChecked(false)
end

function LobbyCaptainTitleOperator:SetTipCheckState(bChecked)
    local pWidgetRef = GetPrefabWidget(self)
    pWidgetRef.chboxTip:SetIsChecked(bChecked)
    OnCheckStateChanged(self, bChecked)
end

function LobbyCaptainTitleOperator:SetTitleText(l10nText)
    local pWidgetRef = GetPrefabWidget(self)
    pWidgetRef.kmtxtTitle:SetText(l10nText)
end

function LobbyCaptainTitleOperator:SetTitleVisible(bVisible)
    local pWidgetRef = GetPrefabWidget(self)
    if bVisible then
        pWidgetRef.sboxTitle:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        pWidgetRef.sboxTitle:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function LobbyCaptainTitleOperator:SetTipTitle(l10nText)
    local pWidgetRef = GetPrefabWidget(self)
    pWidgetRef.kmtxtTipTitle:SetText(l10nText)
end

function LobbyCaptainTitleOperator:OnTitleInfoSet(tbTitleInfo)
    -- override by sub class
end

function LobbyCaptainTitleOperator:OnTipShow(tbTitleInfo)
    -- override by sub class
end


return LobbyCaptainTitleOperator