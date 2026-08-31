local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetFFAProcessStateAction = luaclass("BattleSetFFAProcessStateAction", BattleActionBase)

local Proto = require("DungeonCommonProtoNames")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local NetworkManager = dynamic_require("NetworkManager")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattleSetFFAProcessStateAction.nState = 0

function BattleSetFFAProcessStateAction:Parse(tbJsonData)
    self.nState = tbJsonData.State

    return true
end

function BattleSetFFAProcessStateAction:Execute()
    BattleOperationHelper:PrintLog(self, "State: "..self.nState)

    local tbGameState = BattleGameModeSystem:GetGameState()
    local nFFAProcessState = tbGameState.nFFAProcessState
    nFFAProcessState:Set(self.nState)

    local tbPacket = {nState = self.nState}
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_FFAProcessStateChanged, tbPacket, false)

    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self.nState)

    return true
end

return BattleSetFFAProcessStateAction