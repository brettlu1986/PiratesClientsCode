local BattleCommandSystem = {}

local Proto = require("DungeonCommonProtoNames")
local DungeonIni = require("DungeonIni")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local tbLastSendTimes = {}
local nSendCommandInterval = DungeonIni.tbUIConfig.nSendCommandInterval

local function IsSenderCDEnd(self, tbSender)
    local nLastSendTime = tbLastSendTimes[tbSender]
    local nCurrentTime = GlobalVariableSystem:GetLocalTime()
    if nLastSendTime then
        return (nCurrentTime - nLastSendTime) >= nSendCommandInterval
    end
    return true
end

local function RecordSendTime(self, tbSender)
    tbLastSendTimes[tbSender] = GlobalVariableSystem:GetLocalTime()
end

local function SendCommand(self, tbSender, tbPacket)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if tbGameMode then
        RecordSendTime(self, tbSender)
    
        local d2c_MulticastTacticsCommand = {}
        d2c_MulticastTacticsCommand.type = tbPacket.type
        d2c_MulticastTacticsCommand.sender_instance_id = tbSender:GetServerInstanceId()
        d2c_MulticastTacticsCommand.target_instance_id = tbPacket.target_instance_id
        tbGameMode:SendRPCToAllTeammate(tbSender, Proto.d2c_MulticastTacticsCommand, d2c_MulticastTacticsCommand, true)
    end
end

function BattleCommandSystem:Init()
    tbLastSendTimes = {}
end

function BattleCommandSystem:Uninit()
    tbLastSendTimes = nil
end

function BattleCommandSystem:RequestSendCommand(nSenderUniqueId, tbPacket)
    local tbSender = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbSender and IsSenderCDEnd(self, tbSender) then
        SendCommand(self, tbSender, tbPacket)
    end
end

return BattleCommandSystem