
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIThreatSystem = luaclass("SAIThreatSystem", SAISystemBase)
local SAIThreatStrategyRegister = require("SAIThreatStrategyRegister")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

SAIThreatSystem.tbStrategy = nil
SAIThreatSystem.nActiveID = 0
SAIThreatSystem.nInterval = 1

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIThreatSystem:", ...)
end
-- luacheck: pop

local function DoStart(self)
    self.bRunning = true
    local tbStrategy = self.tbStrategy[self.nActiveID]
    if tbStrategy then
        tbStrategy:Start(self.nInterval)
    end
end

local function DoStop(self)
    local tbStrategy = self.tbStrategy[self.nActiveID]
    if tbStrategy then
        tbStrategy:Stop()
    end
    self.bRunning = false
end

local function OnDyingStateChanged(self, tbGameObject, bIsDying)
    local tbOwner = self.tbOwner
    if tbGameObject == tbOwner then
        if self.bRunning and bIsDying then
            DoStart(self)
        elseif not self.bRunning and not bIsDying then
            DoStop(self)
        end
    end
end

local function OnDead(self, tbGameObject)
    if self.bRunning and self.nActiveID > 0 then
        self.tbStrategy[self.nActiveID]:OnDead(tbGameObject)
    end
end


function SAIThreatSystem:AddStrategy(nID, szStrategy)
    local tbStrategy = require(szStrategy)()
    tbStrategy:Init(self.tbOwner)
    self.tbStrategy[nID] = tbStrategy
end

function SAIThreatSystem:GetThreatObject()
    local tbStrategy = self.tbStrategy[self.nActiveID]
    if tbStrategy then
        return tbStrategy.tbThreatObject
    end
end

function SAIThreatSystem:Active(nID)
    if self.nActiveID > 0 and self.bRunning then
        self.tbStrategy[self.nActiveID]:Stop()
        self.nActiveID = 0
    end
    local tbStrategy = self.tbStrategy[nID]
    if tbStrategy then
        self.nActiveID = nID
        if self.bRunning then
            tbStrategy:Start(self.nInterval)
        end
    end
end


function SAIThreatSystem:OnConfig(tbConfig)
    self.tbConfig  = tbConfig
    local tbThreatConfig = tbConfig.Threat
    self.nActiveID = tbThreatConfig.DefaultStratrgy
    self.nInterval = tbThreatConfig.Interval
    if tbThreatConfig.StartDisable then
        self.bEnabled  = false
        LOG("threat start disabled")
    end
end


function SAIThreatSystem:OnInit()
    self.tbStrategy  = {}
    self.bRunning = false
    SAIThreatStrategyRegister:RegisterStrategy(self)
end


function SAIThreatSystem:OnStart()
    LOG("threat start")
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnDyingStateChanged)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnDead)
    DoStart(self)
end


function SAIThreatSystem:OnStop()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnDyingStateChanged)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnDead)
    DoStop(self)
end

function SAIThreatSystem:OnUninit()
    for i,v in ipairs(self.tbStrategy) do
        v:Uninit()
    end
    self.nActiveID = 0
    self.tbStrategy = nil
end

return SAIThreatSystem
