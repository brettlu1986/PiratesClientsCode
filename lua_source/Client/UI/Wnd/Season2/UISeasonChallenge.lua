-----------------------------------------------------
--File Name    : UISeasonChallenge.lua
--Description  : 赛季任务界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonChallenge = luaclass("UISeasonChallenge", WndBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")


UISeasonChallenge.pbWindowFrame = nil
UISeasonChallenge.ulSeasonChallenge = nil
-------------------------------------------------------------------------------------------------------
local function OnClickedBack(self)
    self:CloseSelf()
    if self.tbOpenArgs.szFrom == nil then
        UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEPASS)   
    elseif self.tbOpenArgs.szFrom ~= "LobbyMain" then
        UIUtils.BottomMenuHide(false)
        if self.tbOpenArgs.tbUINames ~= nil then
            LobbySystem:Activate(LobbySubTypeDef.MAIN, {tbUINames = self.tbOpenArgs.tbUINames, nId = self.tbOpenArgs.nId, szFrom = UIDef.UI_SCHEDULE_CHEST_POP}) 
        else
            UIUtils.BottomMenuSelect(1, true)
            UIManager:OpenWnd(self.tbOpenArgs.szFrom, {szFrom = UIDef.UI_SEASON_CHALLENGE, nId = self.tbOpenArgs.nId})
        end
    end 
end

function UISeasonChallenge:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulSeasonChallenge = UILogicHelper:CreateUILogic("ULSeasonChallenge")

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnClickedBack, self)
end

function UISeasonChallenge:OnUnload()
end

function UISeasonChallenge:OnBindEvent(EventHelper)
end

function UISeasonChallenge:OnShow()
    -- UIUtils.BottomMenuHide(true)
    log("UISeasonChallenge:OnShow")
    self.ulSeasonChallenge:Activate(self.tbOpenArgs.tbExtendData)
    self:PlayAnimation("anim_SeasonBattlePass_WarriorIn", 0, 1, EUMGSequencePlayMode.Forward, 1)

    log("UISeasonChallenge:OnShow end")

    if self.tbOpenArgs.szFrom ~= nil then
        UIUtils.BottomMenuHide(true)
    end
end

function UISeasonChallenge:OnHide()
    -- UIUtils.BottomMenuHide(false)
    self.ulSeasonChallenge:Deactivate()
end

return UISeasonChallenge