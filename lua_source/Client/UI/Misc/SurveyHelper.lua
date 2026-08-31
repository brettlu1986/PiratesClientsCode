-----------------------------------------------------
--File Name    : SurveyHelper.lua
--Author       : Edward J
--Create Time  : 2020-01-06
--Description  : 
-----------------------------------------------------
local GuideSystem           = require("GuideSystem")
local ActivityMiscIni       = require("ActivityMiscIni")
local ClientEventDef        = require("ClientEventDef")
local EventManager          = require("EventManager")
local UIUtils               = require("UIUtils")
local UISetUtils            = require("UISetUtils")
local Proto                 = require("ClientProtoNames")
local NetworkManager        = dynamic_require("NetworkManager")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local SaveGameDef           = require("SaveGameDef")
local SurveyHelper = {}

local TARGET_ENTER_BATTLE_COUNT     = ActivityMiscIni.tbSurvey.Target_Battle_Count
local LaunchURL                     = KismetSystemLibrary.LaunchURL

SurveyHelper.EBattleCountNotValid   = -1
SurveyHelper.ENotFinish             = 0
SurveyHelper.EAllFinish             = 1
SurveyHelper.bLogin                 = false
SurveyHelper.bAwardStatus           = nil
-----------------------------------------------------

function SurveyHelper.IsFirstInit()
    return SurveyHelper.bAwardStatus == nil
end

function SurveyHelper.GetAwardStatus()
    local Socket = NetworkManager:GetHubServerProxy()
	local c2s_GetSurvey = {}
	Socket:SendPacket(Proto.c2s_GetSurvey, c2s_GetSurvey)
end

function SurveyHelper.GetAward()
    local Socket = NetworkManager:GetHubServerProxy()
	local c2s_GetSurveyAward = {}
	Socket:SendPacket(Proto.c2s_GetSurveyAward, c2s_GetSurveyAward)
end

function SurveyHelper.SetLoginStatus(bValue)
    SurveyHelper.bLogin = bValue
end

function SurveyHelper.CheckBattleCount()
    local nEnterBattleCount = GuideSystem.nEnterBattleCount
    return nEnterBattleCount >= TARGET_ENTER_BATTLE_COUNT
end

function SurveyHelper.CheckFinishStatus()
    local bAwardStatus = SurveyHelper.bAwardStatus
    if bAwardStatus == nil then
        SurveyHelper.GetAwardStatus()
        return true
    else
        return bAwardStatus
    end
end

function SurveyHelper.SetFinishStatus(bStatus)
    SurveyHelper.bAwardStatus = bStatus
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_CLICK_SURVEY)
end

function SurveyHelper.GetSurveyStatus()
    if not SurveyHelper.CheckBattleCount() then
        return SurveyHelper.EBattleCountNotValid
    end
    if not SurveyHelper.CheckFinishStatus() then
        return SurveyHelper.ENotFinish
    end
    return SurveyHelper.EAllFinish
end

local function LaunchUrlWithPlayerId(szUrl)
    local nPlayerId = 0
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer then
        nPlayerId = tbPlayer.nPlayerId
    end
    local szFullUrl = string.format("%s/?openid=%s", szUrl, tostring(nPlayerId))
    LaunchURL(szFullUrl)
end

function SurveyHelper.LaunchQuestionURL()
    local szUrl = ActivityMiscIni.tbSurvey.QuestionUrl
    LaunchUrlWithPlayerId(szUrl)
end

function SurveyHelper.LaunchSurveyURL()
    local szUrl = ActivityMiscIni.tbSurvey.Url
    LaunchUrlWithPlayerId(szUrl)
    SurveyHelper.GetAward()
end

function SurveyHelper.ShowSurveyDialog()
    EventManager:OnFireEvent(ClientEventDef.EV_MATCHMAKING_FORCE_CANCLE)
    UIUtils.ShowDialog(UISetUtils.GetL10NTextByKey("UI_STATIC_SURVEY_TITLE"), UISetUtils.GetL10NTextByKey("UI_STATIC_SURVEY_CONTENT"),UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_OK"), SurveyHelper.LaunchSurveyURL, UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_CANCEL"))
    SurveyHelper.bLogin = false
end

function SurveyHelper.AutoPopSurveyDialog()
    if SurveyHelper.bLogin then
        EventManager:OnFireEvent(ClientEventDef.EV_MATCHMAKING_FORCE_CANCLE)
        UIUtils.ShowDialog(UISetUtils.GetL10NTextByKey("UI_STATIC_SURVEY_TITLE"), UISetUtils.GetL10NTextByKey("UI_STATIC_SURVEY_CONTENT"),UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_OK"), SurveyHelper.LaunchSurveyURL, UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_CANCEL"))
        SurveyHelper.bLogin = false
    end
end

--活动里的问卷 是否点击填写
function SurveyHelper.IsFillScheduleQuestion()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    return pSaveGameMgr:GetBoolData(SaveGameDef.FILL_QUESTION)
end

function SurveyHelper.SaveFillSchedule()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddBoolData(SaveGameDef.FILL_QUESTION, true)
    pSaveGameMgr:Save()
end

return SurveyHelper