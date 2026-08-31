local luaclass              = require("luaclass")
local WndBase               = require("WndBase")
local UILobbyFriendBlackList= luaclass("UILobbyFriendBlackList", WndBase)
-- local FriendSystem          = require("FriendSystem")
local ClientEventDef        = require("ClientEventDef")
local SelfVerticalListHelper= require("SelfVerticalListHelper")

UILobbyFriendBlackList.pbDialogFrame = nil
UILobbyFriendBlackList.tbListHelper  = nil

local function OnRefresh(self)
    local tbDatas = {}--FriendSystem:GetComponent():GetBlackList()
    self.tbListHelper:SetData(tbDatas)
end

local function OnRefreshBlackList(self)
    OnRefresh(self)
end

local function OnClickClose(self)
    self:CloseSelf()
end

function UILobbyFriendBlackList:OnLoad()    
    local pWidgetRef = self.pWidgetRef

    self.pbDialogFrame = self.PrefabHelper:BindPrefab(pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetDialogClosedCallback(OnClickClose, self)
    self.tbListHelper:Init(self, pWidgetRef.klistItem)
end

function UILobbyFriendBlackList:OnCreate()
    self.tbListHelper = SelfVerticalListHelper()
end

function UILobbyFriendBlackList:OnShow()
    OnRefresh(self)
end

function UILobbyFriendBlackList:OnDestroy()
    self.pbDialogFrame = nil
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UILobbyFriendBlackList:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_BLACK_LIST, self, OnRefreshBlackList)
end

return UILobbyFriendBlackList
