local luaclass = require("luaclass")
local GameModeCppDelegateProcessorClass = require("GameModeCppDelegateProcessor")
local GameModeCppDelegateProcessor_S = luaclass("GameModeCppDelegateProcessor_S", GameModeCppDelegateProcessorClass)
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattlePrepareSystem = require("BattlePrepareSystem")

function GameModeCppDelegateProcessor_S:ApproveLogin(szOptions)
    local ErrorMsg = GameModeCppDelegateProcessor_S.super.ApproveLogin(self, szOptions)
    
    if(ErrorMsg ~= "") then
        return ErrorMsg
    end

    local nPlayerId = self:ParsePlayerId(szOptions)
    if nPlayerId == nil then
        return "Player Id not found."
    end

    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if tbPrepareInfo == nil then
        return "tbPrepareInfo not found: " .. nPlayerId .. ". "
    end

    local szInputToken = GameplayStatics.ParseOption(szOptions, "GameToken")
    local nPlayerToken = tbPrepareInfo.nToken

    if szInputToken == nil then
        return "Token missing. Player id: " .. nPlayerId .. ". "
    end

    local nInputToken = tonumber(szInputToken)
    if nInputToken == nil or nInputToken ~= nPlayerToken then
        return "Token invalid. Player id: " .. nPlayerId
        .. ". Input token: " .. szInputToken
        .. ". Real token: " .. nPlayerToken
    end

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    ErrorMsg = tbGameMode:ApproveLogin(szOptions)
    if(ErrorMsg ~= "") then
        return ErrorMsg
    end

    return ""
end

function GameModeCppDelegateProcessor_S:OnStartGameModeManually(pGameMode, szOptions)
    BattleGameModeSystem:SetDungeonInitData()
    GameModeCppDelegateProcessor_S.super.OnStartGameModeManually(self, pGameMode, szOptions)
end

return GameModeCppDelegateProcessor_S
