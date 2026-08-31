-----------------------------------------------------
--File Name    : UILobbyHumanWeaponShow.lua
--Author       : WuJizhou
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyHumanWeaponShow = luaclass("UILobbyHumanWeaponShow", WndBase)

local LobbySystem = require("LobbySystem")
local ClientEventDef = require("ClientEventDef")

UILobbyHumanWeaponShow.ulLobbyShowHumanWeaponFashion = nil
UILobbyHumanWeaponShow.ulLobbyHumanItemLevelSwitcher = nil
UILobbyHumanWeaponShow.ulLobbyHumanWeaponFashionItemInfo = nil


local function OnLevelChanged(self, nLevel)
    self.ulLobbyShowHumanWeaponFashion:ActivateLevel(nLevel)
end

local function OnBackClicked(self)
    LobbySystem:ReturnToPrevSub()
end

function UILobbyHumanWeaponShow:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBackClicked, self)
    local tbParam = self.tbOpenArgs
    self.ulLobbyShowHumanWeaponFashion = self.UILogicHelper:CreateUILogic("ULLobbyShowHumanWeaponFashion")
    self.ulLobbyShowHumanWeaponFashion:InitParams(tbParam)
    self.ulLobbyHumanItemLevelSwitcher = self.UILogicHelper:CreateUILogic("ULLobbyHumanItemLevelSwitcher")
    self.ulLobbyHumanWeaponFashionItemInfo = self.UILogicHelper:CreateUILogic("ULLobbyHumanWeaponFashionItemInfo")
    self.ulLobbyHumanItemLevelSwitcher:Enable(tbParam.bShowLevel)
end

function UILobbyHumanWeaponShow:OnShow()
    self.ulLobbyHumanWeaponFashionItemInfo:Display(self.tbOpenArgs.nItemTemplateId)
end


function UILobbyHumanWeaponShow:OnUnload()
    self.ulLobbyShowHumanWeaponFashion = nil
end


function UILobbyHumanWeaponShow:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_HUMAN_LEVEL_SWITCHED, self, OnLevelChanged)
end


return UILobbyHumanWeaponShow