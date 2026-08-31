-----------------------------------------------------
--File Name    : AbilityEvent_Trigger.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-22
--Description  : 激活时生成一个球型Trigger，在OverlapBegin时触发DoAction，OverlapEnd时触发UndoAction
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_Trigger = luaclass("AbilityEvent_Trigger", AbilityEventBaseClass)

local CppDelegate = require("CppDelegate")
local UEActorHelper = require("UEActorHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local INVALID_NUMBER = -1
local ABILITY_TRIGGER_CLASS_PATH = "/Game/Game/GameSystems/Skill/BP_AbilityTriggerActor.BP_AbilityTriggerActor_C"

AbilityEvent_Trigger.pAbilityTrigger = nil
AbilityEvent_Trigger.OnBeginOverlapDelegate = nil
AbilityEvent_Trigger.OnEndOverlapDelegate = nil
AbilityEvent_Trigger.tbOverlapedCharacter = nil

local function IndexOverlapCharacter(self, tbCharacter)
    for i,v in ipairs(self.tbOverlapedCharacter) do
        if v == tbCharacter then
            return i
        end
    end
    return INVALID_NUMBER
end

local function AddOverlappedCharacter(self, tbCharacter)
    if IndexOverlapCharacter(self, tbCharacter) ~= INVALID_NUMBER then
        return false
    end
    table.insert(self.tbOverlapedCharacter, tbCharacter)
    return true
end

local function RemoveOverlappedCharacter(self, tbCharacter)
    local nIndex = IndexOverlapCharacter(self, tbCharacter)
    if nIndex ~= INVALID_NUMBER then
        table.remove(self.tbOverlapedCharacter, nIndex)
        return true
    end
    return false
end

local function IsValidOverlappedObject(self, tbOverlappedObject)
    if tbOverlappedObject == self.OwnerPawn then                            -- 不是跟自己Overlap
        return false
    end
    if not GameObjectSystem:IsCharacter(tbOverlappedObject) then            -- Overlap的对象是个Character（不是收集物等）
        return false
    end
    return true
end

local function OnActorBeginOverlap(self, _, pOtherActor)
    local tbOverlappedObject = GameObjectSystem:FindByUEActor(pOtherActor)
    if not IsValidOverlappedObject(self, tbOverlappedObject) then
        return
    end
    if not AddOverlappedCharacter(self, tbOverlappedObject) then
        return
    end
    self:TriggerDo({tbTargetPawns = {tbOverlappedObject}})
end

local function OnActorEndOverlap(self, _, pOtherActor)
    local tbOverlappedObject = GameObjectSystem:FindByUEActor(pOtherActor)
    if not IsValidOverlappedObject(self, tbOverlappedObject) then
        return
    end
    if not RemoveOverlappedCharacter(self, tbOverlappedObject) then
        return
    end
    self:TriggerUndo({tbTargetPawns = {tbOverlappedObject}})
end

function AbilityEvent_Trigger:OnActivate()
    if self.pAbilityTrigger then
        return
    end

    if self.OwnerPawn:IsHuman() then    -- TODO 暂时不对人开放
        return
    end

    self.tbOverlapedCharacter = {}

    local pOwnerUEActor = self.OwnerPawn.pUEActor
    local _, pAbilityTrigger = UEActorHelper:CreateActor(ABILITY_TRIGGER_CLASS_PATH)
    pAbilityTrigger:Init(pOwnerUEActor, self.tbParams.Radius)
    self.pAbilityTrigger = pAbilityTrigger

    local tbOverlapedActors = pAbilityTrigger.OverlapedActors
    for i,v in ipairs(tbOverlapedActors) do
        OnActorBeginOverlap(self, pOwnerUEActor, v)
    end

    self.OnBeginOverlapDelegate = CppDelegate:BindMethod(pAbilityTrigger.OnActorBeginOverlap, self, OnActorBeginOverlap)
    self.OnEndOverlapDelegate = CppDelegate:BindMethod(pAbilityTrigger.OnActorEndOverlap, self, OnActorEndOverlap)
end

function AbilityEvent_Trigger:OnDeactivate()
    if self.OnBeginOverlapDelegate then
        self.OnBeginOverlapDelegate:Unbind()
        self.OnBeginOverlapDelegate = nil
    end
    if self.OnEndOverlapDelegate then
        self.OnEndOverlapDelegate:Unbind()
        self.OnEndOverlapDelegate = nil
    end
    if self.pAbilityTrigger then
        UEActorHelper:DestroyActor(self.pAbilityTrigger)
        self.pAbilityTrigger = nil
    end
    if self.tbOverlapedCharacter then
        if #self.tbOverlapedCharacter > 0 then
            self:TriggerUndo({tbTargetPawns = self.tbOverlapedCharacter})
        end
        self.tbOverlapedCharacter = nil
    end
end

return AbilityEvent_Trigger
