local dkjson = require("dkjson")	
local ChannelSDKSystem = require("ChannelSDKSystem")

local LoginRequestHelper = {}

local SDKNAME = {
    XGSDK = "XGSDK",
    EGSDK = "seasungames",
    SGSDK = "SGSDK"
}

local APINAME = {
    DEVICEID = "LoginWithDeviceId",
    ACCOUNT  = "LoginWithAccount",
    ACTIVATE = "Activate",
    XGSDK    = "LoginWithXGSDK",
    EGSDK    = "LoginWithEGSDK",
    SGSDK    = "LoginWithSGSDK"
}

local function BuildRequestBody(fnUrlEncode, tbBody)
    local szBody = ""
    for k, v in pairs(tbBody) do
        if string.len(szBody) > 0 then
            szBody = string.format("%s&",szBody)
        end
        szBody = string.format("%s%s=%s", szBody, k, fnUrlEncode(v))
    end
    log("login request body: ", szBody)
    return szBody
end

local function GetAud(HydraClient)
    local szAud = ChannelSDKSystem:GetChannelID()
    log("aud is " .. tostring(szAud))
    if szAud == "" then
        szAud = HydraClient.GameId
    end
    return szAud
end

function LoginRequestHelper:LoginWithDeviceId(HydraClient, szDeviceId)
    local fnUrlEncode = HydraClient.UrlEncode
    local szAud = GetAud(HydraClient)
    local tbBody = {
        ["device_id"] = szDeviceId,
        ["aud"] = szAud,
        ["create"] = HydraClient.CreateIfNotFound and "true" or "false"
    }
    local szBody = BuildRequestBody(fnUrlEncode, tbBody)

    HydraClient:Login(APINAME.DEVICEID, szBody)
end

function LoginRequestHelper:LoginWithAccount(HydraClient, szUsername, szPassword)
    local fnUrlEncode = HydraClient.UrlEncode
    local szAud = GetAud(HydraClient)
    local tbBody = {
        ["username"] = szUsername,
        ["password"] = szPassword,
        ["aud"] = szAud,
        ["create"] = HydraClient.CreateIfNotFound and "true" or "false"
    }
    local szBody = BuildRequestBody(fnUrlEncode, tbBody)

    HydraClient:Login(APINAME.ACCOUNT, szBody)
end

function LoginRequestHelper:LoginWithActivationCode(HydraClient, szToken, szCode, szChannel)
    local fnUrlEncode = HydraClient.UrlEncode

    local tbBody = {
        ["activation_code"] = szCode,
        ["channel"] = szChannel,
    }
    local szBody = BuildRequestBody(fnUrlEncode, tbBody)

    HydraClient:LoginWithActivationCode(szToken, APINAME.ACTIVATE, szBody)
end

function LoginRequestHelper:LoginWithXGSdk(HydraClient, szAuthInfo)
    local fnUrlEncode = HydraClient.UrlEncode
    local szAud = GetAud(HydraClient)
    local tbBody = {
        ["auth_info"] = szAuthInfo,
        ["aud"] = szAud,
        ["create"] = HydraClient.CreateIfNotFound and "true" or "false"
    }
    local szBody = BuildRequestBody(fnUrlEncode, tbBody)

    HydraClient:Login(APINAME.XGSDK, szBody)
end

function LoginRequestHelper:LoginWithSGSdk(HydraClient, szUId, szToken)
    local szChannelId = ChannelSDKSystem:GetChannelID()
    local fnUrlEncode = HydraClient.UrlEncode
    local nChannelCode = tonumber(szChannelId)
    nChannelCode = nChannelCode == nil and 0 or nChannelCode
    local szAud = GetAud(HydraClient)
    local tbBody = {
        ["uid"] = szUId,
        ["aud"] = szAud,
        ["token"] = szToken,
        ["channel_id"] = nChannelCode,
        ["create"] = HydraClient.CreateIfNotFound and "true" or "false"
    }
    local szBody = BuildRequestBody(fnUrlEncode, tbBody)

    HydraClient:Login(APINAME.SGSDK, szBody)
end

function LoginRequestHelper:LoginWithEGSdk(HydraClient, szUserId, szAccessToken)
    local fnUrlEncode = HydraClient.UrlEncode
    local szAud = GetAud(HydraClient)
    local tbBody = {
        ["uid"] = szUserId,
        ["token"] = szAccessToken,
        ["aud"] = szAud,
        ["create"] = HydraClient.CreateIfNotFound and "true" or "false"
    }
    local szBody = BuildRequestBody(fnUrlEncode, tbBody)

    HydraClient:Login(APINAME.EGSDK, szBody)
end

function LoginRequestHelper:OnSdkLoginSuccess(HydraClient, szJsonData)
    local tbJsonData = dkjson.decode(szJsonData)
    if tbJsonData.name == SDKNAME.XGSDK then
        self:LoginWithXGSdk(HydraClient, tbJsonData.auth_info)
    elseif tbJsonData.name == SDKNAME.EGSDK then
        self:LoginWithEGSdk(HydraClient, tbJsonData.uid, tbJsonData.token)
    elseif tbJsonData.name == SDKNAME.SGSDK then
        self:LoginWithSGSdk(HydraClient, tbJsonData.uid, tbJsonData.token)
    else
        logerror("OnSdkLoginSuccess invalid sdk name ", tbJsonData.name)
    end
end

return LoginRequestHelper
