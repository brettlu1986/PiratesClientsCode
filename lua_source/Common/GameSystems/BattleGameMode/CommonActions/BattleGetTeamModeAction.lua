local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGetTeamModeAction = luaclass("BattleGetTeamModeAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattleGetTeamModeAction.szResultKey = nil

function BattleGetTeamModeAction:Parse(tbJsonData)
    self.szResultKey = tbJsonData.ResultKey
    return string.len(self.szResultKey) > 0
end

function BattleGetTeamModeAction:Execute()
    local nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId

    if not nTeamModeId then
        nTeamModeId = 2 --Mock
    end

    local szKey = self.szResultKey
    BattleOperationHelper:PrintLog(self, "ResultKey: "..szKey..", TeamMode: "..nTeamModeId)
    return BattleBlackboard:SetNumber(szKey, nTeamModeId)
end

return BattleGetTeamModeAction