local luaclass = require("luaclass")
local HumanMovementStateBase = dynamic_require("HumanMovementStateBase")
local HumanMovementStateSwimming = luaclass("HumanMovementStateSwimming", HumanMovementStateBase)
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local DamageTypeEx = require("DamageTypeEx")
local PropUtil = require("PropUtil")
local HumanMovementStateType = require("HumanMovementStateType")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local SelfEventHelper = require("SelfEventHelper")
local Timer = require("Timer")
local HumanSwimmingIni = require("HumanSwimmingIni")
local CommonEventDef = require("CommonEventDef")

local STAMINA_TIMER = "StaminaTimer"
local DISTANCE_CHECK_TIMER = "DistanceCheckTimer"
local DISTANCE_CHECK_TIME = 1
local StaminaPosition  = Vector()

HumanMovementStateSwimming.EventHelper = nil 
HumanMovementStateSwimming.bIsStaminaRevert = false

local function StaminaChange(self, bRevert)
    local HumanBattlePropertyComponent = self.GamePlayer.HumanBattlePropertyComponent
    local nSwimmingStamina = HumanBattlePropertyComponent:GetSwimmingStamina()

    if bRevert and nSwimmingStamina >=  HumanSwimmingIni.nMaxStamina then  
        return 
    end 
    if Timer.IsOwnerTimerAlived(self, STAMINA_TIMER) and bRevert == self.bIsStaminaRevert then 
        return 
    end
    self.bIsStaminaRevert = bRevert
    if bRevert then 
        self.GamePlayer.BuffComponentServer:RemoveBuffById(HumanSwimmingIni.nBuffId)
    end
    Timer.StopOwnerTimer(self, STAMINA_TIMER)
    Timer.StartOwnerTimer(self, STAMINA_TIMER, function() 
        -- self:RouteProjectAttack(tbRepData)
        nSwimmingStamina = HumanBattlePropertyComponent:GetSwimmingStamina()
        if bRevert then  
            nSwimmingStamina = nSwimmingStamina + HumanSwimmingIni.nRecoverValue
            if nSwimmingStamina > HumanSwimmingIni.nMaxStamina then  
                nSwimmingStamina = HumanSwimmingIni.nMaxStamina
                -- Timer.StopOwnerTimer(self, STAMINA_TIMER)
            end 
            -- Timer.StopOwnerTimer(self, DISTANCE_CHECK_TIMER)
        else  
            nSwimmingStamina = nSwimmingStamina - HumanSwimmingIni.nDecreaseValue
            if nSwimmingStamina < 0 then  
                nSwimmingStamina = 0
                -- Timer.StopOwnerTimer(self, STAMINA_TIMER)
                self.GamePlayer.BuffComponentServer:AddBuffById(HumanSwimmingIni.nBuffId)
            end             
        end 
        HumanBattlePropertyComponent:SetSwimmingStamina(nSwimmingStamina)
    end, 1, true)
end 


local function CheckDistance(self)
    local fnDist = KismetMathLibrary.Vector_Distance2D

    local Location = self.GamePlayer:GetLocation()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRealRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)   

    if nRealRegionType == EPiratesGridRegionType.Land then  
        StaminaChange(self, true)
        return false
    end 
    local bRet, ShoreLoction = GridTypeManager:GetClosestPositionOfRegionType(Location.X, Location.Y, EPiratesGridRegionType.Land)

    if(not bRet) then
        logerror("OnSwimmCheckDistanceToShore GetClosestPositionOfRegionType failed,", Location.X, Location.Y)
        return false
    end
    -- local TargetPosition = Vector{X=NewLoction.X, Y=NewLoction.Y, Z=0}
    StaminaPosition.X = ShoreLoction.X
    StaminaPosition.Y = ShoreLoction.Y
    local Dist = fnDist(Location, StaminaPosition) 
    destroyUserData(ShoreLoction)
    -- logwarning("CheckDistance", Dist, "HumanSwimmingIni.nStaminaMinDistance", HumanSwimmingIni.nStaminaMinDistance)
    if Dist > HumanSwimmingIni.nStaminaMinDistance then
        StaminaChange(self, false)
        -- Timer.StopOwnerTimer(self, DISTANCE_CHECK_TIMER)
        return true
    else 
        StaminaChange(self, true)
    end  
    return false  
end

local function ChangeSwimmingType(self, nRegionType)
    Timer.StopOwnerTimer(self, DISTANCE_CHECK_TIMER)
    if nRegionType == EPiratesGridRegionType.Ocean then  
        -- if not CheckDistance(self) then 
            Timer.StartOwnerTimer(self, DISTANCE_CHECK_TIMER, CheckDistance, DISTANCE_CHECK_TIME, true)
        -- end
    else 
        StaminaChange(self, true)
    end
end 

local function ClearSwimming(self)
    if not self.bServer then 
        return 
    end 
    if self.GamePlayer.BuffComponentServer then 
        self.GamePlayer.BuffComponentServer:RemoveBuffById(HumanSwimmingIni.nBuffId)
    end
    local HumanBattlePropertyComponent = self.GamePlayer.HumanBattlePropertyComponent
    HumanBattlePropertyComponent:SetSwimmingStamina(HumanSwimmingIni.nMaxStamina)
    Timer.StopOwnerAllTimer(self, true)
    return 
end 

local function OnGridTypeChanged(self, tbGameObject, nRegionType)  
    if(tbGameObject == self.GamePlayer) then
        ChangeSwimmingType(self, nRegionType)
    end        
end


function HumanMovementStateSwimming:Active(tbParams)
    -- self:ChangeCapsule()
    local Owner   = self.Owner
    local GamePlayer = self.GamePlayer
    self:ChangeCapsule()

    local nLastState = Owner:GetLastState()
    if nLastState == HumanMovementStateType.Dying_State then 
        PropUtil.ApplyDamage(GamePlayer, nil, DamageTypeEx.DROWN, 100, nil)
        return 
    end

    TeamWatchServerHelper.NotifyViewersMovementState(GamePlayer, HumanMovementStateType.UpRight_State, 
    HumanMovementStateType.Swimming)


    BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(GamePlayer)
    local tbCurrentWeapon = GamePlayer.HumanWeaponComponent:GetCurrentWeapon()
    if tbCurrentWeapon then 
        -- 具体cancelattack的操作客户端自己处理
        BattleHumanWeaponSystemNew:SetCurrentWeapon(GamePlayer, 0, true)
    end
    if self.bServer then 
        if not self.EventHelper then
            self.EventHelper = SelfEventHelper()
        end
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GRID_TYPE_CHANGED, self, OnGridTypeChanged)

        local Location = GamePlayer:GetLocation()
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        local nRealRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)   
        ChangeSwimmingType(self, nRealRegionType)

        -- Timer.StartOwnerTimer(self, DISTANCE_CHECK_TIMER, CheckDistance, DISTANCE_CHECK_TIME, true)
    end
end

function HumanMovementStateSwimming:UnActive(tbParams)
    -- self:ChangeCapsule()
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end    

    ClearSwimming(self)
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner

    local pUEActor = GamePlayer.pUEActor
    local CharacterMovement = pUEActor.CharacterMovement
    CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)

    local SaveWeapon = BattleHumanWeaponSystemNew:GetSavedCurrentWeaponFromOwner(GamePlayer)
    if SaveWeapon ~= 0 then 
        BattleHumanWeaponSystemNew:SetCurrentWeapon(GamePlayer, SaveWeapon)
    end
end

function HumanMovementStateSwimming:UnInit(tbOwner)
    HumanMovementStateSwimming.super.UnInit(self, tbOwner)
    Timer.StopOwnerAllTimer(self, true)
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end    
end


return HumanMovementStateSwimming