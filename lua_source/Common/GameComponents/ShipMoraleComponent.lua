------------------------------------------------------
--File Name    : ShipMoraleComponent.lua
--Author       : Chen Jing
--Create Time  : 2018-09-14
--Description  : 船体的士气系统（每隔一段时间自动减少士气）
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local ShipMoraleComponent = luaclass("ShipMoraleComponent", GameComponentBaseClass)

local SelfEventHelperClass = require("SelfEventHelper")
local SelfTimerHelper = require("SelfTimerHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ShipDataTable = require("ShipDataTable")
local ShipMoraleDataTable = require("ShipMoraleDataTable")
local ShipMoraleIni = require("ShipMoraleIni")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local PropName = require("PropName")

ShipMoraleComponent.bDecreaseToHuman = false
ShipMoraleComponent.nDecreaseTimerHandler = nil
ShipMoraleComponent.EventHelper  = nil
ShipMoraleComponent.TimerHelper  = nil
ShipMoraleComponent.nPhase = 0

local function LOG(...)
    log("CJ->ShipMoraleComponent:", ...)
end

local function OnDyingStateChanged(self, tbGameObject, bIsDying)
    if tbGameObject ~= self.Owner then
        return
    end
    if not bIsDying then
        return
    end
    local tbPropertyComponent = self.Owner.ShipBattlePropertyComponent
    if tbPropertyComponent ~= nil then
        local nCurEp = tbPropertyComponent:GetEp()
        if nCurEp > 0 then
            tbPropertyComponent:ConsumeEp(nCurEp)
        end
    end
end

local function OnPawnDead(self, tbGameObject)
    if tbGameObject ~= self.Owner then
        return
    end

    local tbPropertyComponent = self.Owner.ShipBattlePropertyComponent
    if tbPropertyComponent ~= nil then
        local nCurEp = tbPropertyComponent:GetEp()
        if nCurEp > 0 then
            tbPropertyComponent:ConsumeEp(nCurEp)
        end
    end
    if self.nDecreaseTimerHandler then
        self.TimerHelper:ClearTimer(self.nDecreaseTimerHandler)
        self.nDecreaseTimerHandler = nil
    end
end

function ShipMoraleComponent:OnCreate(Owner, tbParams)
    ShipMoraleComponent.super.OnCreate(self, Owner, tbParams)
    self.EventHelper = SelfEventHelperClass()
    self.TimerHelper = SelfTimerHelper()
    self.Owner.ShipBattlePropertyComponent.OnEpChanged:Bind(self.OnEpChanged, self)
    self.bDecreaseToHuman = ShipMoraleIni.tbShipMorale.bDecreaseToHuman

    if GlobalVariableSystem:IsServerLogic() then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED,  self, OnDyingStateChanged)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    end

    return true
end

function ShipMoraleComponent:OnDestroy()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil

    if self.Owner and self.Owner.ShipBattlePropertyComponent and self.Owner.ShipBattlePropertyComponent.OnEpChanged then
        self.Owner.ShipBattlePropertyComponent.OnEpChanged:Unbind(self.OnEpChanged, self)
    end
    if self.nDecreaseTimerHandler then
        self.TimerHelper:ClearTimer(self.nDecreaseTimerHandler)
        self.nDecreaseTimerHandler = nil
    end
    ShipMoraleComponent.super.OnDestroy(self)
end


function ShipMoraleComponent:OnActorCreated(pUEActor)
    ShipMoraleComponent.super.OnActorCreated(self, pUEActor)
    if self.Owner:IsShip() then
        self:SetEnableDecrease(true)
    end
end

function ShipMoraleComponent:OnActorDestroyed(pUEActor)
    if self.Owner:IsShip() and not self.bDecreaseToHuman then
        self:OnMoralePhaseChanged(0)
        self:SetEnableDecrease(false)
    end
    ShipMoraleComponent.super.OnActorDestroyed(self, pUEActor)
end

local function RemoveProperies(self, tbShipMoraleTemplate)
    local tbOwner = self.Owner
    if tbOwner and tbShipMoraleTemplate and tbOwner.BuffComponentServer and tbShipMoraleTemplate.tbBuffIds then
        for _,v in ipairs(tbShipMoraleTemplate.tbBuffIds) do
            LOG("remove buffer ", v)
            tbOwner.BuffComponentServer:RemoveBuffById(v)
        end
    end
end

local function AddProperies(self, tbShipMoraleTemplate)
    local tbOwner = self.Owner
    if tbOwner and tbShipMoraleTemplate and tbOwner.BuffComponentServer and tbShipMoraleTemplate.tbBuffIds then
        for _,v in ipairs(tbShipMoraleTemplate.tbBuffIds) do
            LOG("add buffer ", v)
            tbOwner.BuffComponentServer:AddBuffWithInstigator(tbOwner, v)
        end
    end
end

local function RemoveApearance(self, tbShipMoraleTemplate)
    -- nothing todo
end

local function AddApearance(self, tbShipMoraleTemplate)
    local SoundManager = require("SoundManager")
    local NpcDialogBoardHelper = require("NpcDialogBoardHelper")

    if tbShipMoraleTemplate.nSound > 0 then
        LOG("play sound ", tbShipMoraleTemplate.nSound)
        SoundManager:PlaySoundEffect(tbShipMoraleTemplate.nSound)
    end
    if string.len(tbShipMoraleTemplate.strParticle) > 0 then
        LOG("play effect ", tbShipMoraleTemplate.strParticle)
    end
    if tbShipMoraleTemplate.nPopText > 0 then
        LOG("play pop text ", tbShipMoraleTemplate.nPopText)
        NpcDialogBoardHelper:OpenDialogBoard(tbShipMoraleTemplate.nPopText)
    end
end


function ShipMoraleComponent:OnMoralePhaseChanged(nNewPhase)
    if self.Owner:IsShip() then
        local nTemplateId  = self.Owner:GetShipTemplateId()
        local ShipTemplate = ShipDataTable:GetTemplate(nTemplateId)
        if not ShipTemplate then return end
        assert(ShipTemplate, "ShipMoraleComponent:OnTickMoraleDecrease() invalid ship template id")
        local nMoralePhaseId = ShipTemplate.nMoralePhaseId
        local tbOldShipMoraleTemplate = ShipMoraleDataTable:GetMoralePhase(nMoralePhaseId, self.nPhase)
        local tbNewShipMoraleTemplate = ShipMoraleDataTable:GetMoralePhase(nMoralePhaseId, nNewPhase)
        if GlobalVariableSystem:IsServerLogic() then
            RemoveProperies(self, tbOldShipMoraleTemplate)
            AddProperies(self, tbNewShipMoraleTemplate)
        end
        if GlobalVariableSystem:IsClient() then
            if nNewPhase > self.nPhase then
                RemoveApearance(self, tbOldShipMoraleTemplate)
                AddApearance(self, tbNewShipMoraleTemplate)
            end
        end
    end
    self.nPhase = nNewPhase
    EventManager:OnFireEvent(CommonEventDef.EV_MORALE_PHASE_CHANGED)
end


function ShipMoraleComponent:OnEpChanged(nNewValue)
    local tbOwner = self.Owner
    if tbOwner:IsDead() then
        return
    end

    local nTemplateId = tbOwner:GetShipTemplateId()
    local ShipTemplate = ShipDataTable:GetTemplate(nTemplateId)
    if ShipTemplate then
        if nNewValue > 0 then
            if self.bDecreaseToHuman or tbOwner:IsShip() then
                self:SetEnableDecrease(true)
            end
        else
            self:SetEnableDecrease(false)
        end

        local nMoralePhaseId = ShipTemplate.nMoralePhaseId
        local nMaxPhase = ShipMoraleDataTable:GetMoralePhaseCount(nMoralePhaseId)
        for i=1,nMaxPhase do
            local tbShipMoraleTemplate = ShipMoraleDataTable:GetMoralePhase(nMoralePhaseId, i)
            if tbShipMoraleTemplate and nNewValue <= tbShipMoraleTemplate.nMorale then
                if self.nPhase ~= i then
                    self:OnMoralePhaseChanged(i)
                end
                break
            end
        end
    end
end

function ShipMoraleComponent:OnTickMoraleDecrease()
    local tbOwner = self.Owner
    if tbOwner and tbOwner.ShipBattlePropertyComponent then
        local ShipBattlePropertyComponent = tbOwner.ShipBattlePropertyComponent
        if ShipBattlePropertyComponent then
            local nMorale = ShipBattlePropertyComponent:GetEp()
            if nMorale > 0 then
                local nDecreaseEp = ShipBattlePropertyComponent:GetProp(PropName.nShipMoraleConsumedSpeed)
--                LOG("nDecreaseEp", nMorale,nDecreaseEp)
                ShipBattlePropertyComponent:ConsumeEp(nDecreaseEp)
            end
        end
    end
end

function ShipMoraleComponent:SetEnableDecrease(bEnable)
    if GlobalVariableSystem:IsServerLogic() then
        if bEnable then
            local nTemplateId = self.Owner:GetShipTemplateId()
            local ShipTemplate = ShipDataTable:GetTemplate(nTemplateId)
            if ShipTemplate and not self.nDecreaseTimerHandler and self.Owner.ShipBattlePropertyComponent:GetEp() > 0 then
                self.nDecreaseTimerHandler = self.TimerHelper:NewTimerMethod(self, self.OnTickMoraleDecrease, 1, true)
            end
        else
            if self.nDecreaseTimerHandler then
                self.TimerHelper:ClearTimer(self.nDecreaseTimerHandler)
                self.nDecreaseTimerHandler = nil
            end
        end
    end
end

function ShipMoraleComponent:GetPhaseIcon()
    if self.nPhase <= 0 then
        return
    end
    local nTemplateId  = self.Owner:GetShipTemplateId()
    local ShipTemplate = ShipDataTable:GetTemplate(nTemplateId)
    if not ShipTemplate then return end
    local nMoralePhaseId = ShipTemplate.nMoralePhaseId
    local tbShipMoraleTemplate = ShipMoraleDataTable:GetMoralePhase(nMoralePhaseId, self.nPhase)
    return tbShipMoraleTemplate and tbShipMoraleTemplate.tbBuffIcons
end

return ShipMoraleComponent
