local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFASetting = luaclass("UPFFASetting", PrefabBase)

local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIDialogQuitDungeonHelper = require("UIDialogQuitDungeonHelper")
local GMSystem = dynamic_require("GMSystem")
local NetworkManager = dynamic_require("NetworkManager")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local function OnClickedBtnExitFFA(self)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        local tbGameState = BattleGameModeSystem:GetGameState()
        local nQuitDungeonDialogType = tbGameState.rGameStateBaseInfo.nQuitDungeonType
        local bCanQuit = tbGameState.rGameStateBaseInfo.bCanQuit

        if bCanQuit then
            local szTitle = UIDialogQuitDungeonHelper:GetDungeonQuitDialogTitle(nQuitDungeonDialogType)
            local szMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogMessage(nQuitDungeonDialogType)
            if szTitle ~= nil and szMessage ~= nil then
                local funQuit = function()
                    BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
                end
                local funCancel = function()
                    UIManager:CloseWnd(UIDef.UI_DIALOG_BOARD)
                end
                UIUtils.ShowChoiceDialog(szTitle, szMessage, funQuit, funCancel)
            else
                logwarning("UIBattleSettings:OnClickedBtnExitDungeon failed. nQuitDungeonDialogType:", nQuitDungeonDialogType, ". szTitle:", szTitle, "; szMessage:", szMessage, ". Please override BattleGameMode:GetQuitDungeonDialogType function")
            end
        else
            local szLimitMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogLimitMessage(nQuitDungeonDialogType)
            if szLimitMessage then
                UIUtils.ShowToast(szLimitMessage)
            else
                logwarning("UIBattleSettings:OnClickedBtnExitDungeon Cannot quit. But missing limit message. nQuitDungeonDialogType", nQuitDungeonDialogType)
            end
        end
    else
        local HubServerProxy = NetworkManager:GetHubServerProxy()
        HubServerProxy:Disconnect()
    end
end

local function OnDoubleFireCheckStateChanged(self, bIsChecked)
    GlobalVariableSystem.bDoubleFire = bIsChecked
end

local function OnClickedBtnAddBot(self)
    GMSystem:Exec("dm createsquad 80 2")
end

local function OnClickedBtnChoosePoint(self)
    GMSystem:Exec("dm setboolvalue SkipFFAWaitTime true")
end

function UPFFASetting:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAddBot.OnClicked, self, OnClickedBtnAddBot)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChoosePoint.OnClicked, self, OnClickedBtnChoosePoint)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnExitFFA.OnClicked, self, OnClickedBtnExitFFA)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkDoubleFire.OnCheckStateChanged, self, OnDoubleFireCheckStateChanged)
end

return UPFFASetting
