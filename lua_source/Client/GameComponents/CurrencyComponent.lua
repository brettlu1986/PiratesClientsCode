-----------------------------------------------------
--File Name    : CurrencyComponent.lua
--Author       : Ranjie
--Create Time  : 2019-03-08
--Description  : 货币的component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local CurrencyComponent = luaclass("CurrencyComponent", GameComponentBase)

local DelayTimer = require("DelayTimer")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local CurrencyIni = require("CurrencyIni")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

CurrencyComponent.tbCurrencyMap = nil

CurrencyComponent.tbCurrencyCeilingsRecords = nil
CurrencyComponent.nNextRefreshSeconds = nil
CurrencyComponent.tbRefreshCurrencyCeilingTimer = nil
CurrencyComponent.bFirstEnterLobby = false

-----------------------------------------local function---------------------------------------------

local function RequestRefreshCurrencyCeilings()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_RefreshCurrencyCeilings)
end

local function ClearRefreshCurrencyCeilingTimer(self)
    if self.tbRefreshCurrencyCeilingTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRefreshCurrencyCeilingTimer)
        self.tbRefreshCurrencyCeilingTimer = nil
    end
end

local function StartRefreshCurrencyCeilingTimer(self, nRemainSeconds)
    if self.tbRefreshCurrencyCeilingTimer ~= nil then
        error("Already Start RefreshCurrencyCeilingTimer!")
    end
    local FunRefreshCurrencyCeilingCallback = function()
        RequestRefreshCurrencyCeilings()
        self.tbRefreshCurrencyCeilingTimer = nil
    end
    local nRandomDelaySeconds = math.random(1, CurrencyIni.tbCurrencyCeiling.nDelaySecondsMax)
    local DelayHandle = DelayTimer:DelayRun(FunRefreshCurrencyCeilingCallback, nRemainSeconds + nRandomDelaySeconds)
    self.tbRefreshCurrencyCeilingTimer = DelayHandle
end

local function ClearAllTimers(self)
    ClearRefreshCurrencyCeilingTimer(self)
end

local function InitCurrency(self, tbParams)
    local tbCurrency = tbParams.currency
    if not tbCurrency then
        tbCurrency = {}
    end
    self.tbCurrencyMap = {}
    for k, v in ipairs(tbCurrency) do
        self:UpdateCurrency(v.template_id, v.count)
    end
end

local function InitCurrencyCeilings(self, tbParams)
    local tbCurrencyCeilings = tbParams.currency_ceilings
    if not tbCurrencyCeilings then
        tbCurrencyCeilings = {}
    end
    local tbCeilings = tbCurrencyCeilings.currency_ceiling
    if not tbCeilings then
        tbCeilings = {}
    end
    self.tbCurrencyCeilingsRecords = {}
    self:UpdateCurrencyCeilingsRecords(tbCeilings)
    self:UpdateCurrencyCeilingsRefreshTime(tbCurrencyCeilings.remain_refresh_time)
end

local function ResetCurrencyCeilingTimer(self)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSeconds = self.nNextRefreshSeconds - now
    if nRemainSeconds > 0 then
        StartRefreshCurrencyCeilingTimer(self, nRemainSeconds)
    else
        RequestRefreshCurrencyCeilings()
    end
end

local function OnEnterLobby(self)
    log("[Currency]CurrencyComponent OnEnterLobby")
    if self.bFirstEnterLobby then
        self.bFirstEnterLobby = false
        return
    end
    ClearAllTimers(self)
    ResetCurrencyCeilingTimer(self)
end

local function OnEnterBattle(self)
    log("[Currency]CurrencyComponent OnEnterBattle")
    ClearAllTimers(self)
end

local function OnLeaveLobby(self)
    log("[Currency]CurrencyComponent OnLeaveLobby")
    ClearAllTimers(self)
end

-----------------------------------------初始化---------------------------------------------
function CurrencyComponent:OnCreate(Owner, tbParams)
    CurrencyComponent.super.OnCreate(self, Owner, tbParams)
    self.bFirstEnterLobby = true
    if not tbParams then
        tbParams = {}
    end
    ClearAllTimers(self)
    InitCurrency(self, tbParams)
    InitCurrencyCeilings(self, tbParams)
    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    EventManager:BindEventMethod(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    
    return true
end

function CurrencyComponent:OnDestroy()
    ClearAllTimers(self)
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    EventManager:UnBindEventMethod(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    CurrencyComponent.super.OnDestroy(self)
end

-----------------------------------------道具的基础方法---------------------------------------------

function CurrencyComponent:UpdateCurrency(nTemplateId, nCount)
    self.tbCurrencyMap[nTemplateId] = nCount
end

function CurrencyComponent:GetCurrencyCount(nTemplateId)
    local nCount = self.tbCurrencyMap[nTemplateId]
    if nCount then
        return nCount
    end
    return 0
end

function CurrencyComponent:GetCurrencyCeilingsRecords(nTemplateId)
    return self.tbCurrencyCeilingsRecords[nTemplateId]
end

function CurrencyComponent:UpdateCurrencyCeilingsRecords(tbCeilings)
    for _, v in ipairs(tbCeilings) do
        local tbCeiling = {}
        tbCeiling.nTemplateId = v.template_id
        tbCeiling.nPeriodicCount = v.periodic_count
        tbCeiling.nCeiling = v.ceiling
        self.tbCurrencyCeilingsRecords[tbCeiling.nTemplateId] = tbCeiling
    end
end

function CurrencyComponent:UpdateCurrencyCeilingsRefreshTime(nRemainSeconds)
    if not nRemainSeconds then
        nRemainSeconds = 0
    end
    local now = GlobalVariableSystem:GetServerTimeUtc()
    self.nNextRefreshSeconds = now + nRemainSeconds
    StartRefreshCurrencyCeilingTimer(self, nRemainSeconds)
end

return CurrencyComponent
