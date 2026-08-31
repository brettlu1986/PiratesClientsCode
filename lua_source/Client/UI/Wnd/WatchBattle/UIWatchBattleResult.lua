--这里一定是原始队伍内的观战
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIWatchBattleResult = luaclass("UIWatchBattleResult", WndBase)

local PlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local Proto = require("DungeonCommonProtoNames")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")
local L10N = require("L10N")
local UIUtils = require("UIUtils")
local UIDef = require("UIDef")
local UITextDef = require("UITextDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")

local EState = Proto.TeamInfo_EState
local COUNT_DOWN_TIME = 10
UIWatchBattleResult.nTeamSurviveCount = 0
UIWatchBattleResult.tbTeamInfo = nil

--看当前队伍还有多少存活的
local function OnFFATeamInfoChanged(self)
    local tbPlayer = PlayerSelfHelper:Get()
    local nSurviveCount = 0

    local tbTeamInfo = TeamWatchClientHelper.GetOriginalTeamInfo()
    if tbTeamInfo then
        local nPlayerId = tbPlayer:GetServerInstanceId()
        self.tbTeamInfo = tbTeamInfo
        for k, v in ipairs(self.tbTeamInfo) do
            if v.nInstanceId ~= nPlayerId and v.nState ~= EState.DEAD
                    and v.nState ~= EState.ADDITIONALSUCCESS then
                nSurviveCount = nSurviveCount + 1
            end
        end
    end
    self.nTeamSurviveCount = nSurviveCount

    local pWidget = self.pWidgetRef
    local l10nSurvive = L10N:Format(UITextDef.FFA_TEAM_SURVIVE_NUM, nSurviveCount)
    pWidget.rtxtRank:SetText(L10N:ToString(l10nSurvive))

    if nSurviveCount == 0 then
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.btnWatchMate:SetIsEnabled(false)
        local l10nStr = L10N:Format(UITextDef.FFA_WATCH_MATE_COUNTDOWN, 0)
        pWidgetRef.txtCountDown:SetText(L10N:ToString(l10nStr))
    end
end

local function InitTeamSurvive(self)
    OnFFATeamInfoChanged(self)
end

local function OnWatchTeamBattleClick(self)
    local pFirstTeammate = TeamWatchClientHelper.GetValidOriginalTeammateInfo()
    if pFirstTeammate then
        UIUtils.ShowWaitingPacket()
        self.EventHelper:FireEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_MATE, pFirstTeammate.nInstanceId)
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, true)
        local l10nTip2 = UITextDef.NO_VALID_WATCH_MATE
        UIUtils.ShowToast(L10N:ToString(l10nTip2))
    end
end

local function OnShowWatchTeammateView(self, tbMateObj)
    UIUtils.HideWaitingPacket()
    UIManager:PushState(UIStateDef.StateName.UI_WATCH_BATTLE_STATE, { tbMateObj = tbMateObj }, true, true)
end

local function OnWatchMatCountDownFinish(self)
    OnWatchTeamBattleClick(self)
end

local function OnExitGame(self)
    local bTeamDead = self.nTeamSurviveCount == 0
    self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, bTeamDead)
end

function UIWatchBattleResult:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
end

function UIWatchBattleResult:OnEnter()
    --init ui content
    InitTeamSurvive(self)
end

function UIWatchBattleResult:OnShow()
    local pWidget = self.pWidgetRef
    local l10nCountDown = UITextDef.FFA_WATCH_MATE_COUNTDOWN
    pWidget.txtCountDown:SetTimerStart(L10N:ToString(l10nCountDown),false, GlobalVariableSystem:GetLocalTime() + COUNT_DOWN_TIME)

    local l10nText = UITextDef.FFA_WATCH_BATTLE_DEFAULT_TEXT
    if self.tbOpenArgs.bAdditionSuccess then
        l10nText = UITextDef.FFA_WATCH_BATTLE_ADDITIONAL_SUCCESS
    end
    pWidget.txtResult:SetText(L10N:ToString(l10nText))
end

function UIWatchBattleResult:OnHide()
    UIManager:CloseWnd(UIDef.UI_SPECIAL_TOAST_BOARD)
end

function UIWatchBattleResult:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnWatchMate.OnClicked, self, OnWatchTeamBattleClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnExit.OnClicked, self, OnExitGame)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtCountDown.OnCountDownFinished, self, OnWatchMatCountDownFinish)

    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamInfoChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnShowWatchTeammateView)

end

return UIWatchBattleResult