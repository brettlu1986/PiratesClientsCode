-----------------------------------------------------
--File Name    : UILobbyLevelUpAwardItem.lua
--Author       : zhiyuan
--Create Time  : 2020-02-20
--Description  : 玩家升级获得道具的UI
--tbOpenArgs   : 道具数据列表
-- tbOpenArgs = {tbItemDatas = {}}
-- local tbItemData = {}
-- tbItemData.nItemTemplateId = 1
-- tbItemData.nCount = 2
-- table.insert(tbOpenArgs.tbItemDatas, tbItemData)
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyLevelUpAwardItem = luaclass("UILobbyLevelUpAwardItem", WndBase)

local UIManager = require("UIManager")
local UIDef = require("UIDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UISetUtils = require("UISetUtils")

UILobbyLevelUpAwardItem.tbCurrentDatas = nil
UILobbyLevelUpAwardItem.ListHelper = nil

local function SetTitle(self)
    self.pWidgetRef.kmtxtTitle:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_LEVEL_AWARD_TITLE"))
end

local function PlayAnim(self)
	self:PlayAnimation("animAwarditem", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        -- 为了让引导在此处抛出动画结束时的事件
    end)
end

local function ShowData(self)
    local Visible = ESlateVisibility.Visible
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.kmListItem:SetVisibility(Visible)

    local tbItemDatas = {}
    for _, v in ipairs(self.tbCurrentDatas) do
        table.insert(tbItemDatas, {nItemTemplateId = v.nItemTemplateId, nCount = v.nCount, bCanClick = true})
    end
    self.ListHelper:SetData(tbItemDatas)
end

local function ShowCurrentData(self)
    local tbItemDatas = self.tbCurrentDatas
    local nItemCount = #tbItemDatas
    if nItemCount == 0 then
        error("Cannot find item to show! nItemCount is 0!")
    end
    ShowData(self)

    SetTitle(self)
    PlayAnim(self)
end

local function OnClickedCloseBtn(self)
    UIManager:CloseWnd(UIDef.UI_LOBBY_LEVEL_UP_AWARD_ITEM)
end

function UILobbyLevelUpAwardItem:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmListItem, nil, UIDef.UP_LOBBY_ITEM_SUB)
end

function UILobbyLevelUpAwardItem:OnShow()
    local tbOpenArgs = self.tbOpenArgs
    local tbItemDatas = tbOpenArgs.tbItemDatas
    if tbItemDatas == nil then
        error("Cannot find item to show! tbOpenArgs.tbItemDatas is nil!")
    end

    self.tbCurrentDatas = tbItemDatas
    ShowCurrentData(self)
end

function UILobbyLevelUpAwardItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCancelFullScreen.OnClicked, self, OnClickedCloseBtn)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnDone.OnClicked, self, OnClickedCloseBtn)
end

function UILobbyLevelUpAwardItem:OnDestroy()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

return UILobbyLevelUpAwardItem
