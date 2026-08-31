-----------------------------------------------------
--File Name    : AbilityAction_DisableMovement.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-29
--Description  : 禁止人/船移动
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_DisableMovement = luaclass("AbilityAction_DisableMovement", AbilityActionBase)

local function GetMovementComponent(tbCharacter)
    -- local pCharacter = tbCharacter.pUEActor
    -- if pCharacter then
    --     if tbCharacter:IsShip() then
    --         return pCharacter.ShipMovementComponent
    --     else
    --         return pCharacter.CharacterMovement
    --     end
    -- end
    return nil
end

function AbilityAction_DisableMovement:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local pMovementComponent = GetMovementComponent(tbCharacter)
        if pMovementComponent then
            pMovementComponent:SetComponentTickEnabled(false)
        end
    end, tbParams)
end

function AbilityAction_DisableMovement:OnUndo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local pMovementComponent = GetMovementComponent(tbCharacter)
        if pMovementComponent then
            pMovementComponent:SetComponentTickEnabled(true)
        end
    end, tbParams)
end

return AbilityAction_DisableMovement
