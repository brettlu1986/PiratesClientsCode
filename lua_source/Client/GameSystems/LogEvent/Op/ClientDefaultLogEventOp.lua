local luaclass                  = require("luaclass")
local LogEventOpBase            = dynamic_require("LogEventOpBase")
local ClientDefaultLogEventOp   = luaclass("ClientDefaultLogEventOp", LogEventOpBase)

local DataSDKHelper         = require("DataSDKHelper")
local Analytics             = require("ClientAnalyticsProtoNames")
local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local GuideSystem           = require("GuideSystem")
local ItemSystem            = require("ItemSystem")
local ItemCategoryDef       = require("ItemCategoryDef")
local CurrencySystem        = require("CurrencySystem")
local L10N                  = require("L10N")
local Proto                 = require("ClientProtoNames")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")

--register event call interface
local function OnAccountLogin(self, szAccountId)
    local tbPacket = {}
    tbPacket.data_info = szAccountId
    self:LogEvent(Analytics.OnAccountLogin, tbPacket)
end

--账号退出
local function OnAccountLogout(self)
    local tbPacket = {}
    self:LogEvent(Analytics.OnAccountLogout, tbPacket)
end

--角色登录
local function OnRoleLogin(self, tbRolePacket)
    local tbCurrentServerData = GlobalVariableSystem.tbCurrentServerData
    local tbPacket = {}
    local szRoleType = "captain"
    local szServerId = tbCurrentServerData.id
    local szServerName = tbCurrentServerData.name
    local nAvartarId = tbRolePacket.avatar_id
    local szRoleInfo = DataSDKHelper.CreateRoleInfo(tostring(tbRolePacket.id), tbRolePacket.name, tostring(tbRolePacket.level), "0", szRoleType,
    szServerId, szServerName, szServerId, szServerName, "", nAvartarId == 100000 and "f" or "m")
    tbPacket.data_info = szRoleInfo
    self:LogEvent(Analytics.OnRoleLogin, tbPacket)
end

--角色退出
local function OnRoleLogout(self)
    OnAccountLogout(self)
    local tbPacket = {}
    self:LogEvent(Analytics.OnRoleLogout, tbPacket)
end

--角色升级
local function OnRoleLevelUp(self, szRoleLevel)
    local tbPlayer = GamePlayerSelfHelper:Get()
	local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
	if LobbyPropertyComponent then
		return
	end
	local nLevel = LobbyPropertyComponent:GetPlayerLevel()
    local tbPacket = {}
    tbPacket.data_info = tostring(nLevel)
    self:LogEvent(Analytics.OnRoleLevelUp, tbPacket)
end

--支付完成
local function OnPayFinish(self, szCurrency, nMoney, szGameTradeNo)
    local tbPacket = {}
    local szPayInfo = DataSDKHelper.CreatePayInfo(szCurrency, nMoney, szGameTradeNo)
    tbPacket.data_info = szPayInfo
    self:LogEvent(Analytics.OnPayFinish, tbPacket)
end

--关卡开始
local function OnMissionBegin(self)
    local szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower = BattleGameModeSystem:GetDungeonSessionId(), "", GuideSystem:GetEnterBattleCount(), 100
    local tbPacket = {}
    local szMissionInfo = DataSDKHelper.CreateMissionInfo(szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower)
    tbPacket.data_info = szMissionInfo
    self:LogEvent(Analytics.OnMissionBegin, tbPacket)
end

--关卡成功完成
local function OnMissionSuccess(self)
    local szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower = BattleGameModeSystem:GetDungeonSessionId(), "", GuideSystem:GetEnterBattleCount(), 100						
    local tbPacket = {}
    local szMissionInfo = DataSDKHelper.CreateMissionInfo(szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower)
    tbPacket.data_info = szMissionInfo
    self:LogEvent(Analytics.OnMissionSuccess, tbPacket)
end

--关卡失败
local function OnMissionFail(self, szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower)							
    local tbPacket = {}
    local szMissionInfo = DataSDKHelper.CreateMissionInfo(szMissionId, szMissionName, nDoMissionTimes, nRoleCurrentPower)
    tbPacket.data_info = szMissionInfo
    self:LogEvent(Analytics.OnMissionFail, tbPacket)
end

--获得虚拟货币  必须保证通个awardsystem获得 才能保证数据正确
local function OnVirtualCurrencyGain(self, tbData)
    local tbPacket = {}
    local szGainInfo = DataSDKHelper.CreateCurrencyGainInfo(tbData.nAmount, tbData.szCurrencyType, tbData.nTotal, tbData.szChannel, tbData.szChannelType)
    tbPacket.data_info = szGainInfo
    self:LogEvent(Analytics.OnVirtualCurrencyGain, tbPacket)
end

--充值购买虚拟货币 必须保证通个awardsystem获得 才能保证数据正确
local function OnVirtualCurrencyGainForPurchased(self, tbData)
    local tbPacket = {}
    local szPurchasedInfo = DataSDKHelper.CreateCurrencyPurchasedInfo(tbData.nAmount, tbData.szCurrencyType, tbData.nTotal, tbData.szChannel, tbData.szChannelType)
    tbPacket.data_info = szPurchasedInfo
    self:LogEvent(Analytics.OnVirtualCurrencyGainForPurchased, tbPacket)
end

--获得物品 必须保证通个awardsystem获得 才能保证数据正确
local function OnItemGain(self, tbData)
    local tbPacket = {}
    tbPacket.data_info = DataSDKHelper.CreateItemGainInfo(tbData.nAmount, tbData.szItemName, tbData.szItemType, tbData.nTotal, tbData.szChannel, tbData.szChannelType)
    self:LogEvent(Analytics.OnItemGain, tbPacket)
end

local function OnAwardGain(self, nSourceType, tbItemInfo)
    local tbData = {}
    local nTemplateId = tbItemInfo.template_id
    tbData.nAmount = tbItemInfo.count
    local tbTemplateInfo = ItemSystem:GetItemTemplate(nTemplateId)
    if not tbTemplateInfo then
        return
    end
    local nCategory = tbTemplateInfo.nCategory
    local szChannel = tostring(nSourceType)
    tbData.szChannel = szChannel
    tbData.szChannelType = szChannel
    
    if nCategory == ItemCategoryDef.CURRENCY then
        tbData.nTotal = CurrencySystem:GetCurrencyCount(nTemplateId)
        tbData.szCurrencyType = L10N:ToString(tbTemplateInfo.l10nName)
        if nSourceType == Proto.IAP then  --充值获得的虚拟货币
            OnVirtualCurrencyGainForPurchased(self, tbData)
        else -- 其他虚拟货币
            OnVirtualCurrencyGain(self, tbData)
        end
    else
        --获得物品
        tbData.szItemName = L10N:ToString(tbTemplateInfo.l10nName)
        tbData.szItemType = tostring(nCategory)
        tbData.nTotal = ItemSystem:GetItemCount(nTemplateId)
        OnItemGain(self, tbData)
    end
end

--消耗物品
local function GetConsumData(nInstanceId, nStackCount)
    local tbData = {}
    local Item = ItemSystem:GetItem(nInstanceId)
    if not Item then
        return tbData
    end
    local nOldStackCount = Item:GetStackCount()
    local tbTemplate = Item:GetTemplate()
    if nStackCount < nOldStackCount then
        tbData.nAmount = nOldStackCount - nStackCount
        tbData.szItemName = L10N:ToString(tbTemplate.l10nName)
        tbData.szItemType = tostring(tbTemplate.nCategory)
        tbData.nTotal = nStackCount
    end
    return tbData
end

local function OnItemConsume(self, nInstanceId, nStackCount)
    local tbData = GetConsumData(nInstanceId, nStackCount)
    local tbPacket = {}
    tbPacket.data_info = DataSDKHelper.CreateItemGainInfo(tbData.nAmount, tbData.szItemName, tbData.szItemType, tbData.nTotal, tbData.szChannel, tbData.szChannelType)
    self:LogEvent(Analytics.OnItemConsume, tbPacket)
end

--消耗虚拟货币 无法获取货币的消费渠道
local function GetCurrencyConsumeData(nTemplateId, nNewCount)
    local nOldCount = CurrencySystem:GetCurrencyCount(nTemplateId)
    local tbData = {}
    tbData.nTotal = nNewCount
    if not nOldCount or nNewCount > nOldCount then
        return tbData, false
    end
    if nOldCount > nNewCount then
        tbData.nAmount = nOldCount - nNewCount
        tbData.szCurrencyType = CurrencySystem:GetCurrencyName(nTemplateId)
    end
    return tbData, true
end

local function OnVirtualCurrencyConsume(self, nTemplateId, nNewCount)
    local tbConsumeData, bConsume = GetCurrencyConsumeData(nTemplateId, nNewCount)
    if not bConsume then
        return
    end
    local tbPacket = {}
    local szPurchasedInfo = DataSDKHelper.CreateCurrencyConsumeInfo(tbConsumeData.nAmount, tbConsumeData.szCurrencyType, tbConsumeData.nTotal, 
    tbConsumeData.szChannel, tbConsumeData.szChannelType)
    tbPacket.data_info = szPurchasedInfo
    self:LogEvent(Analytics.OnVirtualCurrencyConsume, tbPacket)
end

--标准事件
local function OnGameLoadResource(self)											    
    local tbPacket = {}
    self:LogEvent(Analytics.OnGameLoadResource, tbPacket)
end

--标准事件
local function OnGameLoadConfig(self)												
    local tbPacket = {}
    self:LogEvent(Analytics.OnGameLoadConfig, tbPacket)
end

--标准事件
local function OnOpenAnnouncement(self)											    
    local tbPacket = {}
    self:LogEvent(Analytics.OnOpenAnnouncement, tbPacket)
end

--标准事件
local function OnCloseAnnouncement(self)											
    local tbPacket = {}
    self:LogEvent(Analytics.OnCloseAnnouncement, tbPacket)
end

--标准事件
local function OnNewUserMission(self)												
    local tbPacket = {}
    self:LogEvent(Analytics.OnNewUserMission, tbPacket)
end

--私有功能码
function ClientDefaultLogEventOp:OnPrivateFunCodeUse(szCode, szCodeDes, szCodeType, szBatchId)
    local tbPacket = {}
    local szFunCode = DataSDKHelper.CreateFuncCodeInfo(szCode, szCodeDes, szCodeType, szBatchId)
    tbPacket.data_info = szFunCode
    self:LogEvent(Analytics.OnPrivateFunCodeUse, tbPacket)
end

--公有功能码
function ClientDefaultLogEventOp:OnPublicFunCodeUse(szCode, szCodeDes, szCodeType, szBatchId)
    local tbPacket = {}
    local szFunCode = DataSDKHelper.CreateFuncCodeInfo(szCode, szCodeDes, szCodeType, szBatchId)
    tbPacket.data_info = szFunCode
    self:LogEvent(Analytics.OnPublicFunCodeUse, tbPacket)
end

--自定义事件
function ClientDefaultLogEventOp:OnEvent(szEventId, szEventDesc)		
    local tbPacket = {}
    tbPacket.data_info = szEventDesc
    tbPacket.event_id = szEventId
    self:LogEvent(Analytics.OnEvent, tbPacket)
end

--自定义事件
function ClientDefaultLogEventOp:OnCustomEvent(szEventId, szEventDesc, nEventValue, tbEventData)		
    local tbPacket = {}
    tbPacket.data_info = DataSDKHelper.CreateCustomEventData(szEventId, szEventDesc, nEventValue, tbEventData)	
    tbPacket.event_id = szEventId
    self:LogEvent(Analytics.OnCustomEvent, tbPacket)
end

--测试网络延迟
function ClientDefaultLogEventOp:Ping(szHost)									    
    local tbPacket = {}
    tbPacket.data_info = szHost
    self:LogEvent(Analytics.Ping, tbPacket)
end

function ClientDefaultLogEventOp:Init()
    ClientDefaultLogEventOp.super.Init(self)
    self:RegisterEvent()
end

function ClientDefaultLogEventOp:Uninit()
    ClientDefaultLogEventOp.super.Uninit(self)
end

function ClientDefaultLogEventOp:RegisterEvent()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ACCOUNT_LOGIN,         self, OnAccountLogin)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ROLE_LOGIN,            self, OnRoleLogin)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_RETURN_TO_START_GAME,  self, OnRoleLogout)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW,                    self, OnRoleLevelUp)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_PAY_FINISH,            self, OnPayFinish)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE,                 self, OnMissionBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE,                 self, OnMissionSuccess)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_MISSION_FAIL,          self, OnMissionFail)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_AWARD_GAIN,            self, OnAwardGain)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_CURRENCY_GAIN,         self, OnVirtualCurrencyGain)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_CURRENCY_PURCHASED,    self, OnVirtualCurrencyGainForPurchased)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ITEM_GAIN,             self, OnItemGain)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_CURRENCY_CONSUME,      self, OnVirtualCurrencyConsume)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ITEM_CONSUME,          self, OnItemConsume)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOAD_RESOURCE,         self, OnGameLoadResource)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOAD_CONFIG,           self, OnGameLoadConfig)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_OPEN_ANNOUNCEMENT,     self, OnOpenAnnouncement)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_CLOSE_ANNOUNCEMENT,    self, OnCloseAnnouncement)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_NEW_USER_MISSION,      self, OnNewUserMission)
end

return ClientDefaultLogEventOp