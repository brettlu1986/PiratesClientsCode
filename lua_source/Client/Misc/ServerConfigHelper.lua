local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HttpHelper = require("HttpHelper")
local Json = require("dkjson")
local DelayTimer = require("DelayTimer")
local IAPSystem = require("IAPSystem")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local L10N = require("L10N")
local StringUtil = require("StringUtil")
local GPerfSystem = require("GPerfSystem")
local GMOpenModeDef = require("GMOpenModeDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local LogReportSystem = dynamic_require("LogReportSystem")

local ServerConfigHelper = {}

local ERROR_CODE = 1

local szConfigUrl = nil
local tbRequestConfigTimer = nil
local tbConfigCompleteFunc = nil
-- 拿不到configjson就用这个默认的
local tbDefaultConfig =
{
    dev_mode = false,
    ios_in_review = false,
    disable_iap = false,
    gm_mode = "double_click",
    log_mode = "automatic"
}

local RequestConfigFile = nil

local function ShowRetryDialog()
    log("Failed to obtain server config, retry")
    local l10nText = L10N:Format(UITextDef.FAILED_OBTAIN_SERVER_INFO, ERROR_CODE)
    UIUtils.ShowErrorDialog("", l10nText, function()
        UIManager:CloseWnd(UIDef.UI_ERROR_DIALOG, {bNoAnim=true})
        if not tbRequestConfigTimer then
            tbRequestConfigTimer =  DelayTimer:RunNextTick(function()
                tbRequestConfigTimer = nil
                RequestConfigFile()
            end)
        end
    end)
end

local function ParseIAPConfig(tbConfig)
    local bIAPEnabled = not tbConfig.disable_iap
    local szIAPUrl = tbConfig.iap_url
    IAPSystem:SetIAPEnabled(bIAPEnabled)
    IAPSystem:SetIAPUrl(szIAPUrl)
end

local function ParseCandidateAvatarSexConfig(tbConfig)
    local szConfig = tbConfig.avatar
    GlobalVariableSystem:SetAvatarSexConfig(szConfig)
end
local function ParseGPerfConfig(tbConfig)
    local bEnable = tbConfig.enable_gperf
    local szUrl = tbConfig.gperf_url
    GPerfSystem:Enable(bEnable)

    local tbUrl = StringUtil.Split(szUrl, "//")
    GPerfSystem:SetUrl(tbUrl[1], tbUrl[2])

    local szLogUploadingMode = tbConfig.log_mode
    GPerfSystem:SetLogUploadingModeByString(szLogUploadingMode)
end

local function SetVersion()
    local bUseNewProcedure =  ExtendBlueprintFunctions.GetGameConfigBool("/Script/EngineExt.EngineExtSetting", "UseNewHotUpdateProcedure", false)
    log("ServerConfigHelper:SetVersion, bUseNewProcedure = ", bUseNewProcedure)
    if bUseNewProcedure then
        GlobalVariableSystem:SetVersion(HotUpdateProcedure.GetFullVersion())
        GlobalVariableSystem:SetAppVersion(HotUpdateProcedure.GetAppVersion())
        GlobalVariableSystem:SetResVersion(HotUpdateProcedure.GetResVersion())
    else
        GlobalVariableSystem:SetVersion(UpdateProcedure.GetFullVersion())
        GlobalVariableSystem:SetAppVersion(UpdateProcedure.GetAppVersion())
        GlobalVariableSystem:SetResVersion(UpdateProcedure.GetResVersion())
    end
end

local function SetUrl()
    GlobalVariableSystem:SetPatchUrl(UrlSettings.GetPatchUrl())
    GlobalVariableSystem:SetHelpUrl(UrlSettings.GetHelpUrl())
    GlobalVariableSystem:SetAnnouncementUrl(UrlSettings.GetAnnouncementUrl())
    GlobalVariableSystem:SetServerListUrl(UrlSettings.GetServerListUrl())
end

local function ParseConfigFile(tbConfig)
    local bDevMode = tbConfig.dev_mode
    local bIosInReview = tbConfig.ios_in_review
    local szGMOpenMode = tbConfig.gm_mode
    local bGuideUIMode = tbConfig.guide_ui_mode
    local bEnableLogReport = tbConfig.enable_log_report
    if bIosInReview == nil then
        bIosInReview = false
    end
    local BaseUtil = require("BaseUtil")
    BaseUtil:PrintTable(tbConfig)
    GlobalVariableSystem:SetDevMode(bDevMode)
    GlobalVariableSystem:SetIosReviewMode(bIosInReview)
    GlobalVariableSystem:SetGMOpenMode(GMOpenModeDef.TransformByString(szGMOpenMode))
    log("Parse config file bGuideUIMode = " .. tostring(bGuideUIMode))
    GlobalVariableSystem:SetGuideSkipCtrl(bGuideUIMode)
    GlobalVariableSystem.bQuickBattleLoading = bIosInReview
    if bEnableLogReport ~= nil then
        LogReportSystem:SetEnabled(bEnableLogReport)
    end
    ParseIAPConfig(tbConfig)
    ParseCandidateAvatarSexConfig(tbConfig)
    ParseGPerfConfig(tbConfig)
    SetUrl()
    log("ServerConfigHelper complete")
    if tbConfigCompleteFunc then
        tbConfigCompleteFunc()
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_UI_MODE)
end

RequestConfigFile = function()
    local bRet = HttpHelper:SendGetRequest(szConfigUrl, function(nRetCode, szContent)
        log("ServerConfigHelper request config ", nRetCode, HttpHelper.HttpResponseCodes.OK)
        if nRetCode == HttpHelper.HttpResponseCodes.OK then
            local tbConfig = Json.decode(szContent)
            ParseConfigFile(tbConfig)
        else
            ShowRetryDialog()
        end
    end)
    if not bRet then
        ShowRetryDialog()
    end
end

function ServerConfigHelper.RequestConfig(tbCompleteFunc)
    tbConfigCompleteFunc = tbCompleteFunc
    szConfigUrl = UrlSettings.GetConfigUrl()
    if(szConfigUrl and szConfigUrl ~= '') then
        RequestConfigFile()
    else
        szConfigUrl = nil
    end
    log("ConfigURL is ", szConfigUrl)
    if(not szConfigUrl)then
        ParseConfigFile(tbDefaultConfig)
    end
    SetUrl()
    SetVersion()
end

function ServerConfigHelper.ClearTimer()
    if tbRequestConfigTimer then
        DelayTimer:ClearTimer(tbRequestConfigTimer)
        tbRequestConfigTimer = nil
    end
end

return ServerConfigHelper
