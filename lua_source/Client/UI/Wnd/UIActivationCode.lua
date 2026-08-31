local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIActivationCode = luaclass("UIActivationCode", WndBase)
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ChannelSDKSystem = require("ChannelSDKSystem")
local UIDef = require("UIDef")
local L10N = require("L10N")
local LoginResponseHelper = require("LoginResponseHelper")
local LoginRequestHelper = require("LoginRequestHelper")

UIActivationCode.pbDialogFrame = nil

local function trim(input)
    return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
end

local function OnClickOk(self)
    local txtCode = self.pWidgetRef.txtCode
    local szCode = L10N:ToString(txtCode:GetText())
    if string.len(szCode) <= 0 then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("ACTIVATION_CODE_INVALID"))
        return
    end
    local HydraClient = ClientShell.GetClient(GWorld):GetHydraClient()
    local szChannel = ChannelSDKSystem:GetChannelID()
    if string.len( szChannel ) == 0 then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("ACTIVATION_CODE_CHANNEL_BLANK"))
        return
    end
    szCode = string.upper( szCode )
    szCode = trim(szCode)
    local szToken = "Bearer " .. self.tbOpenArgs.token
    log(string.format("login with activation code: token = %s, code = %s, channel = %s ", szToken, szCode, szChannel))
    LoginRequestHelper:LoginWithActivationCode(HydraClient, szToken, szCode, szChannel)
end

local function OnClickClose(self)
	LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HYDRA_ACTIVATE_CODE_UI)
    self:CloseSelf()
end

function UIActivationCode:OnShow()
    self.pbDialogFrame:SetPositiveButtonCallback(OnClickOk, self)
    self.pbDialogFrame:SetDialogClosedCallback(OnClickClose, self)
end

function UIActivationCode:OnLoad()
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame, UIDef.UP_DIALOG_FRAME)
end

return UIActivationCode