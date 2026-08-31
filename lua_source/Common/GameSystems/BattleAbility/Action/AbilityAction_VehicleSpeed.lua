-----------------------------------------------------
--File Name    : AbilityAction_VehicleSpeed.lua
--Description  : 马移动速度
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_VehicleSpeed = luaclass("AbilityAction_VehicleSpeed", AbilityActionBase)

local GameObjectSystem = dynamic_require("GameObjectSystem")

AbilityAction_VehicleSpeed.nValue = 0

function AbilityAction_VehicleSpeed:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
end

function AbilityAction_VehicleSpeed:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local tbHumanMovementStateComponent = tbCharacter.HumanMovementStateComponent
        if tbHumanMovementStateComponent and tbHumanMovementStateComponent:IsInVehicle() then
            local nVehicleInstanceId = tbHumanMovementStateComponent:GetVehicleInstanceId()
            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
            if tbVehicle then
                local tbVehicleMovementComponent = tbVehicle.VehicleMovementComponent
                if tbVehicleMovementComponent then
                    tbVehicleMovementComponent:ChangeSpeedBuffRatio(self.nValue)
                end
            end
        end
    end, tbParams)
end

function AbilityAction_VehicleSpeed:OnUndo(tbParams)
    self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
        local tbHumanMovementStateComponent = tbCharacter.HumanMovementStateComponent
        if tbHumanMovementStateComponent and tbHumanMovementStateComponent:IsInVehicle() then
            local nVehicleInstanceId = tbHumanMovementStateComponent:GetVehicleInstanceId()
            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
            if tbVehicle then
                local tbVehicleMovementComponent = tbVehicle.VehicleMovementComponent
                if tbVehicleMovementComponent then
                    tbVehicleMovementComponent:ChangeSpeedBuffRatio(- self.nValue)
                end
            end
        end
    end, tbParams)
end

return AbilityAction_VehicleSpeed
