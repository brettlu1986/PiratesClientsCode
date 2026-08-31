-----------------------------------------------------
--File Name    : UILobbyAwardItem.lua
--Author       : zhiyuan
--Create Time  : 2019-03-05
--Description  : 获得道具的UI
--tbOpenArgs   : 道具数据列表
-- tbOpenArgs = {tbItemDatas = {}}
-- local tbItemData = {}
-- tbItemData.nItemTemplateId = 1
-- tbItemData.nCount = 2
-- table.insert(tbOpenArgs.tbItemDatas, tbItemData)
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyAwardItem = luaclass("UILobbyAwardItem", WndBase)

local UIManager = require("UIManager")
local UIDef = require("UIDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")

UILobbyAwardItem.tbItemQueue = nil

UILobbyAwardItem.tbCurrentDatas = nil
UILobbyAwardItem.ListHelper = nil

UILobbyAwardItem.OwnerSub = nil

local function SetTitle(self)
    self.pWidgetRef.kmtxtTitle:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_AWARD_TITLE"))
end

local function PlayAnim(self)
	self:PlayAnimation("animAwardItem", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
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
    if self.tbItemQueue == nil or #(self.tbItemQueue) == 0 then
        UIManager:CloseWnd(UIDef.UI_LOBBY_AWARD_ITEM)
        if self.OwnerSub then
            local tbActiveSub = self.OwnerSub.Owner:GetActiveSub()
            if tbActiveSub and self.OwnerSub.nSubType == tbActiveSub.nSubType then
                self.OwnerSub:OnWndClose()
                -- self.OwnerSub.Owner:ReturnToPrevSub()
            end
        end
    else
        self.tbCurrentDatas = self.tbItemQueue[1]
        table.remove(self.tbItemQueue, 1)
        ShowCurrentData(self)
    end
end

local function OnPushAward(self, tbAwardDatas)
    for _, v in ipairs(tbAwardDatas) do
        table.insert(self.tbItemQueue, v.tbAwardDatas)
    end
end

function UILobbyAwardItem:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmListItem, nil, UIDef.UP_LOBBY_ITEM_SUB)
end

function UILobbyAwardItem:OnShow()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    local tbItemDatas = tbOpenArgs.tbItemDatas
    local tbItemQueue = tbOpenArgs.tbItemQueue
    if tbItemDatas == nil then
        error("Cannot find item to show! tbOpenArgs.tbItemDatas is nil!")
    end

    self.tbCurrentDatas = tbItemDatas
    if tbItemQueue ~= nil then
        self.tbItemQueue = tbItemQueue
    else
        self.tbItemQueue = {}
    end
    ShowCurrentData(self)
end

function UILobbyAwardItem:OnBindEvent(EventHelper)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCancelFullScreen.OnClicked, self, OnClickedCloseBtn)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnDone.OnClicked, self, OnClickedCloseBtn)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_PUSH_AWARD, self, OnPushAward)
end

function UILobbyAwardItem:OnDestroy()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

return UILobbyAwardItem
