local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIRoseSelectFriend = luaclass("UIRoseSelectFriend", WndBase)

local SelfVerticalListHelper= require("SelfVerticalListHelper")
local FriendSystem = require("FriendSystem")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local UIUtils = require("UIUtils")

UIRoseSelectFriend.pbDialogFrame = nil
UIRoseSelectFriend.tbListHelper  = nil
UIRoseSelectFriend.tbItem = nil
UIRoseSelectFriend.tbFriendsInfo = nil

function UIRoseSelectFriend:OnLoad()

    self.tbItem = self.tbOpenArgs.tbItem
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetDialogClosedCallback(self.CloseSelf, self)
    self.pbDialogFrame:SetCloseButtonVisible(true)

    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.klistItem)
    local Component = FriendSystem:GetComponent()
    self.tbFriendsInfo = Component:GetFriends()
    if self.tbFriendsInfo == nil or #self.tbFriendsInfo == 0 then 
        return
    end
    self.tbListHelper:SetData(self.tbFriendsInfo)
end

function UIRoseSelectFriend:OnShow()
end

function UIRoseSelectFriend:OnDestroy()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

local function OnClickSearch(self)
    if self.tbFriendsInfo == nil or #self.tbFriendsInfo == 0 then 
        return
    end
    local szName = self.pWidgetRef.txtSearchText:GetText()
    szName = L10N:ToString(szName)
    local nId = tonumber(szName)

    local tbFoundData = nil
    for _, v in pairs(self.tbFriendsInfo) do 
        tbFoundData = {}  
        local tbSummary = v.player_summary
        if (nId ~= nil and nId == tbSummary.id) or (szName == tbSummary.name) then  
            table.insert(tbFoundData, v)
            break
        end
    end
    if not tbFoundData then
        UIUtils.ShowToast(UITextDef.FRIEND_NOT_FOUND)
    else
        self.tbListHelper:SetData(tbFoundData)
    end
end

function UIRoseSelectFriend:OnBindEvent()
    local pWidgetRef = self.pWidgetRef
    self.EventHelper:RegisterCppDelegate(pWidgetRef.btnSearch.OnClicked, self, OnClickSearch)
end


return UIRoseSelectFriend
