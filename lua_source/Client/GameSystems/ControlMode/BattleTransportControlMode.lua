local luaclass = require("luaclass")
local ControlModeBase = require("ControlModeBase")
local BattleTransportControlMode = luaclass("BattleTransportControlMode", ControlModeBase)
-- local HandlerManagerHelper = require("HandlerManagerHelper")



local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")

function BattleTransportControlMode:OnActivate(tbParams)
    local tbPlayerSelf = tbParams.tbPlayerSelf
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.NewPlayer)
    log("BattleTransportControlMode activate", tbPlayerSelf.nPlayerId)
    --所有ffa战斗模式都在同一个界面,用发事件的方式来切换各个模式的ui显示
    -- local tbParam = {
    --     [UIDef.UI_BATTLE_TRANSPORT] =
    --     {
    --         nMinOpenParachuteHeight = tbParams.nMinOpenParachuteHeight,
    --         nMaxOpenParachuteHeight = tbParams.nMaxOpenParachuteHeight,
    --     }
    -- }
    -- UIManager:PushState(UIStateDef.StateName.UI_BATTLE_TRANSPORT, tbParam, true)
    local tbParam = {
        nMinOpenParachuteHeight = tbParams.nMinOpenParachuteHeight,
        nMaxOpenParachuteHeight = tbParams.nMaxOpenParachuteHeight,
        nSeaLevelHeight = tbParams.nSeaLevelHeight
    }
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, ControlModeDef.TRANSPORT, tbParam)
end

function BattleTransportControlMode:OnDeactivate()
    log("BattleTransportControlMode deactivate")
    --UIManager:PopAllState()
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, ControlModeDef.TRANSPORT)
end

function BattleTransportControlMode:GetModeType()
    return ControlModeDef.TRANSPORT
end

return BattleTransportControlMode