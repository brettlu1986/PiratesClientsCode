local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorSetAim = luaclass("GameCorePacketProcessorSetAim", GameCorePacketProcessorAction)

local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSetAim:", ...)
end
-- luacheck: pop

local function IsAiming(tbPlayer)
    if tbPlayer:IsShip() then
        return BattleShipWeaponSystem:GetIsInAim(tbPlayer)
    else
        local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
        if not HumanWeaponComponent then
            LOG("set aim failed!Cannot find bot HumanWeaponComponent", tbPlayer:GetServerInstanceId())
            return false
        end
        return HumanWeaponComponent:IsAiming()
    end
end

local function SetAim(tbPlayer, bIsAim)
    if tbPlayer:IsShip() then
        return BattleShipWeaponSystem:ChangeAimState(tbPlayer, bIsAim)
    else
        local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
        if not HumanWeaponComponent then
            LOG("set aim failed!Cannot find bot HumanWeaponComponent", tbPlayer:GetServerInstanceId())
            return false
        end
        return HumanWeaponComponent:SetAim(bIsAim)
    end
end

function GameCorePacketProcessorSetAim:DoAction(tbPacket)
    local tbAgent = self.tbAgent:GetGameObject()
    local bIsAim = tbPacket.is_aim

    if IsAiming(tbAgent) == bIsAim then
        LOG("set aim failed! state is same", tbAgent:GetServerInstanceId(), bIsAim)
    end

    if SetAim(tbAgent, bIsAim) then
        LOG("set aim", tbAgent:GetServerInstanceId(), bIsAim)
    else
        LOG("set aim failed!", tbAgent:GetServerInstanceId(), bIsAim)
    end
end


return GameCorePacketProcessorSetAim