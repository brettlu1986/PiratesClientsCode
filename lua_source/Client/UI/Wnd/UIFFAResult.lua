-----------------------------------------------------
--File Name    : UIFFAResult.lua
--Description  : FFA战斗结算主界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFAResult = luaclass("UIFFAResult", WndBase)

local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local AvatarDataTable = require("AvatarDataTable")
local HeadIconResDataTable = require("HeadIconResDataTable")
local L10N = require("L10N")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local BACK_WAIT_TIME = 100

local function SetInfo(self)
    local tbInfo = self.tbOpenArgs
    if not tbInfo then
        return
    end
    local nRank = tbInfo.nRank
    local nKillCount = tbInfo.nKillCount
    local nSurvivalTime = tbInfo.nSurvivalTime
    local nTotalPlayerCount = tbInfo.nPlayerCount
    local nApplyDamageToShip = tbInfo.nApplyDamageToShip == nil and 0 or tbInfo.nApplyDamageToShip
    local nApplyDamageToHuman = tbInfo.nApplyDamageToHuman == nil and 0 or tbInfo.nApplyDamageToHuman
    local nApplyCureToShip = tbInfo.nApplyCureToShip == nil and 0 or tbInfo.nApplyCureToShip
    local nApplyCureToHuman = tbInfo.nApplyCureToHuman == nil and 0 or tbInfo.nApplyCureToHuman
    local nSaveTeamateCount = tbInfo.nSaveTeamateCount == nil and 0 or tbInfo.nSaveTeamateCount
    log("UIFFAResult:SetInfo,nRank,nKillCount,nSurvivalTime,nTotalPlayerCount=",nRank,nKillCount,nSurvivalTime,nTotalPlayerCount)
    local pWidgetRef = self.pWidgetRef
    local SelfObj = GamePlayerSelfHelper:Get()
    local HumanTemplate = AvatarDataTable:GetTemplate(SelfObj.nDungeonHumanId)
    if not HumanTemplate then
        logerror("UIFFAResult:SetInfo,HumanTemplate is nil,templateid=", SelfObj:GetTemplateId())
        return
    end
    local szHeadIconPath = HeadIconResDataTable:GetResPath(HumanTemplate.nHeadIconId)
    if szHeadIconPath then
        local pIconObj = szHeadIconPath:load()
        if pIconObj then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgPlayerAvatarIcon, pIconObj)
        end
    end
    pWidgetRef.txtPlayerName:SetText(SelfObj:GetName())
    local l10Rank = UISetUtils.GetL10NTextByKey("FFA_RESULT_RANK")
    l10Rank = L10N:Format(l10Rank, nRank, nTotalPlayerCount)
    pWidgetRef.rtxtRank:SetText(l10Rank)

    local l10Detail = UISetUtils.GetL10NTextByKey("FFA_RESULT_DETAIL")
    l10Detail = L10N:Format(l10Detail, nRank, nKillCount)
    pWidgetRef.rtxtDetail:SetText(l10Detail)

    if nRank == 1 then
        pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_SUCCESS"))
    else
        pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_FAIL"))
    end

    local l10Summary = UISetUtils.GetL10NTextByKey("FFA_RESULT_SUMMARY")
    local nSurvivalMinute = math.floor(nSurvivalTime / 60)
    local nSurvivalSecond = nSurvivalTime % 60
    l10Summary = L10N:Format(l10Summary, nSurvivalMinute, nSurvivalSecond, nApplyDamageToShip, nApplyDamageToHuman, nApplyCureToShip, nApplyCureToHuman, nSaveTeamateCount)
    pWidgetRef.rtxtSummary:SetText(l10Summary)

    local l10Back = UISetUtils.GetL10NTextByKey("FFA_RESULT_BUTTON_BACK")
    pWidgetRef.cdtxtBack:SetTimerStart(l10Back, false, GlobalVariableSystem:GetLocalTime() + BACK_WAIT_TIME)
end

local function OnBackClicked(self)
    BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
end

function UIFFAResult:OnLoad()
    self.pWidgetRef.bTopWindow = false
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
end

function UIFFAResult:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnBackClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.cdtxtBack.OnCountDownFinished, self, OnBackClicked)

end

function UIFFAResult:OnShow()
    SetInfo(self)
end

return UIFFAResult