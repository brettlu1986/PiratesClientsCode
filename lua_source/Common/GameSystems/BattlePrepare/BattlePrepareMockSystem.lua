-- 用于伪造准备阶段的玩家数据
local luaclass = require("luaclass")
local BattlePrepareMockSystem = luaclass("BattlePrepareMockSystem")

local StringUtil = require("StringUtil")
local CommonEventDef = require("CommonEventDef")
local BattlePrepareSystem = require("BattlePrepareSystem")
local BattlePlayerPrepareInfoMockData = require("BattlePlayerPrepareInfoMockData")
local SelfEventHelperClass = require("SelfEventHelper")
local SpawnerSystem = require("SpawnerSystem")
local DungeonDifficultyDataTable = require("DungeonDifficultyDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattlePrepareMockSystem.SelfEventHelper = nil

function BattlePrepareMockSystem:OnMockPlayerData(nPlayerId, szPlayerName)
    log("BattlePrepareMockSystem:OnMockPlayerData", nPlayerId, szPlayerName)

    -- add new mock info to PrepareSystem
    local bInfoNotExist = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId) == nil
    if bInfoNotExist then
        local tbNewInfo = BattlePlayerPrepareInfoMockData:GetInstanceInfo(nPlayerId)
        if not StringUtil.IsEmptyString(szPlayerName) then
            tbNewInfo.szPlayerName = szPlayerName
        end
        BattlePrepareSystem:AddPlayerPrepareInfo(tbNewInfo)
    end
end

local function OnMockApproveLogin(tbInOutParams)
    log("BattlePrepareMockSystem:OnMockApproveLogin")
    tbInOutParams.bSkipApproveLogin = true
end

local function OnPlayerLogout(self, tbPlayer)
    BattleGameModeSystem:UninitPlayerState(tbPlayer.nPlayerId, tbPlayer)
end

local function OnGameModePreStartPlay()
    -- Spawn Npc之前根据DifficultyLevel替换成新的nTemplateId
    -- Init时候可以塞入值到BattleGameModeSystem.tbGameInitData["difficulty"],
    -- 但是此时无法获得pGameMode
    local pGameMode = GameplayStatics.GetGameMode(GWorld)
    if pGameMode and pGameMode.ParseInitOptions then
        local szDifficulty = pGameMode:ParseInitOptions("DifficultyLevel")
        if string.len(szDifficulty) > 0 then
            local tbAll = SpawnerSystem:GetAllSpawners()
            for _, Spawner in pairs(tbAll) do
                if Spawner.nDifficultyId and Spawner.nDifficultyId > 0  then
                    local nNewTemplateId = DungeonDifficultyDataTable:GetNpc(Spawner.nDifficultyId, szDifficulty)
                    Spawner.tbCreateParams.TemplateId = nNewTemplateId
                    Spawner.nTemplateId = nNewTemplateId
                    log("Npc nTemplateId changed by DifficultyLevel", Spawner.nDifficultyId, szDifficulty, nNewTemplateId)
                end
            end
        end
    end
end

local function RegistEvents(self)
    local SelfEventHelper = SelfEventHelperClass()
    self.SelfEventHelper = SelfEventHelper
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_TRY_MOCK_PLAYER_DATA, self, self.OnMockPlayerData)
    SelfEventHelper:RegisterEventFunc(CommonEventDef.EV_GAME_MODE_TRY_MOCK_APPROVE_LOGIN, OnMockApproveLogin)
    SelfEventHelper:RegisterEventFunc(CommonEventDef.EV_GAME_MODE_PRE_START_PLAY, OnGameModePreStartPlay)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, OnPlayerLogout)
end

function BattlePrepareMockSystem:Init()
    BattlePlayerPrepareInfoMockData:LoadTemplateInfo()
    RegistEvents(self)
end

function BattlePrepareMockSystem:Uninit()
    self.SelfEventHelper:UnregisterAll()
end

return BattlePrepareMockSystem