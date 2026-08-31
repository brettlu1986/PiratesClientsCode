-----------------------------------------------------
--File Name    : UPLobbyShipPart.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 船战备舰船零件页面
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipPart = luaclass("UPLobbyShipPart", PrefabBase)

local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
local ClientEventDef = require("ClientEventDef")
local ShipPartTypeDef = require("ShipPartTypeDef")
local ItemCategoryDef = require("ItemCategoryDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local UNSELECTED_INDEX = -1

UPLobbyShipPart.ulLobbyShipPartDetail = nil
UPLobbyShipPart.tbTemplateData = nil
UPLobbyShipPart.TabBarHelper = nil
UPLobbyShipPart.ListHelper = nil
UPLobbyShipPart.tbSelectedIndex = nil

local function OnListSelectedChanged(self, nIndex)
    self.ulLobbyShipPartDetail:SetPartTemplate(self.ListHelper:GetSelectedData())
    local nCategory = self.TabBarHelper:GetCurrentIdx()
    self.tbSelectedIndex[nCategory] = nIndex
    if UNSELECTED_INDEX == nIndex then
        self.ListHelper:ScrollToTop()
    end
end

local function OnTabBarSelectedChanged(self, nIndex)
    self.ListHelper.tbExtraDatas.tbActiveStates = {}
    self.ListHelper:SetData(self.tbTemplateData[nIndex], true)
    -- self.ListHelper:SetSelectedIndex(self.tbSelectedIndex[nIndex] or UNSELECTED_INDEX)
    self.ListHelper:SetSelectedIndex(UNSELECTED_INDEX)
end

local function OnReceiveActivatePartResult(self, nPartCategory, nTemplateId)
    if self.TabBarHelper:GetCurrentIdx() == nPartCategory then
        self.ListHelper:RefreshItemInView()
        self.ulLobbyShipPartDetail:RefreshBtnActivateState(self)
    end
end

-- 新增道具
local function OnAddItem(self, Item)
    local nItemTemplateId = Item:GetTemplateId()
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_PART and self.TabBarHelper:GetCurrentIdx() == tbItemTemplate.nSubCategory then
        self.ListHelper:RefreshItemInView()
        self.ulLobbyShipPartDetail:RefreshBtnActivateState()
    end
end

-- 道具期限变化
local function OnItemChangeExpiredAt(self, nItemInstanceId, bPermanent)
    if not bPermanent then
        return
    end
    local Item = ItemSystem:GetItem(nItemInstanceId)
    OnAddItem(self, Item)
end

local function GetItemIndexById(self, nItemTemplateId)
    local tbData = self.ListHelper:GetData()
    for i, v in ipairs(tbData) do
        if v.nId == nItemTemplateId then
            return i
        end
    end
    return -1
end

local function InitPartData(self)
    local tbTemplateData = {}
    local tbShipPartTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.SHIP_PART)
    for _, tbTemplate in pairs(tbShipPartTemplates) do
        local nCategory = tbTemplate.nSubCategory
        tbTemplateData[nCategory] = tbTemplateData[nCategory] or {}
        table.insert(tbTemplateData[nCategory], tbTemplate)
    end
    for i, v in ipairs(tbTemplateData) do
        table.sort(v, function(A, B) return A.nId < B.nId end)
    end
    self.tbTemplateData = tbTemplateData
end

function UPLobbyShipPart:OnLoad()
    InitPartData(self)

    self.ulLobbyShipPartDetail = self.UILogicHelper:CreateUILogic("ULLobbyShipPartDetail")

    self.TabBarHelper = SelfTabBarHelper()
    self.TabBarHelper:Init(self, self.pWidgetRef.hboxTopBar)
    self.TabBarHelper.OnSelectedChangedDelegate:Bind(OnTabBarSelectedChanged, self)

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listPart)
    self.ListHelper.tbExtraDatas.tbActiveStates = {}
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnListSelectedChanged, self)
end

function UPLobbyShipPart:OnUnload()
    self.TabBarHelper:Uninit()
    self.TabBarHelper = nil

    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPLobbyShipPart:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_PART_RESULT, self, OnReceiveActivatePartResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnItemChangeExpiredAt)
end

function UPLobbyShipPart:Activate()
    self.tbSelectedIndex = {}
    self.TabBarHelper:SelectByIndex(ShipPartTypeDef.ARMOR, true)
end

function UPLobbyShipPart:SetSelectedItem(nItemTemplateId)
    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate and (tbTemplate.nCategory == ItemCategoryDef.SHIP_PART) then
        self.TabBarHelper:SelectByIndex(tbTemplate.nSubCategory, true)
        self.ListHelper:SetSelectedIndex(GetItemIndexById(self, nItemTemplateId))
    end
end

return UPLobbyShipPart