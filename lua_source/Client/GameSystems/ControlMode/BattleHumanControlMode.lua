local luaclass = require("luaclass")
local ControlModeBase = require("ControlModeBase")
local BattleHumanControlMode = luaclass("BattleHumanControlMode", ControlModeBase)
-- local HandlerManagerHelper = require("HandlerManagerHelper")

local ResourceCacheSystem = require("ResourceCacheSystem")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
local MiniMapSystem = require("MiniMapSystem")

function BattleHumanControlMode:OnActivate(tbParams)
    local tbPlayerSelf = tbParams.tbPlayerSelf
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.NewPlayer)
    log("BattleHumanControlMode activate", tbPlayerSelf.nPlayerId)
    --所有ffa战斗模式都在同一个界面,用发事件的方式来切换各个模式的ui显示
    --UIManager:PushState(UIStateDef.StateName.UI_HUMAN_BATTLE_STATE, nil, true)
    if ResourceCacheSystem.pBPChangeState ~= nil then
        ResourceCacheSystem.pBPChangeState.SetPlayerStateHuman(GWorld)    
    end
    MiniMapSystem:SaveLandId()
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, ControlModeDef.HUMAN)
end

function BattleHumanControlMode:OnDeactivate()
    log("BattleHumanControlMode deactivate")
    --UIManager:PopAllState()
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, ControlModeDef.HUMAN)
end

function BattleHumanControlMode:GetModeType()
    return ControlModeDef.HUMAN
end

return BattleHumanControlMode