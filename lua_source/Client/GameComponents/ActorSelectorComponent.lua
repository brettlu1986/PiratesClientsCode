local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase") 
local CppDelegate = require("CppDelegate")
local Timer = require("Timer")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ActorSelectorComponent = luaclass("ActorSelectorComponent", GameComponentBaseClass)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = require("GameObjectSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")


ActorSelectorComponent.TouchActorDelegate = nil
ActorSelectorComponent.AutoSelectedNpc = nil
ActorSelectorComponent.SelectNearestNpcTimer = nil
ActorSelectorComponent.bVisibleInteraction = false
ActorSelectorComponent.tbInteractionObjects = {}
ActorSelectorComponent.nTriggerCount = 0

local tbLastSelectedNpc = nil 
function ActorSelectorComponent:GetSelectedNpc(bForce)
    if self.AutoSelectedNpc and not self.AutoSelectedNpc.bValid then 
        self.AutoSelectedNpc = nil 
    end 
    if bForce then 
        return self:ForceSelectNearestNpc()
    end 
    return self.AutoSelectedNpc
end

-- 创建
function ActorSelectorComponent:OnCreate(Owner, tbParams)
    return self.super.OnCreate(self, Owner, tbParams)
end

-- 销毁
function ActorSelectorComponent:OnDestroy()
end

function ActorSelectorComponent:SetInteractionNpc( pNpc )
    local bVisible = pNpc and true or false
    if self.bVisibleInteraction ~= bVisible or tbLastSelectedNpc ~= pNpc then 
        local nInteractionType = 0
        if pNpc then 
            nInteractionType = pNpc.tbNpcTemplateData.nInteractionType
        end 
        EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_CHANGE, bVisible, nInteractionType, pNpc)
        self.bVisibleInteraction = bVisible
    end 
    tbLastSelectedNpc = pNpc
end


local function GetMaxDIstance( Npc )
    return Npc.tbNpcTemplateData.nDistance
end

function ActorSelectorComponent:IsInRange( Npc )
    local nMaxDistance = GetMaxDIstance(Npc)

    if Npc.pUEActor then
        local nDistance = self.pUEActor:GetDistanceTo(Npc.pUEActor)
        return (nDistance < nMaxDistance and nDistance > 0) , nDistance
    else
        local selfLocation = self.pUEActor:K2_GetActorLocation()
        local npcLocation  = Npc:GetLocation()
        local pVector = KismetMathLibrary.Subtract_VectorVector(selfLocation, npcLocation)
        pVector.Z = 0
        local nDistance = KismetMathLibrary.VSize(pVector)
        
        return (nDistance < nMaxDistance and nDistance > 0) , nDistance
    end
end

function ActorSelectorComponent:TouchActor( pUEActor )
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsDead() then 
        return 
    end 
    local FoundObject = GameObjectSystem:FindByUEActor(pUEActor)
    if FoundObject then 
        if FoundObject.ObjectType == GameObjectTypeDef.PlayerOther then 
            log("On Click Other Player")
            EventManager:OnFireEvent(ClientEventDef.EV_ON_CLICK_PLAYER, FoundObject)
            -- logdebug("Player Is Click")
        elseif FoundObject.ObjectType == GameObjectTypeDef.Npc then 
            local bCanInteract = FoundObject:CheckCanInteraction()
            if( bCanInteract) and (self:IsInRange(FoundObject)) then
                log("On Click NPC ")
                EventManager:OnFireEvent(ClientEventDef.EV_UI_REQUEST_INTERACTION, FoundObject) 
            end
        elseif FoundObject.ObjectType == GameObjectTypeDef.AtmoSphereNpc then 
            FoundObject:OnPlayerInteraction()
        end 
    else -- 触摸到非gameobject的actor
        log("On Click Actor not gameobject", pUEActor.Type)
        EventManager:OnFireEvent(ClientEventDef.EV_TOUCH_TOUCHABLE_ACTOR, pUEActor)
    end
end

function ActorSelectorComponent:ForceSelectNearestNpc()
    local tbGameObjectList = GameObjectSystem:GetAllGameObjects()
    local nMinDistance = nil
    local MinDistanceNpc = nil
    for _, GameObject in pairs(tbGameObjectList) do
        if GameObject:GetObjectType() == GameObjectTypeDef.Npc and GameObject.pUEActor and not GameObject.pUEActor.bHidden then 
            local bCanInteract = GameObject:CheckCanInteraction()
            if(bCanInteract) then
                local IsNpcInRange, nDistance = self:IsInRange(GameObject)
                if IsNpcInRange then --and IsActorInScreen(Npc.pUEActor) then
                    if (nMinDistance == nil) or (nDistance < nMinDistance) then
                        nMinDistance = nDistance
                        MinDistanceNpc = GameObject
                    end
                else 
                    GameObject:SetSelected(false)
                end
            end
        end 
    end
   
    if MinDistanceNpc then 
        MinDistanceNpc:SetSelected(true)
    end 
    if self.AutoSelectedNpc == MinDistanceNpc then
        return self.AutoSelectedNpc 
    else
        if self.AutoSelectedNpc then 
            self.AutoSelectedNpc:SetSelected(false)
        end 
        self.AutoSelectedNpc = MinDistanceNpc
    end 

    self:SetInteractionNpc(self.AutoSelectedNpc)
    return self.AutoSelectedNpc
end

-- Select Nearest Npc and chekc selected Npc valid
function ActorSelectorComponent:SelectNearestNpc()
    local MinDistanceNpc = nil
    if self.nTriggerCount <= 0 then 
        if self.AutoSelectedNpc == MinDistanceNpc then
            return
        else
            if self.AutoSelectedNpc then 
                self.AutoSelectedNpc:SetSelected(false)
            end 
            self.AutoSelectedNpc = MinDistanceNpc
        end 
    
        self:SetInteractionNpc(self.AutoSelectedNpc)        
        return
    end 

    if self.nTriggerCount > 1 then 
        local nMinDistance = nil
        for i,v in pairs(self.tbInteractionObjects) do
            local tbNpc = GameObjectSystem:FindByInstanceId(v)
            if tbNpc then 
                if tbNpc:CheckCanInteraction() and tbNpc.pUEActor and not tbNpc.pUEActor.bHidden then 
                    local nDistance = self.pUEActor:GetDistanceTo(tbNpc.pUEActor)
                    if (nMinDistance == nil) or (nDistance < nMinDistance) then
                        nMinDistance = nDistance
                        MinDistanceNpc = tbNpc
                    end   
                end 
            else 
                self.nTriggerCount = self.nTriggerCount - 1
                self.tbInteractionObjects[i] = nil
            end         
        end 
    else 
        for i,v in pairs(self.tbInteractionObjects) do
            local tbNpc = GameObjectSystem:FindByInstanceId(v)
            if tbNpc then 
                if tbNpc:CheckCanInteraction() and tbNpc.pUEActor and not tbNpc.pUEActor.bHidden then 
                    MinDistanceNpc = tbNpc
                    break
                end 
            else 
                self.nTriggerCount = self.nTriggerCount - 1
                self.tbInteractionObjects[i] = nil                
            end         
        end         
    end   

    if MinDistanceNpc then 
        MinDistanceNpc:SetSelected(true)
    end 

    if self.AutoSelectedNpc == MinDistanceNpc then
        return
    else
        if self.AutoSelectedNpc then 
            self.AutoSelectedNpc:SetSelected(false)
        end 
        self.AutoSelectedNpc = MinDistanceNpc
    end 

    self:SetInteractionNpc(self.AutoSelectedNpc)
end


local OnEnterArea = function(self, tbGameObject, nAreaId)
    if self.Owner:IsDead() then  
        return 
    end 
    if self.tbInteractionObjects[nAreaId] then 
        return 
    end 
    
    local tbGameObjectList = GameObjectSystem:GetAllGameObjects()
    for _,GameObject in pairs(tbGameObjectList) do
        if GameObject:GetObjectType() == GameObjectTypeDef.Npc and GameObject.nAreanId == nAreaId then 
            local bCanInteract = GameObject:CheckCanInteraction()
            if bCanInteract then 
                local nServerInstanceId = GameObject.nServerInstanceId
                self.tbInteractionObjects[nAreaId] = nServerInstanceId
                self.nTriggerCount = self.nTriggerCount + 1
                break
            end 
        end 
    end

    self:SelectNearestNpc()

    if self.nTriggerCount > 0 and not self.SelectNearestNpcTimer  then 
        local fnTimerCallback = function()
             self:SelectNearestNpc()
         end        
         self.SelectNearestNpcTimer = Timer.StartTimer(self.SelectNearestNpcTimer, fnTimerCallback, 0.5, true)
     end 
 
end

local OnLeaveArea = function(self, _tbGameObject, nAreaId)  
    if self.nTriggerCount <= 0 or not self.tbInteractionObjects[nAreaId] then 
        return 
    end 
    self.nTriggerCount = self.nTriggerCount - 1
    self.tbInteractionObjects[nAreaId] = nil 
    self:SelectNearestNpc()

    if self.SelectNearestNpcTimer and  self.nTriggerCount <= 0 then 
        self.SelectNearestNpcTimer:Clear()
        self.SelectNearestNpcTimer = nil         
    end     
end

function ActorSelectorComponent:OnActorCreated(pUEActor)
    ActorSelectorComponent.super.OnActorCreated(self, pUEActor)
    log("ActorSelectorComponent:OnActorCreated")
    self.pUEActor = pUEActor
    
    local DelegateMgr = EngineExtShell.Get(GWorld):GetKMDelegateManager()
    if DelegateMgr == nil then
        error("DelegateMgr has not been initialized.")
    end
    self.TouchActorDelegate = CppDelegate:BindMethod(DelegateMgr.OnActorTouched, self, self.TouchActor)

    self.tbInteractionObjects = {}

    if not self:GetSelectedNpc(true) then 
        EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_CHANGE, false, 0, nil)
    end 

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_AREA_ENTER, self, OnEnterArea)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_AREA_LEAVE, self, OnLeaveArea)    
end


function ActorSelectorComponent:OnActorDestroyed(_pUEActor)
    if self.TouchActorDelegate then
        self.TouchActorDelegate:Unbind()
        self.TouchActorDelegate = nil 
    end

    self.tbNpcList = {}
    log("ActorSelectorComponent:OnActorDestroyed")
    if self.SelectNearestNpcTimer then
        log("ActorSelectorComponent:OnStopTimer")
        self.SelectNearestNpcTimer:Clear()
        self.SelectNearestNpcTimer = nil 
    end

    self.pUEActor = nil
    self.AutoSelectedNpc = nil

    self.tbInteractionObjects = nil 

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_AREA_ENTER, self, OnEnterArea)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_AREA_LEAVE, self, OnLeaveArea)    
end

return ActorSelectorComponent
