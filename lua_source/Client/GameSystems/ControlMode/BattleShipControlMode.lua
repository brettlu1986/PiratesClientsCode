local luaclass = require("luaclass")
local ControlModeBase = require("ControlModeBase")
local BattleShipControlMode = luaclass("BattleShipControlMode", ControlModeBase)

local ResourceCacheSystem = require("ResourceCacheSystem")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")

function BattleShipControlMode:OnActivate(tbParams)
    local tbPlayerSelf = tbParams.tbPlayerSelf
    log("BattleShipControlMode activate", tbPlayerSelf.nPlayerId)
    --所有ffa战斗模式都在同一个界面,用发事件的方式来切换各个模式的ui显示
    --HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipCommonMode)
    --UIManager:PushState(UIStateDef.StateName.UI_BATTLE_STATE, nil, true)
    if ResourceCacheSystem.pBPChangeState ~= nil then
        ResourceCacheSystem.pBPChangeState.SetPlayerStateShip(GWorld)    
    end    
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, ControlModeDef.SHIP)
end

function BattleShipControlMode:OnDeactivate()
    log("BattleShipControlMode deactivate")
    --UIManager:PopAllState()
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, ControlModeDef.SHIP)
end

function BattleShipControlMode:GetModeType()
    return ControlModeDef.SHIP
end

return BattleShipControlMode