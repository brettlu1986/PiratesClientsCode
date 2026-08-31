local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local CurrencyPacketProcessor = luaclass("CurrencyPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local CurrencySystem = require("CurrencySystem")

local function OnSyncCurrencyCount(tbPacket)
    for k, v in ipairs(tbPacket.currency) do
        local nTemplateId = v.template_id
        local nCount = v.count
        -- 虚拟货币数据统计功能
        EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_CURRENCY_CONSUME, nTemplateId, nCount)
        CurrencySystem:UpdateCurrency(nTemplateId, nCount)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_CURRENCY_COUNT_SYNC)
end

local function OnSyncPeriodicCurrencyCeilings(tbPacket)
    CurrencySystem:UpdateCurrencyCeilingsRecords(tbPacket.currency_ceiling)
end

local function OnRefreshCurrencyCeilings(tbPacket)
    local nReturnCode = tbPacket.return_code
    local ReturnCode = Proto.ReturnCode
    if nReturnCode == ReturnCode.OK then
        local tbCurrencyCeilings = tbPacket.currency_ceilings
        CurrencySystem:UpdateCurrencyCeilingsRecords(tbCurrencyCeilings.currency_ceiling)
        CurrencySystem:UpdateCurrencyCeilingsRefreshTime(tbCurrencyCeilings.remain_refresh_time)
    else
        logwarning("RefreshCurrencyCeilings failed!", nReturnCode)
    end
end

-- 注册处理包
function CurrencyPacketProcessor:RegisterPackets()
    self:BindFunc(Proto.s2c_SyncCurrencyCount, OnSyncCurrencyCount)
    self:BindFunc(Proto.s2c_SyncPeriodicCurrencyCeilings, OnSyncPeriodicCurrencyCeilings)
    self:BindFunc(Proto.s2c_RefreshCurrencyCeilings, OnRefreshCurrencyCeilings)
end

-- 初始化
function CurrencyPacketProcessor:Init()
    CurrencyPacketProcessor.super.Init(self)

    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

-- 结束
function CurrencyPacketProcessor:Uninit()
    CurrencyPacketProcessor.super.Uninit(self)
end

return CurrencyPacketProcessor
