local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorAddBTBot = luaclass("GameCorePacketProcessorAddBTBot", GameCorePacketProcessorBase)

local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local BattlePrepareSystem   = require("BattlePrepareSystem")
local BotTemplateDataTable  = require("BotTemplateDataTable")


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorAddBTBot:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorAddBTBot:Process(tbPacket)
    self:AddBTBot(tbPacket.x, tbPacket.y, tbPacket.z, tbPacket.teamid, tbPacket.ai_template_id, tbPacket.auto_teleport)
end


---[[ AddBTBot related:
local function CreateBotPrepareInfo(nPlayerId, nAITemplateId, szPlayerName, nGroupIndex)
    -- 初始物品
    local tbBotTemplate = BotTemplateDataTable:GetTemplate(nAITemplateId)
    assert(tbBotTemplate)
    local nHumanId = BotTemplateDataTable:GetRandomHumanId(nAITemplateId)

    local tbPrepareInfo = BattlePrepareSystem:CreatePlayerInfo(
        nPlayerId,
        szPlayerName,
        nHumanId,
        nGroupIndex)
    tbPrepareInfo:SetDefaultInitItems()
    tbPrepareInfo:SetDefaultShipPreparation()
    tbPrepareInfo:SetIsBot()
    return tbPrepareInfo
end

function GameCorePacketProcessorAddBTBot:CreateGameObject(nID, nX, nY, nZ, nTeamId, nAITemplateId, bAutoTeleport)
    local nRadius = 0
    if bAutoTeleport then
        nRadius = 100
    end
    local GRID_TYPE_OCEAN = EPiratesGridRegionType.Ocean
    local GRID_TYPE_PORT  = EPiratesGridRegionType.Port
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(nX, nY)
    local bShip = false
    if nRegionType == GRID_TYPE_OCEAN or nRegionType == GRID_TYPE_PORT then
        bShip = true
    end
    local tbBotLocation = nil
    if bShip then
        tbBotLocation = { X = nX, Y =  nY, Z =  nZ }
    else
        local pLocation = ExtendBlueprintFunctions.GetAISafePosition(GWorld, Vector{X = nX, Y = nY, Z = nZ}, nRadius, 20000, -10000)
        tbBotLocation = { X = pLocation.X, Y =  pLocation.Y, Z =  pLocation.Z }
    end

    local nAgentId = -nID
    local szAgentName = ("Agent_BT_" .. nID)
    local nGroupIndex = nTeamId
    local tbBotPrepareInfo = CreateBotPrepareInfo(nAgentId, nAITemplateId, szAgentName, nGroupIndex)
    local tbBot = BattleGameModeSystem:CreatePlayerSelf(tbBotPrepareInfo, nil, nil, 0)
    if not tbBot then
        logerror("GameCorePacketProcessorAddBTBot-> CreateGameObject fail, id ", nID)
        return nil
    end
    if not BattleGameModeSystem:SpawnPlayerPawn(tbBot, false) then
        logerror("GameCorePacketProcessorAddBTBot-> CreateGameObject spawn bot fail, id ", nID)
        return nil
    end
    BattleGameModeSystem:OnPlayerLogin(tbBot)
    tbBot:SetLocation(tbBotLocation.X, tbBotLocation.Y, tbBotLocation.Z)
    if bShip then
        self.tbGameCoreProxyClient.SelfTimerHelper:RunNextTick(function()
            local nShipId = tbBot:GetShipTemplateId()
            BattleGameModeSystem:GetGameMode():ChangeToShip(tbBot, nShipId, Vector{X = nX, Y = nY, Z = nZ})
        end)
    end
    return tbBot
end

function GameCorePacketProcessorAddBTBot:AddBTBot(X, Y, Z, nTeamId, nAITemplateId, bAutoTeleport)
    local SAISystemDef = require("SAISystemDef")
    local BotAISystem = dynamic_require("BotAISystem")
    self.tbGameCoreProxyClient.nBTBotCount = self.tbGameCoreProxyClient.nBTBotCount + 1
    local tbBot = self:CreateGameObject(self.tbGameCoreProxyClient.nBTBotCount, X, Y, Z, nTeamId, nAITemplateId, bAutoTeleport)
    BotAISystem:Possess(tbBot, nAITemplateId)
    local tbParachuteSystem = tbBot.SAIComponent:GetSystem(SAISystemDef.Parachute)
    if tbParachuteSystem then
        tbParachuteSystem:StartBattle()
    end
end
--]]

return GameCorePacketProcessorAddBTBot