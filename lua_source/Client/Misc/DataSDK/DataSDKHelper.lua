-----------------------------------------------------
--File Name    : DataSDKHelper.lua
--Author       : Edward J
--Create Time  : 2020-07-14
--Description  : 蓝鲸sdk接口暴露
-----------------------------------------------------
local dkjson                    = require("dkjson")
-- local ChannelSDKSystem          = require("ChannelSDKSystem")

local DataSDKHelper = {}
local DataSDKManager        = ClientShell.GetClient(GWorld):GetDataSdkManager()
--账号登录
local function ValiedValuePaser(val)
    if type(val) == "string" then
        return not val and "" or val
    elseif type(val) == "number" then
        return not val and 0 or val
    else
        return nil
    end
end

function DataSDKHelper.OnAccountLogin(szAccountId)
    DataSDKManager:OnAccountLogin(szAccountId)
end
--账号退出
function DataSDKHelper.OnAccountLogout()												
    DataSDKManager:OnAccountLogout()
end
--角色登录

function DataSDKHelper.CreateRoleInfo(szRoleId, szRoleName, szRoleLevel, szRoleVipLevel, szRoleType, szServerId, szServerName, szZoneId, szZoneName, szPartyName, szGender)							    
    local tbRoleInfo = {}
    tbRoleInfo.roleid           = ValiedValuePaser(szRoleId)
    tbRoleInfo.rolename         = ValiedValuePaser(szRoleName)
    tbRoleInfo.rolelevel        = ValiedValuePaser(szRoleLevel)
    tbRoleInfo.roleviplevel     = ValiedValuePaser(szRoleVipLevel)
    tbRoleInfo.roletype         = ValiedValuePaser(szRoleType)
    tbRoleInfo.serverid         = ValiedValuePaser(szServerId)
    tbRoleInfo.servername       = ValiedValuePaser(szServerName)
    tbRoleInfo.zoneid           = ValiedValuePaser(szZoneId)
    tbRoleInfo.zonename         = ValiedValuePaser(szZoneName)
    tbRoleInfo.partyname        = ValiedValuePaser(szPartyName)
    tbRoleInfo.gender           = ValiedValuePaser(szGender)
    
    local szRoleInfo = dkjson.encode(tbRoleInfo)
    return szRoleInfo
end

function DataSDKHelper.OnRoleLogin(szRoleInfo)
    DataSDKManager:OnRoleLogin(szRoleInfo)
    -- local pChannelSdkManager = ChannelSDKSystem:GetManager()
    -- if not pChannelSdkManager then
    --     return
    -- end
    -- pChannelSdkManager:OnCreateRole(szRoleInfo)
end
--角色退出
function DataSDKHelper.OnRoleLogout()													
    DataSDKManager:OnRoleLogout()
end
--角色升级
function DataSDKHelper.OnRoleLevelUp(szLevel)
    if not szLevel or szLevel == "" then
        return  
    end
    -- local pChannelSdkManager = ChannelSDKSystem:GetManager()
    -- if not pChannelSdkManager then
    --     return
    -- end
    -- pChannelSdkManager:OnRoleLevelup(tonumber(szLevel))
    DataSDKManager:OnRoleLevelUp(szLevel)
end
--支付完成
function DataSDKHelper.CreatePayInfo(szCurrency, nMoney, szGameTradNo)
    local tbPayInfo = {}
    tbPayInfo.currency      = ValiedValuePaser(szCurrency)
    tbPayInfo.money         = ValiedValuePaser(nMoney)
    tbPayInfo.gametradeno   = ValiedValuePaser(szGameTradNo)

    local szPayInfo = dkjson.encode(tbPayInfo)
    return szPayInfo
end

function DataSDKHelper.OnEnterGame()
    -- local pChannelSdkManager = ChannelSDKSystem:GetManager()
    -- if not pChannelSdkManager then
    --     return
    -- end							    
    -- pChannelSdkManager:OnEnterGame()
end

function DataSDKHelper.OnPayFinish(szPayInfo)							    
    DataSDKManager:OnPayFinish(szPayInfo)
end

--事件
function DataSDKHelper.OnEvent(szEventId, szEventDesc)
    DataSDKManager:OnEvent(szEventId, szEventDesc)
end

function DataSDKHelper.CreateCustomEventData(szEventId, szEventDesc, nEventValue, tbEventData)		
    local tbEventInfo = {}
    tbEventInfo.eventid     = ValiedValuePaser(szEventId)
    tbEventInfo.desc        = ValiedValuePaser(szEventDesc)
    tbEventInfo.eventval    = ValiedValuePaser(nEventValue)
    tbEventInfo.eventdata   = tbEventData

    local szEventInfo = dkjson.encode(tbEventInfo)
    return szEventInfo
end

--自定义事件
function DataSDKHelper.OnCustomEvent(szEventInfo)
    DataSDKManager:OnCustomEvent(szEventInfo)
    -- local pChannelSdkManager = ChannelSDKSystem:GetManager()
    -- if not pChannelSdkManager then
    --     return
    -- end
    -- pChannelSdkManager:CustomEvent(szEventInfo)
end

--测试网络延迟
function DataSDKHelper.Ping(szHost)									    
    DataSDKManager:Ping(szHost)
end

--关卡开始
function DataSDKHelper.CreateMissionInfo(szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower)
    local tbMissionInfo = {}
    tbMissionInfo.missionid             = ValiedValuePaser(szMissionId)
    tbMissionInfo.missionname           = ValiedValuePaser(szMissionName)
    tbMissionInfo.domissiontimes        = ValiedValuePaser(nDoMissionTimes)
    tbMissionInfo.rolecurrentpower      = ValiedValuePaser(nRoleCurrentPower)

    local szMissionInfo = dkjson.encode(tbMissionInfo)
    return szMissionInfo
end

function DataSDKHelper.OnMissionBegin(szMissionInfo)						    
    DataSDKManager:OnMissionBegin(szMissionInfo)
end

--关卡成功完成
function DataSDKHelper.OnMissionSuccess(szMissionInfo)	
    DataSDKManager:OnMissionSuccess(szMissionInfo)
end

--关卡失败
function DataSDKHelper.OnMissionFail(szMissionInfo)	
    DataSDKManager:OnMissionFail(szMissionInfo)
end

--获得虚拟货币
function DataSDKHelper.CreateCurrencyGainInfo(nAmount, szCurrencyType, nTotal, szChannel, szChannelType)
    local tbGainInfo = {}
    tbGainInfo.amount               = ValiedValuePaser(nAmount)
    tbGainInfo.currencytype         = ValiedValuePaser(szCurrencyType)
    tbGainInfo.total                = ValiedValuePaser(nTotal)
    tbGainInfo.channel              = ValiedValuePaser(szChannel)
    tbGainInfo.channelType          = ValiedValuePaser(szChannelType)

    local szGainInfo = dkjson.encode(tbGainInfo)
    return szGainInfo
end

function DataSDKHelper.OnVirtualCurrencyGain(szGainInfo)	
    DataSDKManager:OnVirtualCurrencyGain(szGainInfo)
end

--充值购买虚拟货币
function DataSDKHelper.CreateCurrencyPurchasedInfo(nAmount, szCurrencyType, nTotal, szTradeNo)
    local tbPurchasedInfo = {}
    tbPurchasedInfo.amount               = ValiedValuePaser(nAmount)
    tbPurchasedInfo.currencytype         = ValiedValuePaser(szCurrencyType)
    tbPurchasedInfo.total                = ValiedValuePaser(nTotal)
    tbPurchasedInfo.tradeNo              = ValiedValuePaser(szTradeNo)

    local szPurchasedInfo = dkjson.encode(tbPurchasedInfo)
    return szPurchasedInfo
end

function DataSDKHelper.OnVirtualCurrencyGainForPurchased(szPurchasedInfo)
    DataSDKManager:OnVirtualCurrencyGainForPurchased(szPurchasedInfo)
end

--消耗虚拟货币
function DataSDKHelper.CreateCurrencyConsumeInfo(nAmount, szCurrencyType, nTotal, szItemName, nItemNum, szItemType)
    local tbConsumeInfo = {}
    tbConsumeInfo.amount               = ValiedValuePaser(nAmount)
    tbConsumeInfo.currencytype         = ValiedValuePaser(szCurrencyType)
    tbConsumeInfo.total                = ValiedValuePaser(nTotal)
    tbConsumeInfo.itemname             = ValiedValuePaser(szItemName)
    tbConsumeInfo.itemnum              = ValiedValuePaser(nItemNum)
    tbConsumeInfo.itemtype             = ValiedValuePaser(szItemType)

    local szConsumeInfo = dkjson.encode(tbConsumeInfo)
    return szConsumeInfo
end

function DataSDKHelper.OnVirtualCurrencyConsume(szConsumeInfo)	
    DataSDKManager:OnVirtualCurrencyConsume(szConsumeInfo)	
end

--获得物品
function DataSDKHelper.CreateItemGainInfo(nAmount, szItemName, szItemType, nTotal, szChannel, szChannelType)
    local tbItemGainInfo = {}
    tbItemGainInfo.amount               = ValiedValuePaser(nAmount)
    tbItemGainInfo.itemname             = ValiedValuePaser(szItemName)
    tbItemGainInfo.itemtype             = ValiedValuePaser(szItemType)
    tbItemGainInfo.total                = ValiedValuePaser(nTotal)
    tbItemGainInfo.channel              = ValiedValuePaser(szChannel)
    tbItemGainInfo.channeltype          = ValiedValuePaser(szChannelType)

    local szItemGainInfo = dkjson.encode(tbItemGainInfo)
    return szItemGainInfo
end

function DataSDKHelper.OnItemGain(szInfo)							    
    DataSDKManager:OnItemGain(szInfo)
end

--消耗物品
function DataSDKHelper.OnItemConsume(szInfo)							
    DataSDKManager:OnItemConsume(szInfo)
end

--标准事件
function DataSDKHelper.OnGameLoadResource()											    
    DataSDKManager:OnGameLoadResource()
end

--标准事件
function DataSDKHelper.OnGameLoadConfig()												
    DataSDKManager:OnGameLoadConfig()
end

--标准事件
function DataSDKHelper.OnOpenAnnouncement()											    
    DataSDKManager:OnOpenAnnouncement()
end

--标准事件
function DataSDKHelper.OnCloseAnnouncement()											
    DataSDKManager:OnCloseAnnouncement()
end

--标准事件
function DataSDKHelper.OnNewUserMission()												
    DataSDKManager:OnNewUserMission()
end

--私有功能码
function DataSDKHelper.CreateFuncCodeInfo(szCode, szCodeDes, szCodeType, szBatchId)
    local tbFuncCodeInfo = {}
    tbFuncCodeInfo.missionid             = ValiedValuePaser(szCode)
    tbFuncCodeInfo.missionname           = ValiedValuePaser(szCodeDes)
    tbFuncCodeInfo.domissiontimes        = ValiedValuePaser(szCodeType)
    tbFuncCodeInfo.rolecurrentpower      = ValiedValuePaser(szBatchId)

    local szFuncCodeInfo = dkjson.encode(tbFuncCodeInfo)
    return szFuncCodeInfo
end

function DataSDKHelper.OnPrivateFunCodeUse(szFunCodeInfo)					    
    DataSDKManager:OnPrivateFunCodeUse()
end

--公有功能码
function DataSDKHelper.OnPublicFunCodeUse(szFunCodeInfo)					    
    DataSDKManager:OnPublicFunCodeUse()
end

return DataSDKHelper