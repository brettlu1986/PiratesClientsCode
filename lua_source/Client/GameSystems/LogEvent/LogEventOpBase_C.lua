local luaclass = require("luaclass")
local LogEventOpBase = require("LogEventOpBase")
local LogEventOpBase_C = luaclass("LogEventOpBase_C", LogEventOpBase)

local DataSDKHelper = require("DataSDKHelper")
local Analytics = require("ClientAnalyticsProtoNames")

function LogEventOpBase_C:LogEvent(szAnalytics, tbPacket)
    -- log("LogEvent Analytics Name = " .. tostring(szAnalytics))
    local szDataInfo = tbPacket.data_info
    -- log("LogEvent Log Data = " .. tostring(szDataInfo))
    if szAnalytics == Analytics.OnAccountLogin then
        DataSDKHelper.OnAccountLogin(szDataInfo)
    elseif szAnalytics == Analytics.OnAccountLogout then 
        DataSDKHelper.OnAccountLogout()
    elseif szAnalytics == Analytics.OnRoleLogin then
        DataSDKHelper.OnRoleLogin(szDataInfo)
    elseif szAnalytics == Analytics.OnRoleLogout then
        DataSDKHelper.OnRoleLogout()
    elseif szAnalytics == Analytics.OnRoleLevelUp then
        DataSDKHelper.OnRoleLevelUp(szDataInfo)
    elseif szAnalytics == Analytics.OnPayFinish then
        DataSDKHelper.OnPayFinish(szDataInfo)
    elseif szAnalytics == Analytics.OnEvent then
        local szEventId = tbPacket.event_id
        DataSDKHelper.OnEvent(szEventId, szDataInfo)
    elseif szAnalytics == Analytics.OnCustomEvent then
        DataSDKHelper.OnCustomEvent(szDataInfo)	
    elseif szAnalytics == Analytics.Ping then
        DataSDKHelper.Ping(szDataInfo)
    elseif szAnalytics == Analytics.OnMissionBegin then
        DataSDKHelper.OnMissionBegin(szDataInfo)
    elseif szAnalytics == Analytics.OnMissionSuccess then
        DataSDKHelper.OnMissionSuccess(szDataInfo)
    elseif szAnalytics == Analytics.OnMissionFail then
        DataSDKHelper.OnMissionFail(szDataInfo)
    elseif szAnalytics == Analytics.OnVirtualCurrencyGain then
        DataSDKHelper.OnVirtualCurrencyGain(szDataInfo)
    elseif szAnalytics == Analytics.OnVirtualCurrencyGainForPurchased then
        DataSDKHelper.OnVirtualCurrencyGainForPurchased(szDataInfo)
    elseif szAnalytics == Analytics.OnVirtualCurrencyConsume then
        DataSDKHelper.OnVirtualCurrencyConsume(szDataInfo)
    elseif szAnalytics == Analytics.OnItemGain then
        DataSDKHelper.OnItemGain(szDataInfo)
    elseif szAnalytics == Analytics.OnGameLoadResource then
        DataSDKHelper.OnGameLoadResource()
    elseif szAnalytics == Analytics.OnGameLoadConfig then
        DataSDKHelper.OnGameLoadConfig()
    elseif szAnalytics == Analytics.OnOpenAnnouncement then
        DataSDKHelper.OnOpenAnnouncement()
    elseif szAnalytics == Analytics.OnCloseAnnouncement then
        DataSDKHelper.OnCloseAnnouncement()
    elseif szAnalytics == Analytics.OnNewUserMission then
        DataSDKHelper.OnNewUserMission()
    elseif szAnalytics == Analytics.OnPrivateFunCodeUse then
        DataSDKHelper.OnPrivateFunCodeUse(szDataInfo)
    elseif szAnalytics == Analytics.OnPublicFunCodeUse then
        DataSDKHelper.OnPublicFunCodeUse(szDataInfo)
    end
end

return LogEventOpBase_C