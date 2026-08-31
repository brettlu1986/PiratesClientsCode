-----------------------------------------------------
--File Name    : BotDistributionSystem.lua
--Author       : Chen Jing
--Create Time  : 2019-05-06
--Description  : 显示机器人的分布和状态
-----------------------------------------------------
local luaclass         = require("luaclass")
local BotDistributionSystem = luaclass("BotDistributionSystem")
local SelfTimerHelperClass  = require("SelfTimerHelper")
local SelfEventHelperClass  = require("SelfEventHelper")
local NetworkManager        = dynamic_require("NetworkManager")
local ProtoDC               = require("DungeonCommonProtoNames")
local CommonEventDef        = require("CommonEventDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
-----------------------------------------------------

BotDistributionSystem.SelfTimerHelper = nil
BotDistributionSystem.SelfEventHelper = nil
BotDistributionSystem.ReportTimer = nil
BotDistributionSystem.tbListener = nil
BotDistributionSystem.nLastSyncIndex = 0

local nReportInteval = 0.1
local nMaxReportNumPerTick = 1

local tbDataSources = {

}
-- luacheck: push ignore
local function LOG(...)
    log("CJ->BotDistributionSystem:", ...)
end
-- luacheck: pop


local function OnPlayerLogout(self, tbGameObject)
    for i,v in ipairs(self.tbListener) do
        if v == tbGameObject then
            table.remove( self.tbListener, i )
            LOG("remove listener", #self.tbListener)
            break
        end
    end
    if #self.tbListener <= 0 then
        self:StopReport()
    end
end

function BotDistributionSystem:Init()
    self.tbListener = { }
    self.SelfTimerHelper = SelfTimerHelperClass()
    self.SelfEventHelper = SelfEventHelperClass()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT,      self, OnPlayerLogout)
    return true
end

function BotDistributionSystem:Uninit()
    self.tbListener = nil
    self.SelfEventHelper:UnregisterAll()
    self.SelfTimerHelper:ClearAllTimer()
    self:StopReport()
end

function BotDistributionSystem:StartReport()
    self:StopReport()
    if GlobalVariableSystem.EnableDLAgent and GlobalVariableSystem.bEnableAIGameCore then
        tbDataSources = { require("GameCoreAgentSource") }
    else
        tbDataSources = { require("BehaviorTreeBotSource") }
    end
    for i,v in ipairs(tbDataSources) do
        v:OnStart()
    end
    self.nLastSyncIndex = 0
    self.ReportTimer = self.SelfTimerHelper:NewTimerMethod(self, self.OnTick, nReportInteval, true)
end

local function GetInfo(nIndex)
    local nStart = 0
    for i,v in ipairs(tbDataSources) do
        local nSize = v:GetSize()
        if nIndex <= nStart + nSize then
            return v:QueryInfo(nIndex - nStart)
        else
            nStart = nStart + nSize
        end
    end
end

function BotDistributionSystem:OnTick()
    if #self.tbListener <= 0 then
        return
    end
    local nTotalSize = 0
    for i,v in ipairs(tbDataSources) do
        nTotalSize = nTotalSize + v:GetSize()
    end
    if nTotalSize <= 0 then
        return
    end
    local tbBotInfos = { }
    for i=1, math.min( nMaxReportNumPerTick, nTotalSize) do
        local nIndex = self.nLastSyncIndex + 1
        if nIndex > nTotalSize then
            nIndex = 1
        end
        local tbBotInfo = GetInfo(nIndex)
        table.insert( tbBotInfos, tbBotInfo )
        self.nLastSyncIndex = nIndex
    end
    local d2c_SyncBotInfos = {}
    d2c_SyncBotInfos.num_bot = #tbBotInfos
    d2c_SyncBotInfos.bots = tbBotInfos
    for _,v in ipairs(self.tbListener) do
        NetworkManager:GetRPCNetworkProxy():SendToClient(v:GetUEControllerUniqueId(), ProtoDC.d2c_SyncBotInfos,
        d2c_SyncBotInfos)
    end
end

function BotDistributionSystem:StopReport()
    LOG("stop report")
    if self.ReportTimer then
        self.ReportTimer:Clear()
        self.ReportTimer = nil
    end
end

function BotDistributionSystem:AddListenr(tbGameObject)
    assert(tbGameObject:GetUEControllerUniqueId() ~= nil)
    for i,v in ipairs(self.tbListener) do
        if v == tbGameObject then
            return
        end
    end
    table.insert( self.tbListener, tbGameObject)
end

return BotDistributionSystem()