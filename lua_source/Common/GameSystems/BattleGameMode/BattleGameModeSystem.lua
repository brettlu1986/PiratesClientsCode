local luaclass = require("luaclass")
local BattleGameModeSystem = luaclass("BattleGameModeSystem")
local BattleGameStatePropertyBinder = require("BattleGameStatePropertyBinder")
local DungeonDataTable = require("DungeonDataTable")
local DungeonTypeDataTable = require("DungeonTypeDataTable")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local PathNodeSystem = require("PathNodeSystem")
local SpawnerSystem = require("SpawnerSystem")
local DungeonIni = require("DungeonIni")
local Timer = require("Timer")
local GameObjectSystem = dynamic_require("GameObjectSystem")


BattleGameModeSystem.tbGameMode = nil
BattleGameModeSystem.tbGameState = nil
BattleGameModeSystem.nDungeonId = nil
BattleGameModeSystem.tbJsonTableFile = nil
BattleGameModeSystem.GameStartTimeoutTimer = nil
BattleGameModeSystem.tbPlayerState = nil
BattleGameModeSystem.tbGameInitData = nil
BattleGameModeSystem.szDungeonSessionId = nil
BattleGameModeSystem.szShortDungeonSessionId = nil
BattleGameModeSystem.tbGameStatePropertyBinder = nil

BattleGameModeSystem.tbPlayerReLogining = nil

function BattleGameModeSystem:Init()
    self.tbGameMode = nil
    self.tbGameState = nil
    self.tbPlayerState = {}
    self.tbPlayerReLogining = {}
    self.tbGameStatePropertyBinder = BattleGameStatePropertyBinder
    self.tbGameStatePropertyBinder:Init()

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_FINISHED, self, self.OnGameModeFinished)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, self.OnAllPlayerLogout)
    return true
end

function BattleGameModeSystem:Uninit()
    self.tbGameStatePropertyBinder:Uninit()
    self.tbGameStatePropertyBinder = nil
    self.tbPlayerReLogining = nil
    
    self:UninitGameMode()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_FINISHED, self, self.OnGameModeFinished)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, self.OnAllPlayerLogout)
end

function BattleGameModeSystem:SetDungeonSessionId(szDungeonSessionId)
    self.szDungeonSessionId = szDungeonSessionId
    if szDungeonSessionId then
        -- 暂时做截取，之后可以考虑用base64压缩uuid
        self.szShortDungeonSessionId = string.sub(szDungeonSessionId, 1, 23)
    else
        self.szShortDungeonSessionId = nil
    end
end

function BattleGameModeSystem:GetDungeonSessionId()
    return self.szDungeonSessionId
end

function BattleGameModeSystem:GetShortDungeonSessionId()
    return self.szShortDungeonSessionId
end

function BattleGameModeSystem:GetDungeonTemplateData()
    local tbDungeonData = DungeonDataTable:GetTemplate(self.nDungeonId)
    if(tbDungeonData == nil) then
        logerror("BattleGameModeSystem:InitGameMode failed, invalid dungeon id", self.nDungeonId)
        return nil
    end

    local nSubDungeonId = tbDungeonData.nSubId
    local tbDugeonTypeData = DungeonTypeDataTable:GetTemplate(nSubDungeonId)
    if(tbDugeonTypeData == nil) then
        logerror("BattleGameModeSystem:InitGameMode failed, can not find sub id info", nSubDungeonId)
        return nil
    end

    return tbDungeonData, tbDugeonTypeData
end

function BattleGameModeSystem:NoCheckPlayerEnter()
    return false
end

local function InitStartGameTimeoutTimer(self)
    if self:NoCheckPlayerEnter() then
        return true;
    end
    local nTimeout = DungeonIni.tbDungeon.nGameStartTimeout
    log("BattleGameModeSystem InitStartGameTimeoutTimer", nTimeout, " seconds.")
    if nTimeout <= 0 then
        logerror("BattleGameModeSystem InitStartTimeoutTimer failed", self.nDungeonId, ". Dungeon game start timeout not set.")
        return false
    end
    if self.GameStartTimeoutTimer then
        logwarning("BattleGameModeSystem InitStartTimeoutTimer GameStartTimeoutTimer not nil. Clear it.")
        self.GameStartTimeoutTimer:Clear()
    end
    local GameStartTimeout = function()
        logwarning("BattleGameModeSystem GameStartTimeout Send No_Player_Login event")
        self.GameStartTimeoutTimer = nil
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_NO_PLAYER_ENTER)
    end
    self.GameStartTimeoutTimer = Timer.NewTimer(GameStartTimeout, nTimeout, false)
    return true
end

function BattleGameModeSystem:InitGameMode(pGameMode, nDungeonId, nDungeonMode)
    log("BattleGameModeSystem:InitGameMode", nDungeonId)

    self.nDungeonId = nDungeonId
    local tbDungeonData, tbDugeonTypeData = self:GetDungeonTemplateData()
    if(tbDungeonData == nil or tbDugeonTypeData == nil) then
        logerror('BattleGameModeSystem:InitGameMode() tbDungeonData == nil or tbDugeonTypeData')
        return nil
    end

    DungeonDataTable:SetMode(nDungeonId, nDungeonMode)
    -- 加载json
    local tbDescriptor = DungeonDataTable:GetDescriptor(nDungeonId)
    if(tbDescriptor == nil) then
        error("Cannot find dungeon descriptor, dungeon id: "..nDungeonId)
    end
    local tbJsonTableFile = {}
    tbJsonTableFile.tbContainer = tbDescriptor  -- 这里是因为历史原因才故意搞成这样，要不然使用这个json结构的所有地方都得改一遍
    self.tbJsonTableFile = tbJsonTableFile
    if(tbJsonTableFile) then
        SpawnerSystem:ParseJson(tbDescriptor)
        PathNodeSystem:ParseJson(tbDescriptor)
    end

    -- 初始化GameState
    local tbGameState = self:InitGameState(pGameMode.GameState, tbDugeonTypeData.szGameStateClass)
    if (tbGameState == nil) then
        logerror('BattleGameModeSystem:InitGameMode() tbGameState == nil')
        return nil
    end
    tbGameState.rGameStateBaseInfo.nDungeonId = nDungeonId
    pGameMode.GameState.DungeonMode = nDungeonMode

    -- 初始化gamemode
    local tbGameMode = dynamic_require(tbDugeonTypeData.szGameModeClass)()
    self.tbGameMode = tbGameMode
    tbGameMode:SetDungeonData(tbDungeonData)
    if (not tbGameMode:Init(tbDungeonData.nSubId, pGameMode, tbGameState, tbJsonTableFile, tbDungeonData)) then
        logerror("BattleGameModeSystem:InitGameMode init gamemode failed", nDungeonId)
        return nil
    end

    -- 设置保护机制，若长时间没有玩家登陆，则结束游戏
    if not InitStartGameTimeoutTimer(self) then
        logerror("BattleGameModeSystem:InitGameMode init gamemode failed", nDungeonId, ". InitStartGameTimeoutTimer failed.")
        return nil
    end

    return tbGameMode
end

function BattleGameModeSystem:UninitGameMode()
    log("BattleGameModeSystem:UninitGameMode")

    self.bStartStep = false

    self.nDungeonId = nil

    if(self.tbGameMode) then
        self.tbGameMode:Uninit()
        self.tbGameMode = nil
    end
    if(self.tbGameState) then
        self.tbGameState:Uninit()
        self.tbGameState = nil
    end

    self.tbJsonTableFile = nil

    if(self.GameStartTimeoutTimer) then
        self.GameStartTimeoutTimer:Clear()
        self.GameStartTimeoutTimer = nil
    end


    self:ClearAllPlayerState()
    SpawnerSystem:DestroyAll()
    PathNodeSystem:Clear()
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_END_PLAY)

    self.tbGameInitData = nil
    GameObjectSystem:DestroyAll()
end

function BattleGameModeSystem:GetGameMode()
    return self.tbGameMode
end

function BattleGameModeSystem:GetGameState()
    return self.tbGameState
end

function BattleGameModeSystem:InitGameState(pGameState, szClassName)
    log("BattleGameModeSystem:InitGameState", szClassName)
    local Class = require(szClassName)
    if(Class == nil) then
        error("BattleGameModeSystem:CreateGameState failed, can not create class".. szClassName)
        return nil
    end
    local tbGameState = Class()
    tbGameState:Init(pGameState)
    self.tbGameState = tbGameState
    return tbGameState
end

--创建playerstate如果在当前副本没有填写playerstate 不会创建相关的类
function BattleGameModeSystem:InitPlayerState(nPlayerId, pPlayerState, tbGamePlayer)
    local tbPlayerState = self.tbPlayerState[nPlayerId]
    if tbPlayerState ~= nil then
        log("repeat Create GamePlayerState")
        return tbPlayerState
    end
    local szPlayerStateClass = self:GetPlayerStateClassName()
    if szPlayerStateClass == nil then
       return nil
    end
    local Class = require(szPlayerStateClass)
    if(Class == nil) then
        error("BattleGameModeSystem:InitPlayerState failed, can not create class".. szPlayerStateClass)
        return nil
    end

    --log("BattleGameModeSystem:InitPlayerState", nPlayerId, szPlayerStateClass, tbGamePlayer)
    tbPlayerState = Class()
    tbPlayerState:Init(pPlayerState)
    pPlayerState.PiratePlayerId = nPlayerId
    if tbGamePlayer and tbGamePlayer.BattlePlayerStateComponent ~= nil then
        tbGamePlayer.BattlePlayerStateComponent:SetGamePlayerState(tbPlayerState)
    end
    self.tbPlayerState[nPlayerId] = tbPlayerState
    return tbPlayerState
end

--根据dungeonid返回palyerstate所要创建的类名
function BattleGameModeSystem:GetPlayerStateClassName()
    local tbDungeonData, tbDugeonTypeData = self:GetDungeonTemplateData()
    if(tbDungeonData == nil or tbDugeonTypeData == nil) then
        logerror('BattleGameModeSystem:InitPlayerState tbDungeonData == nil or tbDugeonTypeData  nDungeonId : ' , self.nDungeonId)
        return nil
    end

    if string.len(tbDugeonTypeData.szPlayerStateClass) == 0 then
        return nil
    end

    return tbDugeonTypeData.szPlayerStateClass
end

--根据playerID 返回playerstate
function BattleGameModeSystem:GetPlayerState(nplayerID)
    return self.tbPlayerState[nplayerID]
end

--删除playerstate
function BattleGameModeSystem:UninitPlayerState(nPlayerId, tbGamePlayer)
    if self.tbPlayerState == nil then
        return false
    end

    local tbPlayerState = self.tbPlayerState[nPlayerId]
    if (tbPlayerState == nil) then
        return false
    end

    --log("BattleGameModeSystem:UninitPlayerState", nPlayerId, tbGamePlayer)

    if tbGamePlayer and tbGamePlayer.BattlePlayerStateComponent ~= nil then
        tbGamePlayer.BattlePlayerStateComponent:SetGamePlayerState(nil)
    end

    tbPlayerState:Uninit()
    self.tbPlayerState[nPlayerId] = nil
    return true
end

--删除所有playerstate
function BattleGameModeSystem:ClearAllPlayerState()
    if self.tbPlayerState ~= nil then
        for Index, playerstate in pairs(self.tbPlayerState) do
            if playerstate ~= nil then
                playerstate:Uninit()
            end
        end
        self.tbPlayerState = nil
    end
end

function BattleGameModeSystem:OnGameModeFinished()

end

function BattleGameModeSystem:OnAllPlayerLogout()
    self:UninitGameMode()
end

function BattleGameModeSystem:OnPlayerLogin(tbGamePlayer)
    local BotAISystem = dynamic_require("BotAISystem")
    local GameStartTimeoutTimer = self.GameStartTimeoutTimer
    if GameStartTimeoutTimer and (not BotAISystem:IsBot(tbGamePlayer)) then
        GameStartTimeoutTimer:Clear()
        self.GameStartTimeoutTimer = nil
    end

    local nPlayerId = tbGamePlayer.nPlayerId
    if self.tbPlayerReLogining[nPlayerId] then
        --已经存在，是重连操作
        self.tbPlayerReLogining[nPlayerId] = nil

        self.tbGameMode:OnPlayerReLogin(tbGamePlayer)
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, tbGamePlayer)
    else
        --Login流程
        local pUEController = tbGamePlayer:GetUEController()
        if pUEController ~= nil then
            self:InitPlayerState(nPlayerId, pUEController.PlayerState, tbGamePlayer)
        else
            -- Do not create player state if pUEController is nil. E.g. bot player has no controller.
            log("BattleGameModeSystem:OnPlayerLogin player", nPlayerId, " login with no controller. Skip creating player state.")
        end
        self.tbGameMode:OnPlayerLogin(tbGamePlayer)
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, tbGamePlayer)
    end
end

function BattleGameModeSystem:OnPlayerLogout(tbGamePlayer)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, tbGamePlayer)
    self.tbGameMode:OnPlayerLogout(tbGamePlayer)
    --self:UninitPlayerState(tbGamePlayer.nPlayerId, tbGamePlayer)
end

function BattleGameModeSystem:OnEndPlay()
    if(self.tbGameMode) then
        self:UninitGameMode()
    end
end

function BattleGameModeSystem:CreatePlayerSelf(tbPrepareInfo,
        pController, nControllerNetGuid, nControllerUniqueId)

    return self.tbGameMode:CreatePlayerSelf(tbPrepareInfo,
        pController, nControllerNetGuid, nControllerUniqueId)
end

function BattleGameModeSystem:SpawnPlayerPawn(tbGamePlayer, bPossess)
    return self.tbGameMode:SpawnPlayerPawn(tbGamePlayer, bPossess)
end

function BattleGameModeSystem:StartPlay()
    if(self.tbGameMode) then
        log("BattleGameModeSystem StartFirstStep")
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_PRE_START_PLAY)
        self.tbGameMode:StartFirstStep()
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_START_PLAY)
    end
end

-- 属性在 GameInitDataDataTable 中
function BattleGameModeSystem:GetGameInitData()
    return self.tbGameInitData or {}
end

function BattleGameModeSystem:IsPlayerBot(nPlayerId)
    if nPlayerId and self.tbGameState and self.tbGameState.rBotInfo and self.tbGameState.rBotInfo.tbBotIds then
        for _,v in ipairs(self.tbGameState.rBotInfo.tbBotIds) do
            if v == nPlayerId then
                return true
            end
        end
    end
    return false
end

function BattleGameModeSystem:OnRecvInvalidData(tbGameObject, szInfo)
end

function BattleGameModeSystem:OnHumanIllegalAttack(Character, szReason)
    -- TODO: 先error着，等测好了在改成别的
    logerror(string.format("HumanIllegalAttack, name: %s, instanceid: %d, playerid: %d, objecttype: %d, reason: %s",
        Character.szName,
        Character.nServerInstanceId,
        Character.nPlayerId ~= nil and Character.nPlayerId or -1,
        Character.ObjectType,
        szReason))
end

function BattleGameModeSystem:GetCurrentDungeonId()
    return self.nDungeonId
end

function BattleGameModeSystem:ReLoginPossessGamePlayer(tbPlayer)
    return self.tbGameMode:ReLoginPossessGamePlayer(tbPlayer)
end

function BattleGameModeSystem:GetGameStatePropertyBinder()
    return self.tbGameStatePropertyBinder
end

function BattleGameModeSystem:SetPlayerReLoading(nPlayerId, bReLogining)
    self.tbPlayerReLogining[nPlayerId] = bReLogining
end

return BattleGameModeSystem