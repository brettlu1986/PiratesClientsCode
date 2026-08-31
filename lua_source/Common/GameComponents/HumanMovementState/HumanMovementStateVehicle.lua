local luaclass = require("luaclass")
local HumanMovementStateBase = dynamic_require("HumanMovementStateBase")
local HumanMovementStateVehicle = luaclass("HumanMovementStateVehicle", HumanMovementStateBase)

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local TeamWatchServerHelper = require("TeamWatchServerHelper")

local Timer = require("Timer")
local HumanMovementStateType = require("HumanMovementStateType")
local HumanVehicleHelper = require("HumanVehicleHelper")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")

-- local SAFE_DETACH_DISTANCE = 7

HumanMovementStateVehicle.nLastState = 0
HumanMovementStateVehicle.DetachSpeed = 0

-------------------------------------------------------------------------------

function HumanMovementStateVehicle:Init(tbOwner)
    HumanMovementStateVehicle.super.Init(self, tbOwner)
    -- self.Owner.OnVehicleStateChanged:Bind(OnVehicleStateChange, self)
end

function HumanMovementStateVehicle:UnInit(tbOwner)
    Timer.StopOwnerAllTimer(self, true)

    HumanMovementStateVehicle.super.UnInit(self, tbOwner)
end

function HumanMovementStateVehicle:Active(tbParams)
    self:ChangeCapsule()
    -- self:SetOnVehicleCapsule(true)
    self.pOwnerActor.bCanFalling = false
    self.Owner.bStartFalling = false 

    local GamePlayer = self.GamePlayer

    if GlobalVariableSystem:IsServerLogic() then
        BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(GamePlayer)
        BattleHumanWeaponSystemNew:SetCurrentWeapon(GamePlayer, 0, true)
        TeamWatchServerHelper.NotifyViewersGetInVehicle(GamePlayer, GamePlayer.GameVehicleComponent:GetVehicleInstanceId(), true)
    end
end

function HumanMovementStateVehicle:UnActive(tbParams)
    -- self:SetOnVehicleCapsule(false)
    HumanVehicleHelper.ClearVehicle(self.GamePlayer)
    self.pOwnerActor.bCanFalling = true
    Timer.StopOwnerAllTimer(self, true)

    local GamePlayer = self.GamePlayer
    if GlobalVariableSystem:IsServerLogic() then
        local SaveWeapon = BattleHumanWeaponSystemNew:GetSavedCurrentWeaponFromOwner(self.GamePlayer)
        if SaveWeapon ~= 0 then 
            BattleHumanWeaponSystemNew:SetCurrentWeapon(self.GamePlayer, SaveWeapon)
        end
        TeamWatchServerHelper.NotifyViewersGetInVehicle(GamePlayer, GamePlayer.GameVehicleComponent:GetVehicleInstanceId(true), false)
    end
end

function HumanMovementStateVehicle:SetOnVehicleCapsule(bSet)
    local nCapsuleRadius = self.pOwnerActor.CapsuleComponent:GetUnscaledCapsuleRadius()
    local nCapsuleHalfHeight = nCapsuleRadius

    if not bSet then  
        local tbVehicleCapsuleData = HumanCapsuleDataTable:GetTemplate(self.GamePlayer:GetHumanTemplateId(), HumanMovementStateType.Vehicle)
        nCapsuleHalfHeight = tbVehicleCapsuleData.nCapsuleHalfHeight
    end 
    self.pOwnerActor.CapsuleComponent:SetCapsuleHalfHeight(nCapsuleHalfHeight)
end 

return HumanMovementStateVehicle