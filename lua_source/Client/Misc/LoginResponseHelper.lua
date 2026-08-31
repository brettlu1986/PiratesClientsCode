local UITextDef = require("UITextDef")
local ProcedureTool = require("ProcedureTool")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local dkjson = require("dkjson")	
local TimeUtil = require("TimeUtil")
local L10N = require("L10N")
local UIUtils = require("UIUtils")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

local LoginResponseHelper = {}
local RESPONSE_ANTIADDICTION = "AntiAddiction"
local RESPONSE_USERBANNED = "UserBanned"
local RESPONSE_NOTFOUND = "NotFound"
local RESPONSE_NOTACTIVATED = "NotActivated"
local RESPONSE_CODEINVALID = "CodeInvalid"
local RESPONSE_CODEALREADYUSED = "CodeAlreadyUsed"
local RESPONSE_CODEOVERTIME = "CodeExpired"

local SHOWLOADINGTYPE = {
    [RESPONSE_NOTACTIVATED] = true
} 

LoginResponseHelper.LOGIN_OP = {
    HYDRA_LOGIN_SUCCESS_HUB_NIL = 1,
    HYDRA_LOGIN_NOSUCCESS = 2,
    HYDRA_LOGIN_FAILED = 3,
    HYDRA_ACTIVATE_CODE_UI = 4,
    SDK_LOGIN_FAILED = 5,
    HUB_LOGIN_ERROR = 6,
    HUB_LOGIN_NEWPLAYER = 7,
    HUB_LOGIN_PLAYER_DATA = 8,
    HUB_LOGIN_CREATE_PLAYER = 9,
}

local function GetL10nErrorCode(nReturnCode)
    if nReturnCode ~= nil then
        return UITextDef.ANTIADDICTION_ERRORCODE[nReturnCode]
    end
end

-- local function TransferErrorCode(nReason)
--     return nReason
-- end

local function ShowErrorDialog(l10nText, bReturn)
    UIUtils.ShowErrorDialog("", l10nText, function()
        if bReturn then
            ProcedureTool:ReturnToStartGame()
        else
            UIManager:CloseWnd(UIDef.UI_ERROR_DIALOG, {bNoAnim=true})
        end
    end)
end

local function AntiaddictionProcess(nReturnCode, szMessage)
    if nReturnCode ~= nil then
        local l10nAntiAddictionError = GetL10nErrorCode(nReturnCode)
        if l10nAntiAddictionError ~= nil then
            ShowErrorDialog(l10nAntiAddictionError, false)
            return true
        end
    end
    if szMessage ~= nil then
        ShowErrorDialog(szMessage, false)
        return true
    end
    return false
end

local function BannedProcess(tbHydraResponseBody)
    local l10nText = UITextDef.USER_BANNED_LOGIN_FOREVER
    local szUntilTime = tbHydraResponseBody.error.data and tbHydraResponseBody.error.data["until"]
    if szUntilTime ~= nil then
        local szTime = TimeUtil.GetTimeFormatString(tonumber(szUntilTime), "%Y-%m-%d %H:%M")
        l10nText = L10N:Format(UITextDef.USER_BANNED_LOGIN, szTime)
    end
    UIUtils.ShowErrorDialog("", l10nText, function()
        UIManager:CloseWnd(UIDef.UI_ERROR_DIALOG, {bNoAnim=true})
    end)

    return true
end

local function ResponseErrorDialog(l10nText)
    UIUtils.ShowErrorDialog("", l10nText, function()
        UIManager:CloseWnd(UIDef.UI_ERROR_DIALOG, {bNoAnim=true})
    end)

    return true
end

local function NotActivatedProcess(token)
    UIManager:OpenWnd(UIDef.UI_ACTIVATION_CODE, {token = token})

    return true
end

-- 重连先只处理防沉迷，以后根据需求再添加
function LoginResponseHelper:Relogin(nReturnCode, szMessage)
    if nReturnCode ~= nil then
        local l10nAntiAddictionError = GetL10nErrorCode(nReturnCode)
        if l10nAntiAddictionError ~= nil then
            ShowErrorDialog(l10nAntiAddictionError, true)
            return true
        end
    end
    if szMessage ~= nil then
        ShowErrorDialog(szMessage, false)
        return true
    end

    return false
end

function LoginResponseHelper:SuccessProcess(HydraResponse)
    log("Login successful, entering map.");
    GamePlatformMiscLibrary.LogDebug("Login successful, entering map.")
    --self:HideUI()
    assert(GlobalVariableSystem.tbCurrentServerData ~= nil)
    GlobalVariableSystem:SetToken(HydraResponse.data.token, GlobalVariableSystem:GetLocalTime(), HydraResponse.data.expires_in)
    local szHubServerUrl = GlobalVariableSystem:GetLobbyServerAddress()
    if(szHubServerUrl == nil or szHubServerUrl == "") then
        self:HideLoadingDialog(self.LOGIN_OP.HYDRA_LOGIN_SUCCESS_HUB_NIL)
        error("Cannot get hub server url.")
        GamePlatformMiscLibrary.LogDebug("Cannot get hub server url.")
        return false
    else
        local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
        pChannelSdkManager:OnLoginSuccessfully(HydraResponse.data.user_data)
        GamePlatformMiscLibrary.LogDebug("Connect to hub server")
        return true
    end
end

function LoginResponseHelper:FailedProcess(HydraResponse, szHydraResponseBody)
    local FailedResponse = function()
        local errorMsg = "Login failed : " .. HydraResponse.code .. " " .. HydraResponse.error.type .. " " .. HydraResponse.error.message
        GamePlatformMiscLibrary.LogDebug(errorMsg)
        log(errorMsg)
        if not SHOWLOADINGTYPE[HydraResponse.error.type] then
            self:HideLoadingUI(self.LOGIN_OP.HYDRA_LOGIN_FAILED)
        end
        return errorMsg
    end  
	local errorMsg = FailedResponse()
    
    local bProcessed = false
    if HydraResponse.code == 403 then
        local tbHydraResponseBody = dkjson.decode(szHydraResponseBody)
        if HydraResponse.error.type == RESPONSE_ANTIADDICTION then
            bProcessed = AntiaddictionProcess(tbHydraResponseBody.error.code, HydraResponse.error.message) 
        elseif HydraResponse.error.type == RESPONSE_USERBANNED then
            bProcessed = BannedProcess(tbHydraResponseBody)
        elseif tbHydraResponseBody.error.type == RESPONSE_NOTACTIVATED then
            bProcessed = NotActivatedProcess(tbHydraResponseBody.error.token)
        end
    elseif HydraResponse.code == 400 then
        if HydraResponse.error.type == RESPONSE_NOTFOUND then
            bProcessed = ResponseErrorDialog(UITextDef.LOGIN_RESPONSE_NOTFOUND)
        elseif HydraResponse.error.type == RESPONSE_CODEINVALID then
            bProcessed = ResponseErrorDialog(UITextDef.ACTIVATION_CODE_INVALID)
        elseif HydraResponse.error.type == RESPONSE_CODEALREADYUSED then
            bProcessed = ResponseErrorDialog(UITextDef.ACTIVATION_CODE_ALREADYUSED)
        elseif HydraResponse.error.type == RESPONSE_CODEOVERTIME then
            bProcessed = ResponseErrorDialog(UITextDef.ACTIVATION_CODE_OVERTIME)
        end
    end
    
    return bProcessed, errorMsg
end

function LoginResponseHelper:HideLoadingUI(nOp)
    log("LoginResponseHelper:HideLoadingUI ", nOp)
    UIUtils.HideLoadingDialog()
end

-- function LoginResponseHelper:Disconnect(nReason)
--     local nReturnCode = TransferErrorCode(nReason)
--     local l10nAntiAddictionError = nReturnCode and GetL10nErrorCode(nReturnCode)
--     if l10nAntiAddictionError ~= nil then
--         ShowErrorDialog(l10nAntiAddictionError, true)
--         return true
--     end

--     return false
-- end

return LoginResponseHelper
