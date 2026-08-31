
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local SAIComponent = luaclass("SAIComponent", GameComponentBaseClass)
local SelfEventHelperClass  = require("SelfEventHelper")
local CommonEventDef        = require("CommonEventDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local SAISystemRegister     = require("SAISystemRegister")
local SAILogicRegister      = require("SAILogicRegister")
local SAILogicConfigDef     = require("SAILogicConfigDef")
local AIEntitySystem        = require("AIEntitySystem")

SAIComponent.tbSubSystems = nil
SAIComponent.tbAILogics = nil
SAIComponent.bRunning = false
SAIComponent.nActiveLogicId = -1
SAIComponent.bAutoStartAI = true
SAIComponent.bInit = false

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIComponent:", ...)
end
-- luacheck: pop

local function OnDead(self, tbGameObject)
    if GlobalVariableSystem:IsServerLogic() and tbGameObject == self.Owner then
        local pLocation = tbGameObject:GetLocation()
        LOG("ai object dead:", self.Owner.szName, tbGameObject:IsShip(), pLocation.X, pLocation.Y, pLocation.Z)
        self:StopAI()
        self:DestroyAI()
    end
end


function SAIComponent:OnCreate(Owner, tbParams)
    SAIComponent.super.OnCreate(self, Owner, tbParams)
    local SelfEventHelper = SelfEventHelperClass()
    self.tbSubSystems  = {}
    self.tbAILogics = {}
    self.bAutoStartAI = true
    self.bRunning = false
    self.bInit = false
    self.nActiveLogicId = 0
    self.EventHelper = SelfEventHelper
    AIEntitySystem:Register(Owner)
end

function SAIComponent:OnActorCreated(pUEActor)
    SAIComponent.super.OnActorCreated(self, pUEActor)
end

function SAIComponent:AddLogic(nID, szAILogic)
    local tbAILogic = require(szAILogic)()
    tbAILogic:OnInit(self.Owner)
    self.tbAILogics[nID] = tbAILogic
    LOG("add ai logic:", nID, szAILogic)
end

function SAIComponent:AddSubSystem(nID, szSubSystem)
    local tbSubSystem = require(szSubSystem)()
    tbSubSystem:Init(self.Owner)
    self.tbSubSystems[nID] = tbSubSystem
    LOG("add ai subsystem:", nID, szSubSystem)
end


function SAIComponent:SetAutoStartAI(bAutoStartAI)
    self.bAutoStartAI = bAutoStartAI
end

function SAIComponent:StartAI()
    local nActiveLogicId = self.nActiveLogicId
    if nActiveLogicId > 0 then
        local tbAILogic = self.tbAILogics[nActiveLogicId]
        tbAILogic:Start()
        self.bRunning = true
        LOG("start ai")
    end
end

function SAIComponent:StopAI()
    local nActiveLogicId = self.nActiveLogicId
    if nActiveLogicId > 0 and self.bRunning then
        LOG("stop ai ", self.nActiveLogicId, self.Owner.szName)
        local tbAILogic = self.tbAILogics[nActiveLogicId]
        tbAILogic:Stop()
        self.bRunning = false
    end
end

function SAIComponent:DestroyAI()
    for i,v in ipairs( self.tbAILogics) do
        v:OnUninit()
    end
    self.nActiveLogicId = 0
    LOG("destroy ai ", self.Owner.szName)
end

function SAIComponent:InitAI()
    if not self.bInit then
        LOG("init ai")
        self.bInit = true
        local SelfEventHelper = self.EventHelper
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnPostActorCreated)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD,      self, OnDead)
        SAISystemRegister:RegisterSystem(self)
        SAILogicRegister:RegisterLogic(self)
    end
end

function SAIComponent:EnableAI(nID, ...)
    self:InitAI()
    if self.tbAILogics[nID] then
        self.nActiveLogicId = nID
        local tbConfig = SAILogicConfigDef:GetConfig(nID)
        local tbAILogic= self.tbAILogics[nID]
        tbAILogic:Enable(tbConfig, ...)
        self.bRunning = tbAILogic.bStarted
        LOG("enabled ai ", nID, self.bRunning)
    end
end

function SAIComponent:OnPostActorCreated(tbObject)
    if tbObject == self.Owner and self.bAutoStartAI then
        self:StartAI()
    end
end

function SAIComponent:OnActorDestroyed(pUEActor)
    self:StopAI()
    SAIComponent.super.OnActorDestroyed(self, pUEActor)
end

function SAIComponent:GetSystem(nID)
    return self.tbSubSystems[nID]
end

function SAIComponent:StartSubSystem()
    LOG("start system", self.Owner.szName)
    for i,v in ipairs( self.tbSubSystems) do
        v:Start()
    end
end

function SAIComponent:ConfigSubSystem(tbConfig)
    for i,v in ipairs( self.tbSubSystems) do
        v:Config(tbConfig)
    end
end

function SAIComponent:StopSubSystem()
    for i,v in ipairs( self.tbSubSystems) do
        v:Stop()
    end
    LOG("stop system", self.Owner.szName)
end

function SAIComponent:DestroySubSystem()
    for i,v in ipairs( self.tbSubSystems) do
        v:Uninit()
    end
    self.tbSubSystems = nil
    LOG("destroy system")
end

function SAIComponent:OnDestroy(...)
    LOG("OnDestroy")
    AIEntitySystem:Unregister(self.Owner)
    if self.bInit then
        self:DestroySubSystem()
        self:DestroyAI()
    end
    self.bInit = false
    self.EventHelper:UnregisterAll()
    SAIComponent.super.OnDestroy(self, ...)
    self.tbAILogics = nil
    self.tbSubSystems = nil
end


function SAIComponent:GetAIController()
    local nID = self.nActiveLogicId
    if self.tbAILogics[nID] then
        return self.tbAILogics[nID]:GetAIController()
    end
    return
end

function SAIComponent:GetLogic()
    local nID = self.nActiveLogicId
    return self.tbAILogics[nID]
end

function SAIComponent:IsEnabled()
    return  self.nActiveLogicId > 0
end


------------------------------------------------------------
function SAIComponent:CanUseWeapon(nTemplateId)
    local nID = self.nActiveLogicId
    if nID > 0 then
        return self.tbAILogics[nID]:CanUseWeapon(nTemplateId)
    end
end

function SAIComponent:GetWeaponConfig(nTemplateId)
    local nID = self.nActiveLogicId
    if nID > 0 then
        return self.tbAILogics[nID]:GetWeaponConfig(nTemplateId)
    end
end

return SAIComponent
