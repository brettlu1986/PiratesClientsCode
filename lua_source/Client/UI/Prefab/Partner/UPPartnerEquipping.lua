local luaclass = require("luaclass")
local Prefabbase = require("Prefabbase")
local UPPartnerEquipping = luaclass("UPPartnerEquipping", Prefabbase)

local ClientEventDef = require("ClientEventDef")
local SelfListHelperNew = require("SelfListHelperNew")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local MAX_EQUIPPING_COUNT = 3
local EQUIPPING_ITEM_PREFAB_NAME = "pbPartnerEquippingItem"
UPPartnerEquipping.tbEquippingItems = nil
UPPartnerEquipping.nSelectedItemIndex = -1

local function UpdateAllRelation(self)
    for i, v in ipairs(self.tbEquippingItems) do
        v:UpdateRelation()
    end
end

local function OnReceiveRequestEquipPartnerResult(self, nSlot, nPartnerId)
    self.tbEquippingItems[nSlot]:SetPartnerId(nPartnerId)
    UpdateAllRelation(self)
end

local function OnReceiveRequestUnequipPartnerResult(self, nSlot)
    self.tbEquippingItems[nSlot]:SetPartnerId(nil)
    UpdateAllRelation(self)
end

local function OnReceiveUpLevelPartner(self, nPartnerId, nLevel)
    for i, v in ipairs(self.tbEquippingItems) do
        if nPartnerId == v:GetPartnerId() then
            v:SetLevel(nLevel)
        end
    end
    UpdateAllRelation(self)
end

local function SetPartnerListVisible(self, bVisible)
    self.pWidgetRef.cvsPartnerList:SetVisibility(bVisible and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    if bVisible then
        local PartnerComponent = GamePlayerSelfHelper:Get().PartnerComponent
        local tbData = PartnerComponent:GetUnequippedPartnerList()
        if #tbData > 0 then
            self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.Collapsed)
            self.pWidgetRef.listPartner:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.HitTestInvisible)
            self.pWidgetRef.listPartner:SetVisibility(ESlateVisibility.Collapsed)
        end
        self.ListHelper:SetData(tbData)
    end
end

local function OnListSelectedChanged(self)
    SetPartnerListVisible(self, false)
    self.PartnerComponent:RequestEquipPartner(self.nSelectedItemIndex, self.ListHelper:GetSelectedData().nPartnerId)
end

local function OnClickedBtnCloseList(self)
    SetPartnerListVisible(self, false)
end

function UPPartnerEquipping:OnLoad()
    self.PartnerComponent = GamePlayerSelfHelper:Get().PartnerComponent

    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, self.pWidgetRef.listPartner)

    local tbEquippedPartnerList = self.PartnerComponent:GetEquippedPartnerList()
    self.tbEquippingItems = {}
    for i=1,MAX_EQUIPPING_COUNT do
        self.tbEquippingItems[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef[EQUIPPING_ITEM_PREFAB_NAME .. i])
        self.tbEquippingItems[i]:SetEquipPartnerCallback(function()
            self.nSelectedItemIndex = i
            SetPartnerListVisible(self, true)
        end)
        self.tbEquippingItems[i]:SetUnequipPartnerCallback(function()
            self.PartnerComponent:RequestUnequipPartner(i)
        end)
        self.tbEquippingItems[i]:SetPartnerId(tbEquippedPartnerList[i])
    end
end

function UPPartnerEquipping:OnUnload()
    self.ListHelper:Uninit()
end

function UPPartnerEquipping:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCloseList.OnClicked, self, OnClickedBtnCloseList)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCloseListArea.OnClicked, self, OnClickedBtnCloseList)
    EventHelper:RegisterLuaDelegate(self.ListHelper.OnSelectedChangedDelegate, OnListSelectedChanged, self)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_PARTNER_RESULT, self, OnReceiveRequestEquipPartnerResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNEQUIP_PARTNER_RESULT, self, OnReceiveRequestUnequipPartnerResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_PARTNER_LEVEL_UP_RESULT, self, OnReceiveUpLevelPartner)
end

function UPPartnerEquipping:Deactivate()
    SetPartnerListVisible(self, false)
end

return UPPartnerEquipping