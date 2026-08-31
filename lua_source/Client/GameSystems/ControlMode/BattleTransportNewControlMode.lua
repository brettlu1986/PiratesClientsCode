local luaclass = require("luaclass")
local ControlModeBase = require("ControlModeBase")
local BattleTransportNewControlMode = luaclass("BattleTransportNewControlMode", ControlModeBase)
-- local HandlerManagerHelper = require("HandlerManagerHelper")



local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")

function BattleTransportNewControlMode:OnActivate(tbParams)
    local tbPlayerSelf = tbParams.tbPlayerSelf
    log("BattleTransportNewControlMode activate", tbPlayerSelf.nPlayerId)

    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, ControlModeDef.TRANSPORTNEW, tbParams)
end

function BattleTransportNewControlMode:OnDeactivate()
    log("BattleTransportNewControlMode deactivate")
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, ControlModeDef.TRANSPORTNEW)
end

function BattleTransportNewControlMode:GetModeType()
    return ControlModeDef.TRANSPORTNEW
end

return BattleTransportNewControlMode