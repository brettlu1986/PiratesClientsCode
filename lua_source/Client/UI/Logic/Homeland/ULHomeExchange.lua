-----------------------------------------------------
--File Name    : ULHomeExchange.lua
--Author       : zhiyuan
--Create Time  : 2019-05-08
--Description  : 道具兑换的ul
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHomeExchange = luaclass("ULHomeExchange", UILogicBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local BuildingExchangeDataTable = require("BuildingExchangeDataTable")
local LuaDelegateClass = require("LuaDelegate")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local HomelandSystem = require("HomelandSystem")

ULHomeExchange.OnExchangeButtonPressedDelegate = nil
ULHomeExchange.ListHelper = nil

local function IsItemEnough(tbExchangeTemplate)
    local tbCostItems = tbExchangeTemplate.tbCostItems
    for _, v in ipairs(tbCostItems) do
        local HomelandItemSystem = HomelandSystem:GetSubSystem("HomelandItemSystem")
        if not HomelandItemSystem:IsAvailableItemEnough(v.nItemTemplateId, v.nCost) then
            return false
        end
    end
    return true
end

local function OnExchangeButtonPressed(self, tbExchangeTemplate)
    local pbHomeItemExchange = self.PrefabHelper:CreatePrefab(UIDef.UP_HOME_EXCHANGE_TIPS)
    local Dialog = UIUtils.CreateDialog(UITextDef.UI_HOMELAND_EXCHANGE_TITLE )
    Dialog:SetView(pbHomeItemExchange.pWidgetRef)
    Dialog:SetPositiveText(UITextDef.UI_HOMELAND_EXCHANGE_COMMIT)

    if IsItemEnough(tbExchangeTemplate) then
        Dialog:SetPositiveButtonEnabled(true)
        Dialog:SetPositiveButtonCallback(function()
            pbHomeItemExchange:OnCommitExchange()
            self.PrefabHelper:UnbindPrefab(pbHomeItemExchange)
        end)
    else
        Dialog:SetPositiveButtonEnabled(false)
        Dialog:SetPositiveButtonDisableCallback(function()
            pbHomeItemExchange:OnDisableButtonClicked()
        end)
    end

    Dialog:SetNegativeButtonVisible(false)
    pbHomeItemExchange:OnRefresh(tbExchangeTemplate)
    Dialog:ShowDialog()
end

local function GetExchangeDatas(self)
    local tbExchangeDatas = {}
    local tbTemplates = BuildingExchangeDataTable:GetAllTemplates()
    for _, tbTemplate in pairs(tbTemplates) do
        local tbData = {}
        tbData.tbTemplate = tbTemplate
        tbData.OnExchangeButtonPressedDelegate = self.OnExchangeButtonPressedDelegate
        table.insert(tbExchangeDatas, tbData)
    end
    return tbExchangeDatas
end

function ULHomeExchange:Refresh()
    local tbDatas = GetExchangeDatas(self)
    self.ListHelper:SetData(tbDatas)
end

function ULHomeExchange:OnItemChanged()
    self:Refresh()
end

function ULHomeExchange:OnLoad()
    local pWidgetRef =self.pWidgetRef
    self.OnExchangeButtonPressedDelegate = LuaDelegateClass()

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmlistExchanges, {}, UIDef.UP_HOME_ITEM_EXCHANGE)
end

function ULHomeExchange:OnUnload()
    self.ListHelper:Uninit()
end

function ULHomeExchange:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnExchangeButtonPressedDelegate, OnExchangeButtonPressed, self)
end

return ULHomeExchange