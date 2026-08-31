local luaclass = require("luaclass")
local HumanMovementStateHelper = luaclass("HumanMovementStateHelper")
local SelfEventHelper = require("SelfEventHelper")
local HumanMovementStateType = require("HumanMovementStateType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local DESTRUCTIBLE_PATH = "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_WindowBase.BP_WindowBase_C'"

HumanMovementStateHelper.EventHelper = nil  
HumanMovementStateHelper.OwnerComponent = nil  
HumanMovementStateHelper.tbStates = {}
HumanMovementStateHelper.tbCurrentState = nil
HumanMovementStateHelper.nMovementState = HumanMovementStateType.None
HumanMovementStateHelper.nLastMovementState = HumanMovementStateType.None
HumanMovementStateHelper.tbActiveParams = nil
HumanMovementStateHelper.tbUnActiveParams = nil
HumanMovementStateHelper.GamePlayer = nil
HumanMovementStateHelper.OwnerActor = nil
HumanMovementStateHelper.bServer = false
HumanMovementStateHelper.bStantalone = false
HumanMovementStateHelper.bClient = false
HumanMovementStateHelper.bSelf = false
HumanMovementStateHelper.bLessThanAngle = true

local function LOG_DEBUG(self, ...)
    log(string.format("[HumanMovementState]Object[%s]", self.GamePlayer.szName), ...)
    -- log(debug.traceback())
end

local function Define(self, tbStateClass, nStateType)
    if self.tbStates[nStateType] ~= nil then
        logerror("error state type " .. nStateType)
        return
    end
    if not tbStateClass then
        logerror("error state class")
        return
    end
    local tbState = tbStateClass()
    tbState.nStateType = nStateType
    tbState:Init(self.OwnerComponent)
    self.tbStates[nStateType] = tbState
end


local function DefineAll(self)
    Define(self, dynamic_require"HumanMovementStateUpRight", HumanMovementStateType.UpRight_State)
    Define(self, dynamic_require"HumanMovementStateFalling", HumanMovementStateType.Falling_State)
    Define(self, dynamic_require"HumanMovementStateInPlane", HumanMovementStateType.InPlane_State)
    Define(self, dynamic_require"HumanMovementStateParachuting", HumanMovementStateType.Parachutine_State)
    Define(self, dynamic_require"HumanMovementStateGliding", HumanMovementStateType.Gliding_State)
    Define(self, dynamic_require"HumanMovementStateCrouch", HumanMovementStateType.Crouch_State)
    Define(self, dynamic_require"HumanMovementStateCrawl", HumanMovementStateType.Crawl_State)
    Define(self, dynamic_require"HumanMovementStateDying", HumanMovementStateType.Dying_State)
    Define(self, dynamic_require"HumanMovementStateSwimming", HumanMovementStateType.Swimming)
    Define(self, dynamic_require"HumanMovementJumpSpeelWall", HumanMovementStateType.Jumping_SpeelWall)
    Define(self, dynamic_require"HumanMovementStateVehicle", HumanMovementStateType.Vehicle)
    self:ChangeState(HumanMovementStateType.UpRight_State)
end

function HumanMovementStateHelper:Init(HumanMovementComponent)
    self.GamePlayer = HumanMovementComponent.Owner 
    self.OwnerActor = self.GamePlayer.pUEActor 
    self.OwnerComponent = HumanMovementComponent
    self.EventHelper = SelfEventHelper()
    DefineAll(self)    
    self.bServer = GlobalVariableSystem:IsServerLogic()
    self.bStantalone = GlobalVariableSystem:IsStandaloneServer()
    self.bClient = GlobalVariableSystem:IsClient()
    if self.GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        self.bSelf = true
    end

    self:RegisterEvent(self.EventHelper)
 end 

 function HumanMovementStateHelper:UnInit()

    if self.tbStates then 
        for k,v in pairs(self.tbStates) do
            v:UnInit()
        end
        self.tbStates = nil
    end
    self.EventHelper:UnregisterAll()
 end 

 local function ChangeMovementState(self, nMovementState)
    LOG_DEBUG(self, "last state", self.nMovementState, "newstate", nMovementState)
    self.nLastMovementState = self.nMovementState
    self.nMovementState = nMovementState
    
    self:ActiveState(nMovementState)
    self.OwnerComponent:OnMovementStateChangedNew(nMovementState, self.nLastMovementState)
end

function HumanMovementStateHelper:ChangeState(nNewState)
    ChangeMovementState(self, nNewState)
 end

 function HumanMovementStateHelper:OnRepMovementState(nMovementState)
    if self.nMovementState == nMovementState then
        -- LOG_DEBUG(self, "Can't OnRepMovementState Same State", nMovementState)
        return false
    end
    self:ChangeState(nMovementState)
 end

 function HumanMovementStateHelper:CanChangeState(nState)
    if self.nMovementState == nState then
        LOG_DEBUG(self, "Can't ChangeState Same State", nState)
        return false
    end

    if nState == HumanMovementStateType.InPlane_State or 
        nState == HumanMovementStateType.Parachutine_State or   
        nState == HumanMovementStateType.Falling_State then 
        return true
    end

    -- 跳伞时不允许切换姿态
    if self:IsInParachuting() then
        LOG_DEBUG(self, "Can't ChangeState IsInParachuting", nState)
        return false
    end

    local nCurrentMovementState = self:GetCurrentState()
    -- 重伤状态不可以切除游泳外的任何状态
    if nCurrentMovementState == HumanMovementStateType.Dying_State and nState ~= HumanMovementStateType.Dying_State then  
        if nState ~= HumanMovementStateType.Swimming then 
            LOG_DEBUG(self, "Can't ChangeState In Dying", nState)
            return false
        end
    end 
    
    if not self.bServer and self.OwnerComponent.bIsCrouching then  
        LOG_DEBUG(self, "Can't ChangeState bIsCrouching", nState)
        return false
    end 

    if nState == HumanMovementStateType.Crawl_State or nState == HumanMovementStateType.Crouch_State then  
        if not self.OwnerComponent.bEnableMove 
            or nCurrentMovementState == HumanMovementStateType.Dying_State 
            or nCurrentMovementState == HumanMovementStateType.Jumping_SpeelWall 
            or nCurrentMovementState == HumanMovementStateType.Swimming 
            or self:IsInVehicle() 
            then
                LOG_DEBUG(self, "Can't ChangeState bEnableMove", self.OwnerComponent.bEnableMove, self.OwnerComponent.bIsCrouching, nCurrentMovementState)
            return false 
        end        
    end

    if nState == HumanMovementStateType.Crawl_State then 
        -- 救援中不可 趴下 
        if self.OwnerComponent.bIsRescuing or self.GamePlayer.HumanWeaponComponent:IsAttacking() then 
            LOG_DEBUG(self, "Can't Change CrawlState InRescuing")
            return false 
        end
        LOG_DEBUG(self, "bLessThanAngle", self.bLessThanAngle)
        -- 跟据角度
        return self.bLessThanAngle
    end     

    if nState == HumanMovementStateType.Vehicle then
        local GameVehicleComponent = self.GamePlayer.GameVehicleComponent
        if not GameVehicleComponent then
            return false
        end
        local nCurrentVehicleState = GameVehicleComponent:GetVehicleState()
        if nCurrentVehicleState ~= HumanVehicleStateDef.PreAttachToVehicle and nCurrentVehicleState ~= HumanVehicleStateDef.AttachToVehicle then
            return false
        end
    end

    return true
 end


function HumanMovementStateHelper:ActiveState(nStateType)
    if not self.OwnerActor then
        return
    end
    local NextState = self.tbStates[nStateType]
    if NextState == nil then
        return
    end

    if self.tbCurrentState then
        LOG_DEBUG(self, "HumanMovementStateHelper:UnactiveState", self.GamePlayer.szName, self.GamePlayer.nPlayerId)
        self.tbCurrentState:UnActive(self.tbUnActiveParams)
        self.tbCurrentState = nil
    end
    self.tbUnActiveParams = nil 
    LOG_DEBUG(self, "HumanMovementStateHelper:ActiveState", self.GamePlayer.szName, self.GamePlayer.nPlayerId, nStateType)
    self.tbCurrentState = NextState
    NextState:Active(self.tbActiveParams)
    self.tbActiveParams = nil
end

function HumanMovementStateHelper:OnStateCompleted(tbState) 
    local nNextState = 0
    if tbState.nNextState ~= 0 then 
        nNextState = tbState.nNextState
    elseif tbState.bRevertToLastState then  
        nNextState = self.nLastMovementState
    else
        nNextState = HumanMovementStateType.UpRight_State
    end 
    LOG_DEBUG(self, "OnStateCompleted CurrentState = ", tbState.nStateType, "NextState = ", nNextState)
    self.OwnerComponent:RequestChangeMovement(nNextState)
end 

function HumanMovementStateHelper:OnDyingChanged(bIsDying)
    if bIsDying then
        self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.Dying_State)
    else
        self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.Crouch_State, true)
    end
end

local function OnBPMovementState(self, nState)
    if self.nMovementState == nState then
        LOG_DEBUG(self, "Can't OnBPMovementState Same State", nState)
        return false
    end
    -- self:ChangeState(nState)
    log("OnBPMovementState:", self.GamePlayer.szName, self.GamePlayer.nPlayerId, nState)
    self.OwnerComponent:RequestChangeMovement(nState, true)
end

local function OnHumanMoveAngleChanged(self, bLessThanAngle)
    self.bLessThanAngle = bLessThanAngle
    if not bLessThanAngle then
        if self:GetCurrentState() == HumanMovementStateType.Crawl_State then
            self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
        end
    end
end

local function OnHumanFindSwimFloor(self, bFindFloor)
    if not bFindFloor then  
        self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.Swimming)
    else 
        self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
    end 
end 

local function OnUEMovementChanged(self, pUEActor, PrevMovementMode, PrevCustomMode)
    local CurrentMovementMode = pUEActor.CharacterMovement.MovementMode
    if not self:IsInParachuting() and CurrentMovementMode == EMovementMode.MOVE_Falling then
        if not self.OwnerComponent.bIsCrouching then
            if self.nMovementState == HumanMovementStateType.Crawl_State or self.nMovementState == HumanMovementStateType.Crouch_State then 
                if self.bServer then
                    self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
                end
            end
        end
    end
    if CurrentMovementMode == EMovementMode.MOVE_Swimming then
        if not self.bStantalone then
            self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.Swimming)
        end
    elseif not self:IsInParachuting() and PrevMovementMode == EMovementMode.MOVE_Swimming then 
        self.OwnerComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
    end
end

function HumanMovementStateHelper:RegisterEvent(EventHelper)
    local pUEActor = self.OwnerActor
    EventHelper:RegisterCppDelegate(pUEActor.ChangeActorMovementState, self, OnBPMovementState)
    EventHelper:RegisterCppDelegate(pUEActor.CharacterMovement.OnHumanMoveAngleChanged, self, OnHumanMoveAngleChanged)

    local CharacterMovement = pUEActor.CharacterMovement
    EventHelper:RegisterCppDelegate(CharacterMovement.OnHumanFindSwimFloor, self, OnHumanFindSwimFloor)
    EventHelper:RegisterCppDelegate(pUEActor.MovementModeChangedDelegate, self, OnUEMovementChanged)
end

function HumanMovementStateHelper:IsInParachuting() 
    local nCurrentState = self:GetCurrentState()
    if nCurrentState == HumanMovementStateType.InPlane_State or 
        nCurrentState == HumanMovementStateType.Parachutine_State or   
        nCurrentState == HumanMovementStateType.Falling_State or 
        nCurrentState == HumanMovementStateType.Gliding_State then 
            return true
    end
    return false
end 

function HumanMovementStateHelper:IsInVehicle()
    local nVehicleState = self.OwnerComponent:GetVehicleState()
    if (nVehicleState == HumanVehicleStateDef.PreAttachToVehicle 
        or nVehicleState == HumanVehicleStateDef.AttachToVehicle) 
        or nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle then  
        return true  
    end 
    return false 
end 

function HumanMovementStateHelper:GetCurrentState()
    return self.nMovementState
end

function HumanMovementStateHelper:GetLastState()
    return self.nLastMovementState
end 

function HumanMovementStateHelper:GetDestructibleObject() 
    local pUEActor = self.OwnerActor
    -- local nAttackRange = pUEActor.CheckWallWeight

    local szDestructibleClass = DESTRUCTIBLE_PATH
    local pDestructibleClass = szDestructibleClass:load()
    if not pDestructibleClass then return end

    local OutActors = ExtendBlueprintFunctions.GetActorsInSectorRange(GWorld, pDestructibleClass, pUEActor:K2_GetActorLocation(), pUEActor:K2_GetActorRotation(),
    200, 90)
    
    for _, v in ipairs(OutActors) do
        if v ~= pUEActor then
            local tbTaker = GameObjectSystem:FindByUEActor(v)
            if tbTaker and tbTaker.ObjectType == GameObjectTypeDef.DestructibleObject and not tbTaker:IsDead() then
                return tbTaker 
            end
        end
    end
    return nil
end

function HumanMovementStateHelper:GetRootMotionJumpWallYaw()
    local tbSpeelWallState = self.tbStates[HumanMovementStateType.Jumping_SpeelWall]
    if tbSpeelWallState and tbSpeelWallState.GetYaw then
        return tbSpeelWallState:GetYaw()
    end   
    return -1
end

 return HumanMovementStateHelper