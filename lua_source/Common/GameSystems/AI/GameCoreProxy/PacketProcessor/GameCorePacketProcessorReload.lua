local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorReload = luaclass("GameCorePacketProcessorReload", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local HumanWeaponMisc = require("HumanWeaponMisc")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local HumanWeaponType = HumanWeaponMisc.Type

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorReload:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorReload:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        -- if switch to a weapon without bullet try reload first
        local tbCurrentWeapon = tbGameObject.HumanWeaponComponent:GetCurrentWeapon()
        if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.GUN) then
            local tbProperty  = tbCurrentWeapon:GetProperty()
            local nReloadTime = tbProperty.nReloadTime
            tbGameObject.HumanWeaponComponent:Reload(nReloadTime)
            self:ReportActionResult(Proto.ActionType.Reload, 0)
        else
            self:ReportActionResult(Proto.ActionType.Reload, 1)
        end
    else
        local tbWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbGameObject)
        if tbWeapon then
            tbWeapon:LoadBullet()
            self:ReportActionResult(Proto.ActionType.Reload, 0)
        else
            self:ReportActionResult(Proto.ActionType.Reload, 1)
        end
    end
end


return GameCorePacketProcessorReload