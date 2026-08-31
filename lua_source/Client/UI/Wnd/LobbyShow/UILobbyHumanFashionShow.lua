-----------------------------------------------------
--File Name    : UILobbyHumanFashionShow.lua
--Author       : WuJizhou
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyHumanFashionShow = luaclass("UILobbyHumanFashionShow", WndBase)

local LobbySystem = require("LobbySystem")
local ClientEventDef = require("ClientEventDef")

UILobbyHumanFashionShow.ulLobbyShowHumanFashion = nil
UILobbyHumanFashionShow.ulLobbyHumanItemLevelSwitcher = nil
UILobbyHumanFashionShow.ulLobbyHumanFashionItemInfo = nil


local function OnLevelChanged(self, nLevel)
    self.ulLobbyShowHumanFashion:ActivateArmorLevel(nLevel)
end

local function OnBackClicked(self)
    LobbySystem:ReturnToPrevSub()
end

function UILobbyHumanFashionShow:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBackClicked, self)
    local tbParam = self.tbOpenArgs
    self.ulLobbyShowHumanFashion = self.UILogicHelper:CreateUILogic("ULLobbyShowHumanFashion")
    self.ulLobbyShowHumanFashion:InitParams(tbParam)
    self.ulLobbyHumanItemLevelSwitcher = self.UILogicHelper:CreateUILogic("ULLobbyHumanItemLevelSwitcher")
    self.ulLobbyHumanFashionItemInfo = self.UILogicHelper:CreateUILogic("ULLobbyHumanFashionItemInfo")
    self.ulLobbyHumanItemLevelSwitcher:Enable(tbParam.bShowLevel)
end

function UILobbyHumanFashionShow:OnShow()
    self.ulLobbyHumanFashionItemInfo:Display(self.tbOpenArgs.nTargetTemplateId)
end


function UILobbyHumanFashionShow:OnUnload()
    self.ulLobbyShowHumanFashion = nil
end


function UILobbyHumanFashionShow:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_HUMAN_LEVEL_SWITCHED, self, OnLevelChanged)
end


return UILobbyHumanFashionShow