local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_VersionCheck = luaclass("Procedure_VersionCheck", ProcedureBase)

local GlobalVariableSystem = require("GlobalVariableSystem_C")
local HttpHelper = require("HttpHelper")
local ProcedureManager = require("ProcedureManager")
local ProcedureTool = require("ProcedureTool")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")

Procedure_VersionCheck.nReturnCode = nil
Procedure_VersionCheck.szUpdateInfo = nil


local function ShowRetryDialog(self)
    -- 弹出重试界面
    log("Procedure_VersionCheck ShowRetryDialog")
    local l10nMessage = UISetUtils.GetL10NTextByKey("DIALOG_MESSAGE_DOWNLOAD_FIALED")
    local l10nButtonText = UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_RETRY")
    UIUtils.ShowDialog(UITextDef.L10N_INFORMATION_TIP, l10nMessage, nil, nil, l10nButtonText, function()
        ProcedureTool:EnterVersionCheck(nil, true)
    end, false)
end

local function ShowNoWifiDownloadDialog(self)
    -- 弹出无wifi下载提示
    log("Procedure_VersionCheck ShowNoWifiDownloadDialog")
    local l10nMessage = UISetUtils.GetL10NTextByKey("DIALOG_MESSAGE_NO_WIFI")
    local l10nOkButtonText = UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_OK")
    local l10nCancelButtonText = UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_CANCEL")
    UIUtils.ShowDialog(UITextDef.L10N_INFORMATION_TIP, l10nMessage, l10nOkButtonText, 
        function() 
            local tbParam = {}
            tbParam.szUpdateInfo = self.szUpdateInfo
            ProcedureTool:EnterUpdate(tbParam, true)
        end, 
        l10nCancelButtonText, 
        function()
            -- 退出游戏
            log("Procedure_VersionCheck request exit game")
            local GameInstance = GameplayStatics.GetGameInstance(GWorld)
            GameInstance:AppExit()            
        end)
end

local function ShowGotoAppStoreDialog(self)
    -- 弹出需去商店重新下载界面
    -- TODO...
    log("Procedure_VersionCheck ShowGotoAppStoreDialog")
end

local function ProcessUpdateInfo(self, nRetCode, szUpdateInfo)
    log("Procedure_VersionCheck ProcessUpdateInfo")
    if nRetCode == HttpHelper.HttpResponseCodes.OK then
        local nUpdateCode, _szDataSize = UpdateProcedure.VerifyUpdateInfo(szUpdateInfo)
        if(nUpdateCode == EUpdateReturnCode.NoNeedToUpdate) then
            -- 不需要更新的话直接进入serverlist
            log("Procedure_VersionCheck no need to update, enter server list")
            self:Complete(ProcedureManager.Procedure_ServerList)
        elseif(nUpdateCode == EUpdateReturnCode.NeedUpdate) then
            -- 可以更新，判是否wifi环境
            if(FileDownloader:HasActiveWiFiConnection()) then
                -- 直接更
                log("Procedure_VersionCheck enter procedure update")
                local tbParam = {}
                tbParam.szUpdateInfo = szUpdateInfo
                self:Complete(ProcedureManager.Procedure_Update, tbParam)
            else
                ShowNoWifiDownloadDialog(self)
            end
        elseif(nUpdateCode == EUpdateReturnCode.BaseVersionChanged) then
            -- 大版本号变化，需要去商店重新下载
            ShowGotoAppStoreDialog(self)
        elseif(nUpdateCode == EUpdateReturnCode.UpdateInfoParseFailed) then
            -- Parse failed
            logwarning("Procedure_VersionCheck parse json failed, retry")
            ShowRetryDialog(self)
        else
            logerror("Procedure_VersionCheck response failed, unknwon code", nUpdateCode)
        end
    else
        ShowRetryDialog(self)
    end
end

local function SendRequest(self)
    local szURL = GlobalVariableSystem.szResourceServerURL
    if(szURL == nil or szURL == "") then
        logerror("Procedure_VersionCheck url invalid")
        return false
    end
    local bRet = HttpHelper:SendGetRequest(GlobalVariableSystem.szResourceServerURL, function(nRetCode, szContent)
        log("Procedure_VersionCheck recv response", nRetCode, szContent)
        self.nReturnCode = nRetCode
        self.szUpdateInfo = szContent
        ProcessUpdateInfo(self, nRetCode, szContent)
    end)
    log("Procedure_VersionCheck Sendrequest", bRet)
    return bRet
end

function Procedure_VersionCheck:Begin()
    Procedure_VersionCheck.super.Begin(self)

    if(not SendRequest(self)) then
        ShowRetryDialog(self)
        return
    end
end

function Procedure_VersionCheck:End()
    Procedure_VersionCheck.super.End(self)
end


return Procedure_VersionCheck
