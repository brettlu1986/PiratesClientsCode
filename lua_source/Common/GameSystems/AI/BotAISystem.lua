local luaclass = require("luaclass")
local BotAISystem = luaclass("BotAISystem")
local SelfEventHelperClass  = require("SelfEventHelper")
local CommonEventDef        = require("CommonEventDef")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local BattlePrepareSystem   = require("BattlePrepareSystem")
local Timer                 = require("Timer")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local BotNameDataTable      = require("BotNameDataTable")
local BotTemplateDataTable  = require("BotTemplateDataTable")
local BotInitItemRandomDataTable = require("BotInitItemRandomDataTable")
local InitItemDataTable     = require("InitItemDataTable")
local BotGroupDataTable     = require("BotGroupDataTable")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local SAILogicDef           = require("SAILogicDef")
local AIVariableSystem      = require("AIVariableSystem")
local InitItemIni           = require("InitItemIni")
local BattleItemSystemServer = require("BattleItemSystemServer")
local AIHelper              = require("AIHelper")
local AIPreparationHelper   = require("AIPreparationHelper")
local AvatarRandomDataTable = require("AvatarRandomDataTable")
local HumanDataTable        = require("HumanDataTable")


local bTickLoginOut = false
local nBotLogoutIntervalInSeconds = 0.1

local nMaxReplicatesLimitCount = 30
local nBotTeamBaseId = 1000

BotAISystem.tbBots = nil
BotAISystem.SelfEventHelper = nil
BotAISystem.bBotLogoutStart = false
BotAISystem.pBotLogoutTimerHandle = nil
BotAISystem.tbBotNames = nil
BotAISystem.nSpawnTimer = nil
BotAISystem.bShowBotName = false
BotAISystem.nTeamSize = 1
BotAISystem.bBornWithInitItem = true

local function LOG(...)
    log("CJ->BotAISystem:", ...)
end


local function GetBotName(self, nBotIndex)
    return self.tbBotNames[nBotIndex + 1] or ("Bot_" .. nBotIndex + 1)
end


local function CreateBotPrepareInfo(nPlayerId, nAITemplateId, szPlayerName, nGroupIndex)
    local tbBotTemplate = BotTemplateDataTable:GetTemplate(nAITemplateId)
    assert(tbBotTemplate)
    local nHumanId = BotTemplateDataTable:GetRandomHumanId(nAITemplateId)

    local tbPrepareInfo = BattlePrepareSystem:CreatePlayerInfo(
        nPlayerId,
        szPlayerName,
        nHumanId,
        nGroupIndex)
    tbPrepareInfo:SetInitItems(InitItemDataTable:GetItems(InitItemIni.tbPrepareScene.nInitItemGroupId))      -- TODO:需替换成根据dungeonid来获得
    tbPrepareInfo:AddShipPreparation(AIPreparationHelper.GetShipPreparation())
    local tbHumanResTemplate = HumanDataTable:GetResData(nHumanId)
    tbPrepareInfo:SetAppearanceFromPartData(tbHumanResTemplate.tbAppearance)
    local nFashionPoolId = tbBotTemplate.nFashionPoolId
    local tbFashionTemplateIds = AvatarRandomDataTable:RandomAvatar(nFashionPoolId)
    tbPrepareInfo:SetHumanFashion(tbFashionTemplateIds)
    tbPrepareInfo:SetIsBot()
    return tbPrepareInfo
end

local function ResetInitItemsToFormal(self)
    local tbBots = self.tbBots
    for i, tbBot in ipairs(tbBots) do
        local AIComponent = tbBot.SAIComponent
        if AIComponent:IsEnabled() and AIHelper:ShouldSkipParachute(tbBot) then -- Skip Parachute 说明不是队友，可以给初始武器；队友不给武器，否则跳伞阶段就能看到拿着武器.
            local nBotTemplateId = AIComponent:GetLogic().nTemplateId
            local tbBotTemplate = BotTemplateDataTable:GetTemplate(nBotTemplateId)
            local tbPrepareInfo = tbBot.tbPrepareInfo
            tbPrepareInfo:SetInitItems(BotInitItemRandomDataTable:GetRandomItems(tbBotTemplate.nItemRandomId))
            BattleItemSystemServer:ResetBattleItemsFromPrepareInfo(tbBot:GetServerInstanceId())
        end
    end
    LOG("ResetInitItemsToFormal")
end

function BotAISystem:IsBot(tbGameObject)
    if tbGameObject.nPlayerId then
        return BattlePrepareSystem:IsBot(tbGameObject.nPlayerId)
    end
    return false
end

function BotAISystem:HasRealPlayer()
   local tbGameMode = BattleGameModeSystem:GetGameMode()
   if tbGameMode.CheckAllPlayerLogout then
       return not tbGameMode:CheckAllPlayerLogout()
   end

    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbGameObject,_  in pairs(tbGameObjects) do
        if not self:IsBot(tbGameObject) then
            return true
        end
    end
    return false
end

function BotAISystem:InitBotNames(nNumBot)
    self.tbBotNames = BotNameDataTable:RandomName(nNumBot)
end

function BotAISystem:GetAllBots()
    return self.tbBots
end

function BotAISystem:RemoveBot(tbGameObject)
    if self:IsBot(tbGameObject) then
        local AIComponent = tbGameObject.SAIComponent
        AIComponent:StopAI()
        AIComponent:DestroyAI()
        for i,v in ipairs(self.tbBots) do
            if v == tbGameObject then
                table.remove(self.tbBots, i)
                break
            end
        end
        LOG("remove bot ", tbGameObject.szName)
    end
end

function BotAISystem:CreateBot(szName, nAITemplateId, nGroupIndex)
    local nNumBot = #self.tbBots
    local nPlayerId = -(nNumBot + 1)
    local szPlayerName = szName or GetBotName(self, nNumBot)

    if not nGroupIndex then
        nGroupIndex =  nBotTeamBaseId + nNumBot // self.nTeamSize
    end

    local tbBotPrepareInfo = CreateBotPrepareInfo(nPlayerId, nAITemplateId, szPlayerName, nGroupIndex)
    local tbBot = BattleGameModeSystem:CreatePlayerSelf(tbBotPrepareInfo, nil, nil, 0)

    if not tbBot then
        logerror("BotAISystem:CreateBot:create gameobject failed, the returned bot is nil:", szName)
        return
    end

    table.insert(self.tbBots, tbBot)
    local bRet = BattleGameModeSystem:SpawnPlayerPawn(tbBot, false)
    if not bRet then
        logerror("BotAISystem:CreateBot:spawn bot actor failed, return false:", szName)
        return
    end
    tbBot.bIsBot = true
    BattleGameModeSystem:OnPlayerLogin(tbBot)
    tbBot.SAIComponent:EnableAI(SAILogicDef.Bot, nAITemplateId)
    return tbBot
end

function BotAISystem:Possess(tbBot, nAITemplateId)
    if not tbBot then
        logerror("BotAISystem:Possess:possess gameobject failed, the bot is nil.")
        return
    end

    table.insert(self.tbBots, tbBot)
    tbBot.SAIComponent:EnableAI(SAILogicDef.Bot, nAITemplateId)
end

function BotAISystem:DestroyAll()
    LOG("destroy all ai...")
    local tbBots = self.tbBots
    for i, tbBot in ipairs(tbBots) do
        if not tbBot:IsDead() then
            local AIComponent = tbBot.SAIComponent
            AIComponent:StopAI()
            AIComponent:DestroyAI()
        end
    end
    self.tbBots = {}
end

function BotAISystem:KickoutAllBot()
    if self.bBotLogoutStart then
        return
    end
    self:ClearSpawnTimer()
    self:DestroyAll()
    assert(self.pBotLogoutTimerHandle == nil, "BotAISystem:OnPlayerPostLogout start bot logout timer more than once.")
    LOG("start bot logout since no real players existing. Logout interval:", nBotLogoutIntervalInSeconds, "seconds.")
    self.bBotLogoutStart = true
    if bTickLoginOut then
        self.pBotLogoutTimerHandle = Timer.NewTimer(function()
            local tbPlayer = nil
            local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
            for k,v in pairs(tbGameObjects) do
                if k then
                    tbPlayer = k
                    break
                end
            end
            if not tbPlayer then
                logerror("BotAISystem:OnPlayerPostLogout logging out player is nil")
                return
            end
            if self:IsBot(tbPlayer) then
                LOG("Logout bot player. PlayerId:", tbPlayer.nPlayerId)
                BattleGameModeSystem:OnPlayerLogout(tbPlayer)
            else
                LOG("Real player appears in logout bot phase. Kick it. PlayerId:", tbPlayer.nPlayerId)
                BattleGameModeSystem:KickPlayer(tbPlayer)
            end
        end, nBotLogoutIntervalInSeconds, true)
    else
        self.pBotLogoutTimerHandle = Timer.NewTimer(function()
            local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
            for tbGameObject, _ in pairs(tbGameObjects) do
                if tbGameObject.bIsBot then
                    BattleGameModeSystem:OnPlayerLogout(tbGameObject)
                end
            end
            if self.pBotLogoutTimerHandle then
                self.pBotLogoutTimerHandle:Clear()
                self.pBotLogoutTimerHandle = nil
            end
        end, nBotLogoutIntervalInSeconds, false)
    end
end

function BotAISystem:OnPlayerPostLogout(nPlayerId, nGroupIndex)
    local tbBots = self.tbBots
    for i, tbBot in ipairs(tbBots) do
        if tbBot.nPlayerId == nPlayerId then
            LOG("bot logout. remove it from bot system.", i, nPlayerId)
            table.remove(tbBots, i)
            return
        end
    end
    if not AIVariableSystem:IsBattleStarted() then
        return
    end
    if self:HasRealPlayer() then
        return
    end
    self:KickoutAllBot()
end


function BotAISystem:ClearSpawnTimer( ... )
    if self.nSpawnTimer then
        self.nSpawnTimer:Clear()
        self.nSpawnTimer = nil
    end
end

function BotAISystem:OnPreDungeonRelease()
    LOG("pre dungeon release")
    self:ClearSpawnTimer()
end

function BotAISystem:GetBotCount()
    return #self.tbBots
end



function BotAISystem:SetBotTeamSize(nTeamSize)
    self.nTeamSize = nTeamSize
    LOG("set bot teamsize ", nTeamSize)
end

function BotAISystem:GetMaxBotCount()
    return 100
end

function BotAISystem:ConfigReplicatesInfo(nCount)
    AIVariableSystem.nReplicatesLimitCount = math.max(0, nMaxReplicatesLimitCount - (self:GetMaxBotCount() - nCount))
    LOG("nReplicatesLimitCount ", self.nReplicatesLimitCount)
end

function BotAISystem:Spawn(nTotalCount, nAIGroupId, nTimeLimit, nGroupIndex)
    assert(nTotalCount > 0, "BotAISystem:Spawn bot count must > 0")
    self:ClearSpawnTimer()
    local tbBotTemplates = { }
    local tbBotKinds = BotGroupDataTable:GetBotDatas(nAIGroupId, nTotalCount)
    for _,v in ipairs(tbBotKinds) do
        for i=1,v.nCount do
            table.insert(tbBotTemplates, v.nBotTemplateId)
        end
    end
    assert(nTotalCount == #tbBotTemplates, "generate bot template error")
    if nTimeLimit > 0 then
        local nSecondPerBot = nTimeLimit / nTotalCount
        local nSpawnIndex = 1
        self.nSpawnTimer = Timer.NewTimer(function()
            self:CreateBot(GetBotName(self, #self.tbBots), tbBotTemplates[nSpawnIndex], nGroupIndex)
            LOG("spwan bot ",nSpawnIndex, tbBotTemplates[nSpawnIndex])
            nSpawnIndex = nSpawnIndex + 1
            if nSpawnIndex > nTotalCount then
                self:ClearSpawnTimer()
            end
        end, nSecondPerBot, true)
    else
        for i=1,nTotalCount do
            self:CreateBot(GetBotName(self, #self.tbBots), tbBotTemplates[i], nGroupIndex)
            LOG("spwan bot ime",i, tbBotTemplates[i])
        end
    end
end

function BotAISystem:OnEnterTransportStep()
    if not self:HasRealPlayer() then
        self:KickoutAllBot()
        return
    end
    if self.nSpawnTimer then
        self:ClearSpawnTimer()
        logerror("started game when bot has not been spawned over")
    end
    if self.bBornWithInitItem then
        ResetInitItemsToFormal(self)
    end
end

function BotAISystem:OnDisconnectWithHub()
    LOG("BotAISystem:OnDisconnectWithHub Kick out all bots.")
    self:KickoutAllBot()
end

function BotAISystem:OnGameCoreStatusChanged(bEnabled)
    self.bBornWithInitItem = not bEnabled
    LOG("bBornWithInitItem:", self.bBornWithInitItem)
end


function BotAISystem:Init()
    if GlobalVariableSystem:IsServerLogic() then
        BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
        self:InitBotNames(self:GetMaxBotCount())
        local SelfEventHelper = SelfEventHelperClass()
        self.SelfEventHelper = SelfEventHelper
        self.tbBots = {}
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_POST_LOGOUT,      self, self.OnPlayerPostLogout)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP,           self, self.OnEnterTransportStep)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_DISCONNECT_WITH_HUB,         self, self.OnDisconnectWithHub)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT,  self, self.OnPreDungeonRelease)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAMECORE_STATUS_CHANGED,  self, self.OnGameCoreStatusChanged)
    end
    return true
end



function BotAISystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() then
        self.SelfEventHelper:UnregisterAll()
        self:ClearSpawnTimer()
        if self.pBotLogoutTimerHandle then
            self.pBotLogoutTimerHandle:Clear()
            self.pBotLogoutTimerHandle = nil
        end
        self.tbBots = nil
        self.bBotLogoutStart= false
        self.bShowBotName = false
    end
end

return BotAISystem()