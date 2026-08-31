local luaclass = require("luaclass")
local BattleGameModeSystemClass = require("BattleGameModeSystem")
local BattleGameModeSystem_S = luaclass("BattleGameModeSystem_S", BattleGameModeSystemClass)

local GameInitDataDataTable = require("GameInitDataDataTable")
local DelayTimer = require("DelayTimer")

local szGlobalSettingsPath = "Blueprint'/Game/Framework/Base/BP_GlobalSettings.BP_GlobalSettings_C'"

BattleGameModeSystem_S.tbKickTimerHandle = nil

function BattleGameModeSystem_S:Init()
    BattleGameModeSystem_S.super.Init(self)
    self:SetDungeonInitData()

    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if not pGameInstance.GlobalSettings then
        local pGlobalSettings = ExtendBlueprintFunctions.CreateObject(szGlobalSettingsPath:load(), pGameInstance)
        pGameInstance:InitGlobalSettings(pGlobalSettings)
        log("[GlobalSettings] GlobalSettings initialize in BattleGameModeSystem_S.")
    else
        log("[GlobalSettings] GlobalSettings had initialized. Ignore it.")
    end

    self.tbKickTimerHandle = {}
end

function BattleGameModeSystem_S:Uninit()
    BattleGameModeSystem_S.super.Uninit(self)

    for Key, Value in pairs(self.tbKickTimerHandle) do
        if Value then
            Value:Clear()
        end

        self.tbKickTimerHandle[Key] = nil
    end
    self.tbKickTimerHandle = nil
end

function BattleGameModeSystem_S:UninitGameMode()
    BattleGameModeSystem_S.super.UninitGameMode(self)
    ServerShell.GetServer(GWorld):GetDungeonShell():EndGame()
end

function BattleGameModeSystem_S:SetDungeonInitData()
    local szInitData = ServerShell.GetServer(GWorld):GetDungeonInitData()
    local nGameInitDataId = tonumber(szInitData)
    if nGameInitDataId ~= nil then
        self.tbGameInitData = GameInitDataDataTable:GetTemplate(nGameInitDataId)
    else
        self.tbGameInitData = nil
    end

    if (self.tbGameInitData == nil) then
        log("BattleGameModeSystem_S:SetDungeonInitData nil. nGameInitDataId:", nGameInitDataId)
    else
        log("BattleGameModeSystem_S:SetDungeonInitData. nGameInitDataId:", nGameInitDataId)
    end
end

function BattleGameModeSystem_S:OnRecvInvalidData(tbGameObject, szInfo)
    -- TODO: 踢人逻辑
    if(tbGameObject) then
        error(szInfo..", "..require("dkjson").encode(tbGameObject:GetDebugInfo()))
    else
        error(szInfo)
    end
end

function BattleGameModeSystem_S:KickPlayer(tbPlayer, bAsync, bMakeLogout)
    local KickPlayerFunc = function()
        if tbPlayer then
            log(string.format("KickPlayer playerId: %d, instance id: %d, controller uniqueId: %d",
            tbPlayer:GetPlayerId(), tbPlayer:GetServerInstanceId(), tbPlayer:GetUEControllerUniqueId()))

            --self.tbGameMode:QuitDungeon(tbPlayer, 0)
            if tbPlayer.pUEController then
                ServerShell.GetServer(GWorld):KickPlayer(tbPlayer.pUEController)
            end
            self.tbGameMode:OnKickPlayer(tbPlayer)
            self:OnPlayerLogout(tbPlayer) --需要立即删除，所以要强制模拟Logout事件

            if bAsync then
                local nInstanceId = tbPlayer:GetServerInstanceId()
                self.tbKickTimerHandle[nInstanceId] = nil
            end
        end
    end

    if bAsync then
        local timerHandle = DelayTimer:RunNextTick(KickPlayerFunc)
        local nInstanceId = tbPlayer:GetServerInstanceId()

        if self.tbKickTimerHandle[nInstanceId] then
            self.tbKickTimerHandle[nInstanceId]:Clear()
        end

        self.tbKickTimerHandle[nInstanceId] = timerHandle
    else
        KickPlayerFunc()
    end
end

function BattleGameModeSystem_S:NoCheckPlayerEnter()
    -- 测试模式下，不检查玩家长时间不进入的情况。
    return ServerShell.GetServer(GWorld):IsStressTest()
end

function BattleGameModeSystem_S:SetDungeonSessionId(szDungeonSessionId)
    BattleGameModeSystem_S.super.SetDungeonSessionId(self, szDungeonSessionId)

    ServerShell.GetServer(GWorld):RedirectLogBySession(szDungeonSessionId)
end

return BattleGameModeSystem_S()
