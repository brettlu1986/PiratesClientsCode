local luaclass = require("luaclass")
local CppDelegateProcesserBaseClass = require("CPPDelegateProcessorBase")
local BattleGMCppDelegateProcessor = luaclass("BattleGMCppDelegateProcessor", CppDelegateProcesserBaseClass)

local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local PropUtil = require("PropUtil")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local SceneItemActorDef = require("SceneItemActorDef")
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleSpecialToastHelper = require("BattleSpecialToastHelper")
local ProtoDC = require("DungeonCommonProtoNames")
local HumanWeaponItemPropertyHelper = require("HumanWeaponItemPropertyHelper")
local BattleTimerHelper = require("BattleTimerHelper")
local GMSystem = dynamic_require("GMSystem")

local CommandFuncs = {}
local tbOwnerPlayerId = nil
local tbOwnerPlayerName = nil


local function GetPlayerSelfByPlayerController(pPlayerController)
    return GameObjectSystem:FindByUEActor(pPlayerController)
end

local function StartFile(_)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "stat startfile", nil)
end

local function StopFile(_)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "stat stopfile", nil)
end

local function MemReport(_)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "memreport-full", nil)
end

local function StartMallocLeak(_)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "mallocleak.start size=10485760 report=120", nil)
end

local function StopMallocLeak(_)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "mallocleak.stop", nil)
end

local function ReportMallocLeak(_)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "mallocleak.report", nil)
end


local function CreateAction(tbAgent, szAction)
    local Processor = require(szAction)
    Processor:Init()
    Processor.tbAgent = tbAgent
    return Processor
end

local function CreateNpc(tbPlayer, tbParams)
    local nTemplateId = tonumber(tbParams[2])
    if nTemplateId then
        local nLocationX = tonumber(tbParams[3])
        local nLocationY = tonumber(tbParams[4])
        local nLocationZ = tonumber(tbParams[5])
        local nRotationYaw = tonumber(tbParams[6])
        local nPathId = tonumber(tbParams[7])

        local pLocation = EngineExtActorShell.GetActorLocation(tbPlayer.pUEActor)

        nLocationX = nLocationX and (pLocation.X + nLocationX) or pLocation.X
        nLocationY = nLocationY and (pLocation.Y + nLocationY) or pLocation.Y
        nLocationZ = nLocationZ and nLocationZ or pLocation.Z
        nRotationYaw = nRotationYaw and nRotationYaw or 0

        local tbJsonData = {}
        tbJsonData.PathId = nPathId
        tbJsonData.CampType = 0

        local tbSpawnInfo = {}
        tbSpawnInfo.nTemplateId = nTemplateId
        tbSpawnInfo.nX = nLocationX
        tbSpawnInfo.nY = nLocationY
        tbSpawnInfo.nZ = nLocationZ
        tbSpawnInfo.nYaw = nRotationYaw
        --tbSpawnInfo.szName = "Debug"
        tbSpawnInfo.nGroupIndex = 0
        tbSpawnInfo.tbJsonData = tbJsonData
        GameObjectSystem:CreateNpcInGameMode(tbSpawnInfo)
        -- GameObjectSystem:CreateNpcInGameMode(nTemplateId,
        --     nLocationX, nLocationY, nLocationZ, nRotationYaw,
        --     0, "Debug", tbJsonData)
        -- local AIControllerClassPath = "/Game/Game/Ships/AI/BP_PiratesShipAIController.BP_PiratesShipAIController_C"
        -- local AIController = EngineExtActorShell.SpawnActorForScript(GWorld, AIControllerClassPath:load(), Transform(), nil)
        -- AIController:Possess(tbNpc:GetModelActor())
    end
end

local function Createtrigger(_, tbParams)
    local nTemplateId = tonumber(tbParams[2])
    local nRadius = tonumber(tbParams[3])
    if(nTemplateId == nil) then
        return
    end
    if(nRadius == nil) then
        nRadius = 30000
    end

    local Location
    local tbMap = GameObjectSystem:GetAllGameObjects()
    for _nId, tbObject in pairs(tbMap) do
        if(tbObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
            Location = tbObject:GetLocation()
            break
        end
    end

    local tbData = {tbJsonData = {ResId = nTemplateId,
            Transform={X = Location.X, Y = Location.Y, Z = Location.Z},
            Shape = {
                Type = 0,
                Radius = nRadius
            }
        }}
    GameObjectSystem:CreateTriggerInGameMode(tbData)
end

local function TestPathNode(tbPlayer, tbParams)
    local nType = tonumber(tbParams[2])
    local nPathId = tonumber(tbParams[3])
    local nNodeIndex = tonumber(tbParams[4])
    local szUtilityClass = "/Game/Game/Ships/Misc/BP_AIShipUtility.BP_AIShipUtility_C"
    local pClass = szUtilityClass:load()
    local pPlayerController = tbPlayer:GetUEController()
    if(nType == 0) then
        local pLocation = pClass.GetPatrolWaypointLocation(nPathId, nNodeIndex, pPlayerController, GWorld)
        log("BP_AIShipUtility.GetPatrolWaypointLocation return", pLocation.X, pLocation.Y, pLocation.Z)
    else
        local nNextIndex, pLocation = pClass.GetNextPatrolWaypoint(nNodeIndex, nPathId, pPlayerController, GWorld)
        log("BP_AIShipUtility.GetNextPatrolWaypoint return", nNextIndex, pLocation.X, pLocation.Y, pLocation.Z)
    end
end

local function AddBuff(tbPlayer, tbParams)
    if tbPlayer.BuffComponentServer then
        local nBuffId = tonumber(tbParams[2])
        if nBuffId then
            local nOverlapCount = tonumber(tbParams[3]) or 1
            local nLevel = tonumber(tbParams[4]) or 1
            tbPlayer.BuffComponentServer:AddBuffById(nBuffId, nOverlapCount, nLevel)
        end
    else
        logerror("cannot find buffcomponentserver?")
    end
end

local function RemoveBuff(tbPlayer, tbParams)
    if tbPlayer.BuffComponentServer then
        local nBuffId = tonumber(tbParams[2])
        if nBuffId then
            tbPlayer.BuffComponentServer:RemoveBuffById(nBuffId)
        end
    else
        logerror("cannot find buffcomponentserver?")
    end
end

-- local function GetAvailableBotId()
--     local nAvailableBotId = 1000
--     local tbMap = GameObjectSystem:GetAllGameObjects()
--     while true do
--         local bUsedId = false
--         for _nId, tbObject in pairs(tbMap) do
--             if tbObject.nPlayerId == nAvailableBotId then
--                 bUsedId = true
--                 nAvailableBotId = nAvailableBotId + 1
--                 break
--             end
--         end
--         if not bUsedId then
--             break
--         end
--     end
--     return nAvailableBotId
-- end

local function ResetSkillCD(tbPlayer)
    tbPlayer.SkillComponentServer:ResetSkillCD()
end

-- 供测试用，短期保留，打断当前自己的技能
local function InterruptSkill(tbPlayer)
    tbPlayer.SkillComponentServer:InterruptSkill()
end

local function TestSendBattleStats(tbPlayer)
    -- local HubSenderManager = require("HubSenderManager_S")
    -- local HubProto = require("DungeonProtoNames")
    -- local nPlayerId = tbPlayer.nPlayerId
    -- local tbPacket = {}
    -- tbPacket.datas = {}
    -- table.insert(tbPacket.datas,
    --     {
    --         player_id = nPlayerId,
    --         ship_id = 1031,
    --         cannon_damage = 1,
    --         cannon_fired_count = 2,
    --         cannon_hit_count = 3,
    --         cannon_core_count = 4,
    --         caused_fire_count = 5,
    --         caused_fire_damage = 6,
    --         torpedo_damage = 7,
    --         torpedo_fired_count = 8,
    --         torpedo_hit_count = 9,
    --         caused_leak_count = 10,
    --         caused_leak_damage = 11,
    --         cure_amount = 12,
    --         be_cured_amount = 13,
    --         kill_count = 14,
    --         dead_count = 15,
    --         sail_distance = 16,
    --         total_damage = 17,
    --         assist_count = 18,
    --         mvp = true,
    --         result = HubProto.GameResult.GAME_WIN,
    --     }
    -- )
    -- HubSenderManager:Send(HubProto.d2s_BattleStatsData, tbPacket, nPlayerId)
end

local function Teleport(tbPlayer, tbParams)
    local nX = tonumber(tbParams[2])
    local nY = tonumber(tbParams[3])
    local nZ = tonumber(tbParams[4]) and tonumber(tbParams[4]) or 100
    local nYaw = tonumber(tbParams[5]) and tonumber(tbParams[5]) or 0
    local pLocation = Vector{X = nX, Y = nY, Z = nZ}
    local D2CHelper = require("D2CHelper")
    if tbPlayer then
        if tbPlayer:IsShip() then
            local ShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
            if(isvalidhandle(ShipMovementComponent)) then
                ShipMovementComponent:TeleportShip(pLocation, nYaw, true)
                D2CHelper:PlayerSetCameraYaw(tbPlayer, nYaw)
            end
        else
            local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
            if(isvalidhandle(CharacterMovement)) then
                CharacterMovement:TeleportHuman(pLocation, nYaw, true, true, true)
                D2CHelper:PlayerSetCameraYaw(tbPlayer, nYaw)
            end
        end
    end
end

local function TeleportBot(tbPlayer, tbParams)
    local nServerInstanceId = tonumber(tbParams[2])
    local nX = tonumber(tbParams[3])
    local nY = tonumber(tbParams[4])
    local nZ = tonumber(tbParams[5]) and tonumber(tbParams[5]) or 100
    local nYaw = tonumber(tbParams[6]) and tonumber(tbParams[6]) or 0
    local pLocation = Vector{X = nX, Y = nY, Z = nZ}

    local tbBot = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    if tbBot and tbBot:IsAlive() then
        if tbBot:IsShip() then
            local ShipMovementComponent = tbBot.pUEActor.ShipMovementComponent
            ShipMovementComponent:TeleportShip(pLocation, nYaw, true)
            log("teleport bot ship", nServerInstanceId, nX, nY, nZ)
        else
            local CharacterMovement = tbBot.pUEActor.CharacterMovement
            CharacterMovement:TeleportHuman(pLocation, nYaw, true, true, true)
            log("teleport bot human", nServerInstanceId, nX, nY, nZ)
        end
        local GameCoreProxyClient = require("GameCoreProxyClient")
        if GameCoreProxyClient:IsAgent(tbBot) then
            local tbAgent = GameCoreProxyClient:GetAgent(nServerInstanceId)
            CreateAction(tbAgent, "GameCorePacketProcessorFocus"):DoAction({pitch = 0, yaw = nYaw})
        end
    end
end

local function SetGearData(tbPlayer, tbParams)
    local nType = tonumber(tbParams[2])
    local nValue = tonumber(tbParams[3])
    local pShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
    if nType == 1 then
        pShipMovementComponent:Debug_SetCurrentGearData(EShipMoveGearBuffType.MAX_LINEAR_SPEED, nValue)
        return
    end
    if nType == 2 then
        pShipMovementComponent:Debug_SetCurrentGearData(EShipMoveGearBuffType.LINEAR_ACCELERATION, nValue)
        return
    end
    if nType == 3 then
        pShipMovementComponent:Debug_SetCurrentGearData(EShipMoveGearBuffType.LINEAR_DECELERATION, nValue)
        return
    end
    if nType == 4 then
        pShipMovementComponent:Debug_SetCurrentGearData(EShipMoveGearBuffType.MAX_ANGULAR_SPEED, nValue)
        return
    end
    if nType == 5 then
        pShipMovementComponent:Debug_SetCurrentGearData(EShipMoveGearBuffType.ANGULAR_ACCELERATION, nValue)
        return
    end
    if nType == 6 then
        pShipMovementComponent:Debug_SetCurrentGearData(EShipMoveGearBuffType.ANGULAR_DECELERATION, nValue)
        return
    end
end

local function SetShipMoveGearBuff(tbPlayer, tbParams)
    local nMaxLinearSpeed = tonumber(tbParams[2])
    local nLinearAcceleration = tonumber(tbParams[3])
    local nLinearDeceleration = tonumber(tbParams[4])
    local nMaxAngularSpeed = tonumber(tbParams[5])
    local nAngularAcceleration = tonumber(tbParams[6])
    local nAngularDeceleration = tonumber(tbParams[7])

    local pShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
    pShipMovementComponent:SetShipMoveGearBuff(true, nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
end

local function UsingAsyncPathFindingForAI(_, tbParams)
    local n = tonumber(tbParams[2])
    local tbMap = GameObjectSystem:GetAllGameObjects()
    for _nId, tbObject in pairs(tbMap) do
        if(tbObject.ObjectType == GameObjectTypeDef.Npc or tbObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
            if n > 0 then
                tbObject.pUEActor.bUsingAsyncPathFindingForAI = true
            else
                tbObject.pUEActor.bUsingAsyncPathFindingForAI = false
            end
        end
    end
end

local function ChangeToShip(tbPlayer, tbParams)
    BattleGameModeSystem:GetGameMode():ChangeToShip(tbPlayer, tonumber(tbParams[2]))
end

local function ChangeToHuman(tbPlayer, tbParams)
    if(tbPlayer:IsShip()) then
        BattleGameModeSystem:GetGameMode():ChangeToHuman(tbPlayer, tonumber(tbParams[2]))
    end
end

local function MoveToTestPoint(tbPlayer, tbParams)
    local UEActorHelper = require("UEActorHelper")
    local D2CHelper = require("D2CHelper")

    local szTargetPoint = 'TestPoint'..tbParams[2]
    local pLocation
    local fnGetName = KismetSystemLibrary.GetDisplayName
    local tbPlayerStarts = BattleGameModeSystem:GetGameMode().pGameMode:GetAllPlayerStart()
    for _, v in ipairs(tbPlayerStarts) do
        if(fnGetName(v) == szTargetPoint) then
            pLocation = v:K2_GetActorLocation()
            break
        end
    end
    if(pLocation == nil) then
        return
    end

    if(tbPlayer:IsShip()) then
        if UEActorHelper:TeleportShip(tbPlayer.pUEActor, pLocation, 0, true) then
            D2CHelper:PlayerSetCameraYaw(tbPlayer, 0)
            D2CHelper:PlayerSwitchCommonHandlerMode(tbPlayer)
        end
    else
        tbPlayer:SetLocation(pLocation.X, pLocation.Y, pLocation.Z)
        -- D2CHelper:PlayerSetCameraYaw(tbObject, 0)
        -- D2CHelper:PlayerSwitchCommonHandlerMode(tbObject)
    end
end

local function ApplyDamageEnemy(tbPlayer,tbParams)
    -- local tbObjects = GameObjectSystem:GetAllGameObjects()
    -- local tbTarget
    -- for k, v in pairs(tbObjects) do
    --     if(v ~= tbCauser) then
    --         tbTarget = v
    --         break
    --     end
    -- end
    local tbTarget = GameObjectSystem:FindByInstanceId(tonumber(tbParams[2]))
    PropUtil.ApplyDamage(tbTarget, tbPlayer, nil,tonumber(tbParams[3], nil ))
end

local function ConsumeEp(_,tbParams)
    local tbTarget = GameObjectSystem:FindByInstanceId(tonumber(tbParams[2]))
    PropUtil.ConsumeEp(tbTarget, tonumber(tbParams[3]))
end

local function KillObject(tbPlayer, tbParams)
    local tbTarget = GameObjectSystem:FindByInstanceId(tonumber(tbParams[2]))

    if (tbTarget == nil) then
        log("tbTarget is nil")
        return
    end

    local nMaxHp = PropUtil.GetMaxHp(tbTarget)
    local DamageTypeEx = require("DamageTypeEx")
    PropUtil.ApplyDamage(tbTarget, tbPlayer, DamageTypeEx.UNKNOWN, nMaxHp)
end

local function CureObject(tbPlayer, tbParams)
    local tbTarget = GameObjectSystem:FindByInstanceId(tonumber(tbParams[2]))
    local nMaxHp = PropUtil.GetMaxHp(tbTarget)
    PropUtil.ApplyCure(tbTarget, tbPlayer, nMaxHp)
end

local function GainEp(tbPlayer)
    local nMaxEp = PropUtil.GetMaxEp(tbPlayer)
    PropUtil.GainEp(tbPlayer, nMaxEp)
end

local function AddSceneItemBox(tbPlayer)
    local pUEActor = tbPlayer.pUEActor
    local pPos = pUEActor:K2_GetActorLocation()

    local tbTransform = {}
    tbTransform.X = pPos.X
    tbTransform.Y = pPos.Y
    tbTransform.Z = pPos.Z
    tbTransform.Yaw = 0
    local tbSceneItemData = {}
    tbSceneItemData.tbTransform = tbTransform
    tbSceneItemData.tbItemInfos = {}
    local tbItemInfo2 = {}
    tbItemInfo2.nItemTemplateId = 11010004
    tbItemInfo2.nItemCount = 1
    local tbItemInfo3 = {}
    tbItemInfo3.nItemTemplateId = 13010001
    tbItemInfo3.nItemCount = 1
    local tbItemInfo4 = {}
    tbItemInfo4.nItemTemplateId = 14030001
    tbItemInfo4.nItemCount = 1
    local tbItemInfo5 = {}
    tbItemInfo5.nItemTemplateId = 14020001
    tbItemInfo5.nItemCount = 1
    local tbItemInfo6 = {}
    tbItemInfo6.nItemTemplateId = 12010001
    tbItemInfo6.nItemCount = 1
    local tbItemInfo7 = {}
    tbItemInfo7.nItemTemplateId = 17010001
    tbItemInfo7.nItemCount = 30
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo2)
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo3)
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo4)
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo5)
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo6)
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo7)

    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    BattleItemSystemServer:AddItemPackageToScene(tbSceneItemData, SceneItemActorDef.TREASURE_CHEST, 25010003)
end

local function SetDelayDieBoxTime(_, tbParams)
    local nDelayTime = tonumber(tbParams[2])
    if nDelayTime >= 0 then
        local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
        BattleItemSystemServer:SetGMDelayDieBoxTime(nDelayTime)
    end
end

local function ClearDelayDieBoxTime(_, _)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    BattleItemSystemServer:ClearGMDelayDieBoxTime()
end

local function InitGroupItem(tbPlayer, tbParams)
    local nGroupId = tonumber(tbParams[2])
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    BattleItemSystemServer:InitPlayerItemsByGroupId(tbPlayer:GetServerInstanceId(), nGroupId)
end

local function AddBattleItem(tbPlayer, tbParams)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    log("[BattleItem gm]AddBattleItem", tbPlayer.nServerInstanceId, require("dkjson").encode(tbParams))
    BattleItemSystemServer:AddBattleItem(tbPlayer.nServerInstanceId, tbParams)
end

local function AddItemByTemplate(tbPlayer, tbParams)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nItemTemplateId = tonumber(tbParams[2])
    local nCount = tonumber(tbParams[3])
    BattleItemSystemServer:AddItemByTemplate(tbPlayer.nServerInstanceId, nItemTemplateId, nCount)
end

local function DestroyUnequippedItemsByTemplate(tbPlayer, tbParams)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nItemTemplateId = tonumber(tbParams[2])
    local nCount = tonumber(tbParams[3])
    BattleItemSystemServer:DestroyUnequippedItemsByTemplate(tbPlayer.nServerInstanceId, nItemTemplateId, nCount)
end

local function ThrowAwayItemsInRoom(nCharacterInstanceId, ItemRoom)
    local tbItems = ItemRoom:GetRoomItems(false)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    for _, Item in pairs(tbItems) do
        BattleItemSystemServer:ThrowAwayItem(nCharacterInstanceId, Item:GetInstanceId())
    end
end

local function ClearBackpack(tbPlayer, tbParams)
    local BattleItemComponent = tbPlayer.BattleItemComponentServer
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    for i = 2, #tbParams do
        local nRoomType = tonumber(tbParams[i])
        if not BattleItemRoomDef:IsValid(nRoomType) then
            logerror("clearbackpack failed! unvalid room type!", tbParams[i])
            return
        end
        if not BattleItemRoomDef:IsInventoryRoom(nRoomType) then
            logerror("clearbackpack failed! room type is not backpack!", tbParams[i])
            return
        end
        local ItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nCharacterInstanceId)
        ThrowAwayItemsInRoom(nCharacterInstanceId, ItemRoom)
    end
end

local function HurtSelf(tbPlayer, tbParams)
    if tbPlayer then
        local nDamage = tonumber(tbParams[2])
        if nDamage then
            local DamageTypeEx = require("DamageTypeEx")
            PropUtil.ApplyDamage(tbPlayer, tbPlayer, DamageTypeEx.UNKNOWN, nDamage, nil)
        end
    end
end

local function CureSelf(tbPlayer, tbParams)
    if tbPlayer then
        local nCuringValue = tonumber(tbParams[2])
        if not nCuringValue then
            nCuringValue = PropUtil.GetMaxHp(tbPlayer)
        end
        PropUtil.ApplyCure(tbPlayer, tbPlayer, nCuringValue)
    end
end

local function HurtWatchTarget(tbPlayer, tbParams)
    if tbPlayer then
        local nDamage = tonumber(tbParams[2])
        if nDamage then
            local nWatchId = tbPlayer.WatchBattleComponent.nCurrentViewId
            local tbWatchTarget = GameObjectSystem:FindByInstanceId(nWatchId)
            local DamageTypeEx = require("DamageTypeEx")
            PropUtil.ApplyDamage(tbWatchTarget, tbWatchTarget, DamageTypeEx.UNKNOWN, nDamage, nil)
        end
    end
end

local function PrintMaxHp(tbPlayer)
    local nMaxHp = PropUtil.GetMaxHp(tbPlayer)
    local nHp = PropUtil.GetHp(tbPlayer)
    printScreen(nMaxHp, nHp)
    log(nMaxHp, nHp)
end

local function Invincible(tbPlayer, tbParams)
    local nFlag = tonumber(tbParams[2])
    local bFlag = false
    if nFlag == 1 then
        bFlag = true
    end

    if tbPlayer.ShipBattlePropertyComponent  then
        tbPlayer.ShipBattlePropertyComponent.bInvincible = bFlag
    end
    if tbPlayer.HumanBattlePropertyComponent  then
        tbPlayer.HumanBattlePropertyComponent.bInvincible = bFlag
    end
end

local function InvincibleToPoisonCircle(tbPlayer, tbParams)
    local nFlag = tonumber(tbParams[2])
    local bFlag = false
    if nFlag == 1 then
        bFlag = true
    end

    if tbPlayer.ShipBattlePropertyComponent  then
        tbPlayer.ShipBattlePropertyComponent.bInvincibleToPoisonCircle = bFlag
    end
    if tbPlayer.HumanBattlePropertyComponent  then
        tbPlayer.HumanBattlePropertyComponent.bInvincibleToPoisonCircle = bFlag
    end
end

local function RaiseLuaError()
    local tbObj = {}
    tbObj.nullFun()
end

local function KillBotsEx(tbPlayer, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local DamageTypeEx = require("DamageTypeEx")
    local nNumBot = tonumber(tbParams[2])
    if nNumBot > #BotAISystem.tbBots then
        nNumBot = #BotAISystem.tbBots
    end
    local nCount = 0
    for i= #BotAISystem.tbBots, 1, -1 do
        local tbBot = BotAISystem.tbBots[i]
        if not tbBot.bDead then
            log("kill bot ", i)
            local nMaxHp = PropUtil.GetMaxHp(tbBot)
            PropUtil.ApplyDamage(tbBot, tbPlayer, DamageTypeEx.UNKNOWN, nMaxHp)
            nCount = nCount + 1
            if nCount >= nNumBot then
                break
            end
        end
    end
end

local function SetCorrectionDistance(tbPlayer, tbParams)
    local distance = tonumber(tbParams[2])
    if tbPlayer then
        if tbPlayer:IsHuman() then
            log("SetCorrectionDistance ", distance)
            local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
            CharacterMovement.NetworkLargeClientCorrectionDistance = distance
        end
    end
end

local function CreateSquad(_, tbParams)
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if not tbSetting:IsWaitStage() then
        printScreen("该指令只能在集合阶段使用")
        return
    end
    local BotAISystem = dynamic_require("BotAISystem")
    local nNumBot = tonumber(tbParams[2])
    local nAIId = tonumber(tbParams[3] or 2)
    local nTime = tonumber(tbParams[4] or 10)
    nNumBot = math.min(nNumBot, 100)
    if BotAISystem:Spawn(nNumBot, nAIId, nTime, nil) then
        printScreen("createSquad successful")
    end
end

local function CreateAITeammate(tbPlayer, tbParams)
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if not tbSetting:IsWaitStage() then
        printScreen("该指令只能在集合阶段使用")
        return
    end
    local BotAISystem = dynamic_require("BotAISystem")
    local nNumBot = tonumber(tbParams[2])
    local nAIId = tonumber(tbParams[3] or 2)
    local nTime = tonumber(tbParams[4] or 10)
    local nCurrentCount = #(BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer))
    nNumBot = math.min(nNumBot, 4 - nCurrentCount)
    local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
    if nNumBot > 0 and BotAISystem:Spawn(nNumBot, nAIId, nTime, nTeamId) then
        printScreen("createSquad successful")
    end
end

local function SetCorrectionTime(tbPlayer, tbParams)
    local time = tonumber(tbParams[2])
    if tbPlayer then
        if tbPlayer:IsHuman() then
            log("SetCorrectionTime ", time)
            local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
            CharacterMovement.NetworkMinTimeBetweenClientAdjustments = time
            CharacterMovement.NetworkMinTimeBetweenClientAdjustmentsLargeCorrection = (time/2)
        end
    end
end

local function ChangeTeam(tbPlayer, tbParams)
    local nTeamId = tonumber(tbParams[2])
    BattleTeamSystem:ChangeTeam(tbPlayer, nTeamId)
end

local function SetHumanWeaponProperty(tbPlayer, tbParams)
    local nLength = #tbParams
    local tbNewParams = {}
    table.move(tbParams, 2, nLength, 1, tbNewParams)
    HumanWeaponItemPropertyHelper.GMSetBaseWeaponProperty(tbPlayer, tbNewParams, false)
    log("SetHumanWeaponProperty", tbPlayer:GetServerInstanceId(), require("dkjson").encode(tbParams))
end

local function EnableDying(self)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.bDyingEnabled = true
end

local function SetTeamNumber(_, tbParams)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    tbGameMode.Setting.nMode = tonumber(tbParams[2])
end

local function BattleTestAutomation(tbPlayer, tbParams)
    local GameTestAutomationSystemServer = require("GameTestAutomationSystemServer")

    local nServerInstanceId = tbPlayer:GetServerInstanceId()
    local szParam = tbParams[2]
    if szParam == "start" then
        local tbExtraDatas = {}
        if tbParams[3] then
            local nShipTemplateId = tonumber(tbParams[3])
            tbExtraDatas["nShipTemplateId"] = nShipTemplateId
            local nWeaponTemplateId = tonumber(tbParams[4])
            tbExtraDatas["nWeaponTemplateId"] = nWeaponTemplateId
        end
        GameTestAutomationSystemServer:StartBattleAutoTest(nServerInstanceId, tbExtraDatas)
    elseif szParam == "stop" then
        GameTestAutomationSystemServer:StopBattleAutoTest(nServerInstanceId)
    else
        logerror("BattleTestAutomation", "params invalid")
    end
    -- local tbPlayer = GetPlayerSelfByPlayerController(pPlayerController)
    -- local GameTestAutomationRoamSystem = require("GameTestAutomationRoamSystem")
    -- local StringUtil = require("StringUtil")
    -- local nFlag = tonumber(tbParams[2])
    -- if nFlag == 1 then
    --     local szPathIds = tbParams[3]
    --     local tbPathIds = nil
    --     if szPathIds and szPathIds ~= "" then
    --         local tbPathStrs = StringUtil.Split(szPathIds, ",")
    --         for _, szId in ipairs(tbPathStrs) do
    --             local nId = tonumber(szId)
    --             if nId then
    --                 if not tbPathIds then
    --                     tbPathIds = {}
    --                 end
    --                 table.insert(tbPathIds, nId)
    --             end
    --         end
    --     end
    --     GameTestAutomationRoamSystem:Start(nServerInstanceId, tbPathIds)
    -- elseif nFlag == 2 then
    --     GameTestAutomationRoamSystem:Stop(nServerInstanceId)
    -- elseif nFlag == 3 then
    --     GameTestAutomationRoamSystem:Pause(nServerInstanceId)
    -- elseif nFlag == 4 then
    --     GameTestAutomationRoamSystem:Resume(nServerInstanceId)
    -- else
    --     logerror("GM: testautomation, param is invalid, param is ", tbParams[2])
    -- end
end



local function ServerCmd(_, tbParams)
    local szCmd = ""
    for i=2, #tbParams do
        szCmd = szCmd..tbParams[i].." "
    end
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCmd, nil)
end

local function ToggleBotName(_, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local AIHelper = require("AIHelper")
    local bShow = tonumber(tbParams[2]) > 0
    BotAISystem.bShowBotName = bShow
    for i,v in ipairs(BotAISystem.tbBots) do
        AIHelper.ToggleBotName(v, bShow)
    end
end

local function ToggleBotNearby(tbPlayer, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local pActorLocation = tbPlayer.pUEActor:K2_GetActorLocation()
    local bIsShip = tbPlayer:IsShip()
    for i,v in ipairs(BotAISystem.tbBots) do
        if v:IsAlive() then
            local nX = pActorLocation.X + math.random(-200, 200)
            local nY = pActorLocation.Y + math.random(-200, 200)
            local nZ = pActorLocation.Z + 100
            local pLocation = Vector{X = nX, Y = nY, Z = nZ}
            if v:IsShip() and bIsShip then
                local ShipMovementComponent = v.pUEActor.ShipMovementComponent
                ShipMovementComponent:TeleportShip(pLocation, 0, true)
            elseif not v:IsShip() and not bIsShip then
                local CharacterMovement = v.pUEActor.CharacterMovement
                CharacterMovement:TeleportHuman(pLocation, 0, true, true)
            end
        end
    end
end

local function SpawnBotByTime(_, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local nNumBot = tonumber(tbParams[2])
    local nAIGroupId = tonumber(tbParams[3] or 1)
    local nTime = tonumber(tbParams[4] or 10)
    if BotAISystem:Spawn(nNumBot, nAIGroupId, nTime, nil) then
        printScreen("SpawnBotByTime successful")
    end
end

local function LuaDebug(_, tbParams)
	if(tbParams == nil or #tbParams == 1) then
        printLuaDebuginfo(0)
    else
        printLuaDebuginfo(tonumber(tbParams[2]))
	end
end

local function PrintLuaMemory()
	local ResourceManager = require("ResourceManager")
	local nSize = ResourceManager:GetUsedMemorySize()
    log("Lua memory used", nSize/1024/1024, "M")
    printPluginMemory()
end


local function LuaGC()
	local ResourceManager = require("ResourceManager")
	ResourceManager:GC()
	KismetSystemLibrary.CollectGarbage()
end


local function ChangePoisonCirclePosition(_, tbParams)
    local EventManager = require("EventManager")
    local CommonEventDef = require("CommonEventDef")
    local nX = tonumber(tbParams[2])
    local nY = tonumber(tbParams[3])
    EventManager:OnFireEvent(CommonEventDef.EV_MODIFY_POISONCIRCLE_POS, nX, nY)
end



local function GetLandId(tbPlayer, tbParams)
    local pActorLocation = tbPlayer.pUEActor:K2_GetActorLocation()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nLandId = GridTypeManager:GetLandID(pActorLocation.X, pActorLocation.Y)
    printScreen("landid->", nLandId)
end

local function ToggleBotAlwaysRelevent(tbPlayer, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local nIndex    = tonumber(tbParams[2]) or 1
    local nOpen     = tonumber(tbParams[3])
    if BotAISystem.tbBots[nIndex] then
        local v = BotAISystem.tbBots[nIndex]
        if v.pUEActor then
            if nOpen > 0 then
                PiratesReplicationBPHelpers.AddDependentActor(tbPlayer.pUEActor, v.pUEActor)
            else
                PiratesReplicationBPHelpers.RemoveDependentActor(tbPlayer.pUEActor, v.pUEActor)
            end
        end
    end
end

local function PrintTemplateActorInfo()
    CommonShell.Get(GWorld):GetTemplateActorDataManager():PrintDebugInfo()
end


local function KickoutBot()
    local BotAISystem = dynamic_require("BotAISystem")
    BotAISystem:KickoutAllBot()
end



local function SendPlayerResult(tbPlayer, tbParams)
    local GameResultManager = dynamic_require("GameResultManager")
    if GameResultManager ~= nil then
        local nTeamId = tbPlayer.BattleTeamComponent.nTeamId
        local tbPlayerStats = {
            rank = 16,
            kill = 1,
            duration = 15,
            distance = 20,
            heals = 13,
            rescues = 12,
            damage = 11,
            hit = 10,
            critical = 9,
            attack = 8
        }
        GameResultManager:SendPlayerResult(tbPlayer.nPlayerId, nTeamId, tbPlayerStats)
    end
end

local function SendTeamResult(_, tbParams)
    local GameResultManager = dynamic_require("GameResultManager")
    if GameResultManager ~= nil then
        local tbPlayerIds = {1, 2, 3, 4}
        local nTeamId = 12
        local nTeamRank = 13
        local tbTeamStats = {
        }
        GameResultManager:SendTeamResult(tbPlayerIds, nTeamId, nTeamRank, tbTeamStats)
    end
end



local function TestBotDead(tbPlayer, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local nType = tonumber(tbParams[2])
    if nType == 1 then
        for i,v in ipairs(BotAISystem.tbBots) do
            EngineExtActorShell.DestroyActor(GWorld, v.AIComponent:GetActiveAIMoudle().pAIController)
        end
    else
        for i,v in ipairs(BotAISystem.tbBots) do
            PropUtil.ApplyDamage(v, tbPlayer, nil, 10000, nil )
        end
    end
end

local function KickAllPlayers()
    --ServerShell.GetServer(GWorld):KickAllPlayers()
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    tbGameMode:OnAllPlayerLogoutWithEvent()
end

local function KickPlayerByName(tbPlayer, tbParams)
    local szPlayerName = tbParams[2]

    local BattleResultSystem = dynamic_require("BattleResultSystem")
    local BotAISystem        = dynamic_require("BotAISystem")
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbObject, _ in pairs(tbObjects) do
        local nInstanceId = tbObject:GetServerInstanceId()
        local bPlayerBattleEnd = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
        if tbObject.szName == szPlayerName                     and
           not BotAISystem:IsBot(tbObject)                     and
           not bPlayerBattleEnd then
            BattleGameModeSystem:KickPlayer(tbObject)
            return
        end
    end
end

local function StartViewBots(tbPlayer, tbParams)
    local BotDistributionSystem = dynamic_require("BotDistributionSystem")
    BotDistributionSystem:AddListenr(tbPlayer)
    BotDistributionSystem:StartReport()
end

local function TransformToBot(tbPlayer, tbParams)
    local BotAISystem = dynamic_require("BotAISystem")
    local bShip = tbPlayer:IsShip()
    local nIndex = tonumber(tbParams[2])
    if nIndex <= #BotAISystem.tbBots then
        local tbBot = BotAISystem.tbBots[nIndex]
        local pLocation = tbBot:GetLocation()
        if tbBot:IsShip() then
            pLocation.X = pLocation.X + math.random( -50000, 50000 )
            pLocation.Y = pLocation.Y + math.random( -50000, 50000 )
            pLocation.Z = pLocation.Z + 100
            if not bShip then
                local nShipId = tbPlayer:GetShipTemplateId()
                local tbTransform = {}
                tbTransform.X = pLocation.X
                tbTransform.Y = pLocation.Y
                tbTransform.Z = pLocation.Z
                BattleGameModeSystem:GetGameMode():ChangeToShip(tbPlayer, nShipId, tbTransform)
            else
                local ShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
                ShipMovementComponent:TeleportShip(pLocation, 0, true)
            end
        else
            pLocation.X = pLocation.X + math.random( -500, 500 )
            pLocation.Y = pLocation.Y + math.random( -500, 500 )
            pLocation.Z = pLocation.Z + 100
            pLocation = ExtendBlueprintFunctions.GetAISafePosition(GWorld, pLocation, 0, 20000, -20000)
            if bShip then
                local nHumanId = tbPlayer:GetHumanTemplateId()
                local tbTransform = {}
                tbTransform.X = pLocation.X
                tbTransform.Y = pLocation.Y
                tbTransform.Z = pLocation.Z
                BattleGameModeSystem:GetGameMode():ChangeToHuman(tbPlayer, nHumanId, tbTransform)
            else
                local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
                CharacterMovement:TeleportHuman(pLocation, 0, true, true)
            end
        end
        tbPlayer.SAIEntityComponent:SetInvisibleFromAI(true)
        if tbPlayer.ShipBattlePropertyComponent  then
            tbPlayer.ShipBattlePropertyComponent.bInvincible = true
        end
        if tbPlayer.HumanBattlePropertyComponent  then
            tbPlayer.HumanBattlePropertyComponent.bInvincible = true
        end
    end
end



local function TestCoverPoint(_, tbParams)
    local AICoverPointsManager = CommonShell.GetCommon(GWorld):GetAICoverPointsManager()
    AICoverPointsManager:PrintDebugInfo()
end

local function CreateVehicle(tbPlayer, tbParams)
    local location = tbPlayer.pUEActor:K2_GetActorLocation()
    local tbTransform = {X = location.X - 200,
                Y = location.Y,
                Z = location.Z,
                Yaw = 0,
    }
    local nVehicleId = tonumber(tbParams[2])
    GameObjectSystem:CreateVehicleInGameMode(nVehicleId, GameObjectTypeDef.Horse, tbTransform)    -- self拥有spawninfo用到的所有参数
end



local function DeleteTimer(_,tbParams)
    local szTimerName = tbParams[2]
    log("dm deletetimer timername:",szTimerName)

    BattleTimerHelper:DestroyTimer(szTimerName)
end



local function EnableNPCAlert(_, tbParams)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.bEnableNPCAlert = true
end

local function IsValidPlayer(tbPlayer)
    return (tbOwnerPlayerId == nil) or (tbOwnerPlayerId == tbPlayer:GetPlayerId())
end

local function ClearOwnerPlayer()
    tbOwnerPlayerId = nil
    tbOwnerPlayerName = nil
end

local function SetDMEnabled(tbPlayer,tbParams)
    if IsValidPlayer(tbPlayer) then
        local bEnabled = tonumber(tbParams[2]) == 1
        if bEnabled then
            ClearOwnerPlayer()
        else
            tbOwnerPlayerId = tbPlayer:GetPlayerId()
            tbOwnerPlayerName = tbPlayer.szName
        end
    end
end

local SendTestDataTimer = nil
local fnSendTestDataFunc = nil
local function SendTestDataToClient(tbPlayer, tbParams)
    local nDataSize = tonumber(tbParams[2])
    local NetworkManager = dynamic_require("NetworkManager")

    if(SendTestDataTimer ~= nil) then
        SendTestDataTimer:Clear()
        SendTestDataTimer = nil
        fnSendTestDataFunc = nil
    end

    if(nDataSize <= 0) then
        return
    end

    fnSendTestDataFunc = function()
        local pRPC = NetworkManager:GetRPCNetworkProxy().pNetworkManager:GetRPCComponent(tbPlayer:GetUEController())
        if(pRPC) then
            pRPC:SendToClientTestData(nDataSize)
        end
    end

    SendTestDataTimer = require("Timer").NewTimer(fnSendTestDataFunc, 0.05, true)
end

local function SetReplicatePlayerNum(tbPlayer, tbParams)
    if tbParams[2] ~= nil then
        PiratesReplicationBPHelpers.SetReplicatePlayerNum(tbPlayer:GetUEController(), tonumber(tbParams[2]))
    end
end

local function SetBoolValue(tbPlayer, tbParams)
    local EventManager = require("EventManager")
    local BattleBlackboard = require("BattleBlackboard")
    local CommonEventDef = require("CommonEventDef")
    local BattleSkySystem = dynamic_require("BattleSkySystem")
    local GameCoreProxyClient = require("GameCoreProxyClient")

    local tbKeyName = tbParams[2]
    local bValue    = (tbParams[3] == 'true')

    if tbKeyName == "SkipFFASelectionPoint" and bValue then
        if GameCoreProxyClient:IsEnabled() and not GameCoreProxyClient.bItemSpawned then
            logerror("game item has not spawned over")
            return
        end
    end

    if BattleBlackboard:IsDefined(tbKeyName) then
        BattleBlackboard:SetBool(tbKeyName ,bValue)
        if tbKeyName == 'SkipFFAWaitTime' then
            local name = tbPlayer.szName
            BattleSpecialToastHelper:ShowSpecialToast(nil, 4,
                name, '', '',ProtoDC.BattleToastInfo_EToastType.SPECIAL, 0, 3, 0, 0)
                BattleSkySystem:ResumeSky()
        elseif tbKeyName == "ParachutingNewTarget" or tbKeyName == "TransporterNewLaunch" then
            EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTING_INFO, tbKeyName)
        elseif tbKeyName == "INTER_GM_StopSelectPointCondition" and bValue then
            BattleSkySystem:PauseSky()
        end
    end
end

local function EnableBotSupply(tbPlayer, tbParams)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.bEnableBotSupply = true
end

local function GameSpeed(tbPlayer, tbParams)
    local nSpeed = tonumber(tbParams[2] or 1)
    GameplayStatics.SetGlobalTimeDilation(GWorld, nSpeed)
    log("set speed " .. nSpeed .. " in server")
end

local function SetFFADamageEnabled(_, tbParams)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    local AIVariableSystem = require("AIVariableSystem")
    local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

    local bEnable = tbParams[2] ~= nil and tbParams[2] == '1'
    AIVariableSystem:SetBattleStart(bEnable)
    GlobalVariableSystem:SetDungeonDamageEnabled(bEnable)

    if(bEnable) then
        BattleDataStatisticsSystem:Activate()
    else
        BattleDataStatisticsSystem:Deactivate()
    end
end

local function TestLineTrace(tbPlayer, tbParams)
    local nRadius = tonumber(tbParams[2])
    local nSX = tonumber(tbParams[3])
    local nSY = tonumber(tbParams[4])
    local nSZ = tonumber(tbParams[5])
    local nEX = tonumber(tbParams[6])
    local nEY = tonumber(tbParams[7])
    local nEZ = tonumber(tbParams[8])
    local pStart = Vector{X = nSX, Y = nSY, Z = nSZ}
	local pEnd = Vector{X = nEX, Y = nEY, Z = nEZ}
    local nTraceDistance = ExtendBlueprintFunctions.GetCollisionDistance(tbPlayer.pUEActor, nRadius, pStart, pEnd)
	log("server line trace distance ", nTraceDistance)
end

local function Teleport2Npc(tbPlayer, tbParams)
    local nIndex = tonumber(tbParams[2])
    local nCurIndex = 1
    for k,v in pairs(GameObjectSystem:GetAllGameObjects()) do
        if v.ObjectType == GameObjectTypeDef.Npc and v:IsShip() == tbPlayer:IsShip() then
            if nCurIndex == nIndex then
                local pLocation = v:GetLocation()
                local D2CHelper = require("D2CHelper")
                if tbPlayer:IsShip() then
                    local ShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
                    if(isvalidhandle(ShipMovementComponent)) then
                        ShipMovementComponent:TeleportShip(pLocation, 0, true)
                        D2CHelper:PlayerSetCameraYaw(tbPlayer, 0)
                    end
                else
                    local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
                    if(isvalidhandle(CharacterMovement)) then
                        pLocation.X = pLocation.X + math.random( 100, 200 )
                        pLocation.Z = pLocation.Z + 100
                        CharacterMovement:TeleportHuman(pLocation, 0, true, true)
                        D2CHelper:PlayerSetCameraYaw(tbPlayer, 0)
                    end
                end
                return
            else
                nCurIndex = nCurIndex + 1
            end
        end
    end
    log("num npc:", nCurIndex - 1)
end

local function CreateAITrainingBot(tbPlayer, tbParams)
    local GameCoreProxyClient = require("GameCoreProxyClient")
    local x = tonumber(tbParams[2])
    local y = tonumber(tbParams[3])
    local z = tonumber(tbParams[4])
    local teamid = tonumber(tbParams[5]) or math.random( 2, 100 )
    GameCoreProxyClient:AddBot(x, y, z, teamid, false)
end


local function DoAIAction(tbPlayer, tbParams)
    local GameCoreProxyClient = require("GameCoreProxyClient")
    local BattleItemSystemServer = require("BattleItemSystemServer")
    local tbAgent = GameCoreProxyClient.tbAgents[1]
    if not tbAgent then
        logerror("training ai not found...")
    end
    local szAction = tbParams[2]
    if szAction == "focus" then
        if tbAgent.tbAgent:IsHuman() then
            local nX = tonumber(tbParams[3])
            local nY = tonumber(tbParams[4])
            local nZ = tonumber(tbParams[5])
            local pAIController = tbAgent.pAIController
            pAIController:LookAt(Vector{X = nX, Y = nY, Z = nZ})
        else
            local nPitch = tonumber(tbParams[3])
            local nYaw = tonumber(tbParams[4])
            CreateAction(tbAgent, "GameCorePacketProcessorFocus"):DoAction({pitch = nPitch, yaw = nYaw})
        end
    elseif szAction == "fire" then
        CreateAction(tbAgent, "GameCorePacketProcessorFire"):DoAction()
    elseif szAction == "move" then
        local nX = tonumber(tbParams[3])
        local nY = tonumber(tbParams[4])
        local nZ = tonumber(tbParams[5])
        CreateAction(tbAgent, "GameCorePacketProcessorDirectMove"):DoAction({x = nX, y = nY, z = nZ})
    elseif szAction == "navmove" then
        local nX = tonumber(tbParams[3])
        local nY = tonumber(tbParams[4])
        local nZ = tonumber(tbParams[5])
        CreateAction(tbAgent, "GameCorePacketProcessorMove"):DoAction({x = nX, y = nY, z = nZ})
    elseif szAction == "joystick" then
        local nX = tonumber(tbParams[3])
        local nY = tonumber(tbParams[4])
        local nSpeed = tonumber(tbParams[5])
        CreateAction(tbAgent, "GameCorePacketProcessorJoyStick"):DoAction({x = nX, y = nY, speed = nSpeed})
    elseif szAction == "additem" then
        local tbItems = { }
        table.insert( tbItems, { id = tonumber(tbParams[3]), num = tonumber(tbParams[4]) } )
        CreateAction(tbAgent, "GameCorePacketProcessorAddItem"):DoAction({items = tbItems})
    elseif szAction == "change" then
        CreateAction(tbAgent, "GameCorePacketProcessorChangeDisplay"):DoAction()
    elseif szAction == "build" then
        local nItemTemplateId = tonumber(tbParams[3])
        local nSlotId = tonumber(tbParams[4] or 0)
        CreateAction(tbAgent, "GameCorePacketProcessorBuildItem"):DoAction({templateid = nItemTemplateId, slotid = nSlotId})
    elseif szAction == "switchweapon" then
        local nSlotId = tonumber(tbParams[3])
        CreateAction(tbAgent, "GameCorePacketProcessorSwitchWeapon"):DoAction({waepoan_slot = nSlotId})
    elseif szAction == "consume" then
        local nItemTemplateID = tonumber(tbParams[3])
        local tbInventory = BattleItemSystemServer:GetUnEquippedItems(tbAgent.tbAgent.nServerInstanceId,
        BattleItemRoomDef.HUMAN_INVENTORY)
        for i,v in ipairs(tbInventory) do
            if v:GetTemplateId() == nItemTemplateID then
                CreateAction(tbAgent, "GameCorePacketProcessorConsumeItem"):DoAction({itemid = v.nInstanceId})
                return
            end
        end
    elseif szAction == "setinterval" then
        local nInterval = tonumber(tbParams[3])
        GameCoreProxyClient:SetSyncInterval(nInterval)
    elseif szAction == "gamespeed" then
        local nSpeed = tonumber(tbParams[3])
        GameCoreProxyClient:ToggleGameSpeed(nSpeed)
    elseif szAction == "rescue" then
        local nServerInstanceId = tbPlayer.nServerInstanceId
        CreateAction(tbAgent, "GameCorePacketProcessorRescue"):DoAction({rescue_id = nServerInstanceId})
    elseif szAction == "help" then
        local BattleDyingComponent = tbAgent.tbAgent.BattleDyingComponent
        for tbTeammate,v in pairs(BattleDyingComponent.tbNearbyTeammates) do
            if tbTeammate then
                BattleDyingComponent:Rescue(tbTeammate)
                return
            end
        end
    elseif szAction == "jumpwall" then
        CreateAction(tbAgent, "GameCorePacketProcessorJumpWall"):DoAction()
    elseif szAction == "changevehicle" then
        local bGetOn = (tonumber(tbParams[3]) == 1)
        local nVehicleId = tonumber(tbParams[4])
        CreateAction(tbAgent, "GameCorePacketProcessorChangeVehicleState"):DoAction({get_on = bGetOn, vehicle_id = nVehicleId})
    elseif szAction == "crouch" then
        CreateAction(tbAgent, "GameCorePacketProcessorCrouch"):DoAction()
    elseif szAction == "crawl" then
        CreateAction(tbAgent, "GameCorePacketProcessorCrawl"):DoAction()
    elseif szAction == "jump" then
        CreateAction(tbAgent, "GameCorePacketProcessorJump"):DoAction()
    elseif szAction == "hold" then
        local nItemId = tonumber(tbParams[3])
        CreateAction(tbAgent, "GameCorePacketProcessorHoldThrownWeapon"):DoAction({ item_id = nItemId })
    elseif szAction == "unhold" then
        CreateAction(tbAgent, "GameCorePacketProcessorUnholdThrownWeapon"):DoAction()
    elseif szAction == "throw" then
        local nX = tonumber(tbParams[3])
        local nY = tonumber(tbParams[4])
        local nZ = tonumber(tbParams[5])
        CreateAction(tbAgent, "GameCorePacketProcessorThrowAttack"):DoAction({ x = nX, y = nY, z = nZ })
    end
end

local function ToggleBot(tbPlayer, tbParams)
    local GameCoreProxyClient = require("GameCoreProxyClient")
    local GameCoreWatchSystem = dynamic_require("GameCoreWatchSystem")
    local nServerInstanceId = tonumber(tbParams[2])
    for i,v in ipairs(GameCoreProxyClient.tbAgents) do
        if v.tbAgent.nServerInstanceId == nServerInstanceId then
            GameCoreWatchSystem:AddWatch(v.tbAgent, tbPlayer)
            break
        end
    end
end

local function ToggleBack(tbPlayer, tbParams)
    local GameCoreWatchSystem = dynamic_require("GameCoreWatchSystem")
    GameCoreWatchSystem:RemoveWatch(tbPlayer)
end

local function MemSnapshotDump(tbPlayer, tbParams)
    local szPath = ExtendBlueprintFunctions.GetProjectLogDir()
    -- local nDelayTime = tonumber(tbParams[2])
    local nSaveInterval = tonumber(tbParams[3])

    local mri = require("MemoryReferenceInfo")
    mri.m_cConfig.m_bAllMemoryRefFileAddTime = false

    local fnDump = function()
        log("mem dump1", collectgarbage("count"))
        mri.m_cMethods.DumpMemorySnapshot(szPath, "1-Before.txt", -1)

        luagc()
        log("mem dump2", collectgarbage("count"))
        mri.m_cMethods.DumpMemorySnapshot(szPath, "2-After.txt", -1)
        mri.m_cMethods.DumpMemorySnapshotComparedFile(szPath, "Compared", -1, szPath.."1-Before.txt", szPath.."2-After.txt")    
    end
    fnDump()
    require("Timer").NewTimer(fnDump, nSaveInterval, true)
end

local function PrintMem()
    require("Timer").NewTimer(function() 
        local a = collectgarbage("count")
        log("cur mem: ", a)
    end, 3, true)
end

local function SetDamageEnabled(tbPlayer, tbParams)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    local bEnable = tonumber(tbParams[2]) ~= 0
    GlobalVariableSystem:SetDungeonDamageEnabled(bEnable)
    log("SetDamageEnabled", bEnable)
end


local function HideOtherSelectionPoint(tbPlayer, tbParams)
	local NetworkManager = dynamic_require("NetworkManager")
	NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_HideOtherSelectionPoint, {hide = tonumber(tbParams[2]) > 0})
end

local function FinalPoint(tbPlayer, tbParams)
    local nX = tonumber(tbParams[2])
    local nY = tonumber(tbParams[3])

    local pLocation = {X = nX, Y = nY}
    local BattleBlackboard = require("BattleBlackboard")

    local szKey = "INTER_FFAFinalPoint"

    if not BattleBlackboard:IsDefined(szKey) then
        BattleBlackboard:DefineTable(szKey, pLocation)
    else
        BattleBlackboard:SetTable(szKey, pLocation)
    end
end

local function SkipParachute(tbPlayer, tbParams)
    local bSkip = (tbParams[2] == 'true')
    local BattleTransporterHelper = require("BattleTransporterHelper")
    if bSkip then
        BattleTransporterHelper:PlayerSkipParachute(tbPlayer:GetServerInstanceId(), true)
    else
        BattleTransporterHelper:PlayerSkipParachute(tbPlayer:GetServerInstanceId(), nil)
    end
end

local function ExecOnServer(tbPlayer, tbParams)
    local szCommand = nil
    for i=2,#tbParams do
        if i == 2 then
            szCommand = tbParams[i]
        else
            szCommand = szCommand .. " " .. tbParams[i]
        end
    end
    if szCommand then
        log("Exec console command on server :", szCommand)
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCommand, nil)
        GMSystem:Exec(szCommand) -- ExecuteConsoleCommand不会触发GMSystem:Exec，所以为了保证自定义GM指令能走到，手动调用一次
    end
end

local function DebugAiServer(tbPlayer, tbParams)
    local GameCoreProxyClient = require("GameCoreProxyClient")
    GameCoreProxyClient:EnableDebug((tbParams[2] and true or false))
end

local function CheckAIDoor(tbPlayer, tbParams)
    local nSize = tonumber(tbParams[2] or 200)
    local AIDestructibleObjectManager = CommonShell.GetCommon(GWorld):GetAIDestructibleObjectManager()
    local bFound, tbInstanceIds = AIDestructibleObjectManager:GetDoors(tbPlayer:GetLocation(), nSize)
    if bFound then
        logerror("found door")
        for _,v in ipairs(tbInstanceIds) do
            local tbGameDoor = GameObjectSystem:FindByInstanceId(v)
            log("door type ", tbGameDoor.ObjectType, v)
            local pUEActor = tbGameDoor.pUEActor
            local nCurState = enumtoint(pUEActor:GetCurState())
            local pSelfLocation = tbPlayer:GetLocation()
            local pDoorLocation = pUEActor:K2_GetActorLocation()
            log("player location ", pSelfLocation.X, pSelfLocation.Y, pSelfLocation.Z)
            log("door location ", pDoorLocation.X, pDoorLocation.Y, pDoorLocation.Z)
            local nDistance = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pDoorLocation)
            log("distance between player and door ", nDistance)
            local nState = 0
            if nCurState == 0 then -- closed
                local pDoorTransform = pUEActor:GetTransform()
                local pOutLocation   = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.OutPoint)
                local nDistanceOut   = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pOutLocation)
                local pInLocation    = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.InPoint)
                local nDistanceIn    = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pInLocation)
                if nDistanceOut < nDistanceIn then
                    nState = 1
                else
                    nState = 2
                end
            end
            log("req door state ", nState)
            pUEActor:SwitchDoor(nState)
        end
    else
        logerror("not found door")
    end
end

local function PrintAIDoorStat(tbPlayer, tbParams)
    local AIDestructibleObjectManager = CommonShell.GetCommon(GWorld):GetAIDestructibleObjectManager()
    AIDestructibleObjectManager:DumpStat()
end


local function ArrangeAgentDistribution(tbPlayer, tbParams)
    local nTeamPerIsland = tonumber(tbParams[2] or 1)
    local GameCoreAgentDistribution = dynamic_require("GameCoreAgentDistribution")
    GameCoreAgentDistribution.bOneTeamPerIsLand = nTeamPerIsland > 0
    log("one team per island:", GameCoreAgentDistribution.bOneTeamPerIsLand)
end

local function EnableDLAgent(tbPlayer, tbParams)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.EnableDLAgent = true
    log("enable dl agent ", GlobalVariableSystem.EnableDLAgent)
end

local function EnableDLAgentName(tbPlayer, tbParams)
    local bShow = tonumber(tbParams[2] or 0) > 0
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    local GameCoreHelper = require("GameCoreHelper")
    GameCoreHelper.ShowAgentName(bShow)
    GlobalVariableSystem.bShowDLAgentName = bShow
end

local function EnableTeamWithBot(tbPlayer, tbParams)
    local bEnable = tonumber(tbParams[2] or 0) > 0
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.bEnableTeamWithBot = bEnable
end



local function OpenGameCoreNetLog(tbPlayer, tbParams)
    local bShow = tonumber(tbParams[2] or 0) > 0
    local GameCoreProxyClient = require("GameCoreProxyClient")
    GameCoreProxyClient:OpenNetLog(bShow)
end

local function SetNetLogEnabled(tbPlayer, tbParams)
    CommonShell.SetNetLogEnabled(tbParams[2] ~= nil and tbParams[2] == "1")
end

local function SetAdditionalSuccessEnabled(tbPlayer, tbParams)
    local EventManager = require("EventManager")
    local CommonEventDef = require("CommonEventDef")
    EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_ENABLE, tbParams[2] ~= nil and tbParams[2] == "1")
end

local function PrintPoisonCircleInfo(tbPlayer, tbParams)
    local EventManager = require("EventManager")
    local CommonEventDef = require("CommonEventDef")
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PRINT_POISONCIRCLE_INFO)
end

local function PrintAgentMovementState(tbPlayer, tbParams)
    local nId = tonumber(tbParams[2])
    local tbGameObject = GameObjectSystem:FindByInstanceId(nId)
    if not tbGameObject then
        local GameCoreProxyClient = require("GameCoreProxyClient")
        if GameCoreProxyClient.tbAgents[nId] then
            tbGameObject = GameCoreProxyClient.tbAgents[nId]:GetGameObject()
        end
    end
    if tbGameObject and tbGameObject:IsHuman() then
        logerror("movement state:", enumtoint(tbGameObject.pUEActor.CharacterMovement.MovementMode))
        logerror("max speed:", tbGameObject.pUEActor.CharacterMovement.MaxWalkSpeed)
    end
end

local function QueryVehicle(tbPlayer, tbParams)
    local nDistance = tonumber(tbParams[2])
    local nFov = tonumber(tbParams[3])
    local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
    local tbVehicles = AIVehicleManager:FindVisibleVehicle(tbPlayer.pUEActor, 0,nDistance, nFov, GWorld)
    for i,v in ipairs(tbVehicles) do
        log("found vehicle:", v)
    end
end

local function DumpOceanGrid(tbPlayer, tbParams)
    local AIOceanGridSystem = require("AIOceanGridSystem")
    AIOceanGridSystem:Dump()
    CommonShell.Get(GWorld):GetAIVehicleManager():Dump()
end

local function QueryOceanGrid(tbPlayer, tbParams)
    local nDistance = tonumber(tbParams[2])
    local nFov = tonumber(tbParams[3])
    local pOceanGridManager = CommonShell.Get(GWorld):GetAIOceanGridManager()
    rts()
    local tbVisibleTorpedo = pOceanGridManager:FindTorpedo(tbPlayer.pUEActor, nDistance, nFov, GWorld)
    rte("found torpedo")
    for i,v in ipairs(tbVisibleTorpedo) do
        log("torpedo:", v)
    end
end

local function FindDiamond(tbPlayer)
    local DiamondContainer = require("DiamondContainer")
    DiamondContainer:FindPlayerNearbyDiamondXYZ(tbPlayer)
end

local function EnableSyncRealPlayer(tbPlayer, tbParams)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.bEnableSyncRealPlayer = true
    log("enable sync real player to ai:", GlobalVariableSystem:EnableSyncRealPlayerDataToAI())
end

local function ShipNavMove(tbPlayer, tbParams)
    local nX = tonumber(tbParams[2])
    local nY = tonumber(tbParams[3])
    local nZ = tonumber(tbParams[4]) and tonumber(tbParams[4]) or 100
    local pLocation = Vector{X = nX, Y = nY, Z = nZ}
    if tbPlayer and tbPlayer:IsShip() then
        tbPlayer.pUEActor:NavMove(pLocation, 100, true, {})
    end
end

local function StopShipNavMove(tbPlayer, tbParams)
    if tbPlayer and tbPlayer:IsShip() then
        tbPlayer.pUEActor:AbortNavMove(EMapNavGridPathFollowingResult.Aborted)
    end
end

local function CreateBot(tbPlayer, tbParams)
    local nX = tonumber(tbParams[2])
    local nY = tonumber(tbParams[3])
    local nZ = tonumber(tbParams[4])
    local nTeamId = tonumber(tbParams[5])
    local nItem = tonumber(tbParams[6])
    local BotAISystem = dynamic_require("BotAISystem")
    local tbBot = BotAISystem:CreateBot(nil, 2, nTeamId)
    tbBot:SetLocation(nX, nY, nZ)
    local nRegionType = CommonShell.GetCommon(GWorld):GetGridTypeManager():GetRegionType(nX, nY)
    local RegionTypeOcean = EPiratesGridRegionType.Ocean
    local RegionTypePort  = EPiratesGridRegionType.Port
    local bShip = false
    if nRegionType == RegionTypeOcean or nRegionType == RegionTypePort then
        bShip = true
    end
    local DelayTimer = require("DelayTimer")
    DelayTimer:RunNextTick(function()
        if nItem then
            local BattleItemSystemServer = require("BattleItemSystemServer")
            BattleItemSystemServer:AddItemByTemplate(tbBot.nServerInstanceId ,nItem, 1)
        end
        if bShip then
            local nShipId = tbBot:GetShipTemplateId()
            BattleGameModeSystem:GetGameMode():ChangeToShip(tbBot, nShipId, Vector{X = nX, Y = nY, Z = nZ})
        end
    end)

end

local function ResetSkyTime(tbPlayer, tbParams)
    local nStartTimeHour   = tonumber(tbParams[2])
    local nStartTimeMinute = tonumber(tbParams[3])
    local nEndTimeHour     = tonumber(tbParams[4])
    local nEndTimeMinute   = tonumber(tbParams[5])

    local BattleSkySystem = dynamic_require("BattleSkySystem")
    BattleSkySystem:ResetStartEndTime(nStartTimeHour, nStartTimeMinute, nEndTimeHour, nEndTimeMinute)
end

local function SetShipBotProportion(tbPlayer, tbParams)
    local nProportion   = tonumber(tbParams[2])
    local GameCoreAgentDistribution = require("GameCoreAgentDistribution")
    GameCoreAgentDistribution.bBotLocationProportion = true
    GameCoreAgentDistribution.nBotLocationProportionOfShip = nProportion
end

local function ResetTrainingCampTime(tbPlayer, tbParams)
    local nTime = tonumber(tbParams[2])
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if tbSetting.ResetReleaseTime then
        tbSetting:ResetReleaseTime(nTime + 60)
    end
end

local function SetShipFiringDebugEnabled(tbPlayer, tbParams)
    if tbPlayer
    and tbPlayer:IsShip()
    and tbPlayer.pUEActor then
        local bEnabled = tbParams[2] == "1"
        tbPlayer.pUEActor.CameraDebugEnabled = bEnabled
        if not bEnabled then
            tbPlayer.pUEActor:SyncServerCameraInfoToClient(KismetMathLibrary.MakeVector(0,0,0), KismetMathLibrary.MakeRotator(0,0,0))
        end
    end
end

local function ToggleAIShipVisibilityEnable(tbPlayer, tbParams)
    local bEnabled = tonumber(tbParams[2]) > 0
	local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if pGameInstance and pGameInstance.GlobalSettings then
        log("old ai ship visibility:", pGameInstance.GlobalSettings.AIUseShipVisibility)
        pGameInstance.GlobalSettings.AIUseShipVisibility = bEnabled
        log("toggle ai ship visibility:", bEnabled)
    end
end

local function SetAIAgentLevel(tbPlayer, tbParams)
    local szStrategy = (tbParams[2])
    local GameCoreAgentLevel = require("GameCoreAgentLevel")
    GameCoreAgentLevel:InitStrategy(szStrategy)
end


local function AICmd(tbPlayer, tbParams)
    local AIDebug = require("AIDebug")
    AIDebug:ProcessCmd(tbPlayer, tbParams)
end

local function RegisterGMCommand()
    CommandFuncs["startfile"] = StartFile
    CommandFuncs["stopfile"] = StopFile
    CommandFuncs["memreport"] = MemReport
    CommandFuncs["startmallocleak"] = StartMallocLeak
    CommandFuncs["stopmallocleak"] = StopMallocLeak
    CommandFuncs["reportmallocleak"] = ReportMallocLeak
    CommandFuncs["createnpc"] = CreateNpc
    CommandFuncs["createtrigger"] = Createtrigger
    CommandFuncs["testpathnode"] = TestPathNode
    CommandFuncs["addbuff"] = AddBuff
    CommandFuncs["removebuff"] = RemoveBuff
--    CommandFuncs["killbots"] = KillBots
    CommandFuncs["resetskillcd"] = ResetSkillCD
    CommandFuncs["interruptskill"] = InterruptSkill
    CommandFuncs["testsendbattlestats"] = TestSendBattleStats
    CommandFuncs["teleport"] = Teleport -- Params: nX, nY
    CommandFuncs["teleportbot"] = TeleportBot -- Params: nBotId, nX, nY
    CommandFuncs["setgeardata"] = SetGearData -- Params: nType, nValue
    CommandFuncs["setshipmovegearbuff"] = SetShipMoveGearBuff -- Params: nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration
    CommandFuncs["usingasyncpathfindingforai"] = UsingAsyncPathFindingForAI --Params 0/1
    CommandFuncs["changetoship"] = ChangeToShip --Params shipid
    CommandFuncs["changetohuman"] = ChangeToHuman --Params humanid, bDockShip
    CommandFuncs["movetotestpoint"] = MoveToTestPoint -- param test point index
    CommandFuncs["killobject"] = KillObject
    CommandFuncs["cureobject"] = CureObject
    CommandFuncs["gainep"] = GainEp
    CommandFuncs["addsceneitembox"] = AddSceneItemBox
    CommandFuncs["damageenemy"] = ApplyDamageEnemy
    CommandFuncs["consumeep"] = ConsumeEp
    CommandFuncs["additem"] = AddBattleItem
    CommandFuncs["additembytemplate"] = AddItemByTemplate
    CommandFuncs["destroyUnequippeditems"] = DestroyUnequippedItemsByTemplate
    CommandFuncs["clearbackpack"] = ClearBackpack
    CommandFuncs["initgroupitem"] = InitGroupItem
    CommandFuncs["hurtself"] = HurtSelf -- Param: nDamage
    CommandFuncs["cureself"] = CureSelf -- Param: nCuringValue
    CommandFuncs["printmaxhp"] = PrintMaxHp
    CommandFuncs["invincible"] = Invincible
    CommandFuncs["invincibletopoisoncircle"] = InvincibleToPoisonCircle
    CommandFuncs["raiseluaerror"] = RaiseLuaError
    CommandFuncs["killBots"] = KillBotsEx
    CommandFuncs["setcorrectiondistance"] = SetCorrectionDistance
    CommandFuncs["settimecorrect"] = SetCorrectionTime
    CommandFuncs["createsquad"] = CreateSquad
    CommandFuncs["createaiteammate"] = CreateAITeammate
    CommandFuncs["sethumanweaponproperty"] = SetHumanWeaponProperty
    CommandFuncs["changeteam"] = ChangeTeam
    CommandFuncs["enabledying"] = EnableDying
    CommandFuncs["setteamnumber"] = SetTeamNumber
    CommandFuncs["battletestautomation"] = BattleTestAutomation
    CommandFuncs["cmd"] = ServerCmd
    CommandFuncs["showBotName"] = ToggleBotName
    CommandFuncs["gatherBot"] = ToggleBotNearby
    CommandFuncs["spawnBotByTime"] = SpawnBotByTime
    CommandFuncs["luadebug"] = LuaDebug
    CommandFuncs["luamem"] = PrintLuaMemory
    CommandFuncs["luagc"] = LuaGC
    CommandFuncs["finddiamond"] = FindDiamond
    CommandFuncs["changepoisoncirlce"] = ChangePoisonCirclePosition
    CommandFuncs["landId"] = GetLandId
    CommandFuncs["toggleBotAlwaysRelevent"] = ToggleBotAlwaysRelevent
    CommandFuncs["printtemplateactorinfo"] = PrintTemplateActorInfo
    CommandFuncs["kickoutBot"] = KickoutBot
    CommandFuncs["sendplayerresult"] = SendPlayerResult
    CommandFuncs["sendteamresult"] = SendTeamResult
    CommandFuncs["testbotdead"] = TestBotDead
    CommandFuncs["kickallplayers"] = KickAllPlayers
    CommandFuncs["kickplayer"] = KickPlayerByName
    CommandFuncs["startViewBots"] = StartViewBots
    CommandFuncs["transformToBot"] = TransformToBot
    CommandFuncs["testcoverpoint"] = TestCoverPoint
    CommandFuncs["createvehicle"] = CreateVehicle
    CommandFuncs["deletetimer"] = DeleteTimer
    CommandFuncs["enableNPCAlert"] = EnableNPCAlert
    CommandFuncs["setdmenabled"] = SetDMEnabled
    CommandFuncs["sendtestdatatoclient"] = SendTestDataToClient
    CommandFuncs["setrepplayernum"] = SetReplicatePlayerNum
    CommandFuncs["setboolvalue"] = SetBoolValue
    CommandFuncs["enableBotSupply"] = EnableBotSupply
    CommandFuncs["setdelaydieboxtime"] = SetDelayDieBoxTime
    CommandFuncs["cleardelaydieboxtime"] = ClearDelayDieBoxTime
    CommandFuncs["gamespeed"] = GameSpeed
    CommandFuncs["enableffadamage"] = SetFFADamageEnabled
    CommandFuncs["testlinetrace"] = TestLineTrace
    CommandFuncs["teleporttonpc"] = Teleport2Npc
    CommandFuncs["createtraningai"] = CreateAITrainingBot
    CommandFuncs["aiaction"] = DoAIAction
    CommandFuncs["toggleBot"] = ToggleBot
    CommandFuncs["toggleBack"] = ToggleBack
    CommandFuncs["memSnapshotDump"] = MemSnapshotDump
    CommandFuncs["printMem"] = PrintMem
    CommandFuncs["setdamageenabled"] = SetDamageEnabled
    CommandFuncs["hideotherselectionpoint"] = HideOtherSelectionPoint
    CommandFuncs["finalpoint"] = FinalPoint -- Params: nX, nY
    CommandFuncs["skipparachute"] = SkipParachute
    CommandFuncs["exec"] = ExecOnServer
    CommandFuncs["debugaiserver"] = DebugAiServer
    CommandFuncs["checkaidoor"] = CheckAIDoor
    CommandFuncs["printaidoorstat"] = PrintAIDoorStat
    CommandFuncs["arrangeagnetdistribution"] = ArrangeAgentDistribution
    CommandFuncs["enabledlagent"] = EnableDLAgent
    CommandFuncs["showdlagentname"] = EnableDLAgentName
    CommandFuncs["enableteamwithbot"] = EnableTeamWithBot
    CommandFuncs["opengamecorenetlog"] = OpenGameCoreNetLog
    CommandFuncs["setnetlogenabled"] = SetNetLogEnabled
    CommandFuncs["setasenabled"] = SetAdditionalSuccessEnabled
    CommandFuncs["printpoisoncircle"] = PrintPoisonCircleInfo
    CommandFuncs["printagentmovementstate"] = PrintAgentMovementState
    CommandFuncs["queryvehicle"] = QueryVehicle
    CommandFuncs["dumpoceangrid"] = DumpOceanGrid
    CommandFuncs["queryoceangrid"] = QueryOceanGrid
    CommandFuncs["enablesyncrealplayer"] = EnableSyncRealPlayer
    CommandFuncs["shipnavmove"] = ShipNavMove
    CommandFuncs["stopshipnavmove"] = StopShipNavMove
    CommandFuncs["createbot"] = CreateBot
    CommandFuncs["resetskytime"] = ResetSkyTime
    CommandFuncs["setshipbotproportion"] = SetShipBotProportion
    CommandFuncs["hurtwatchtarget"] = HurtWatchTarget
    CommandFuncs["resettrainingcamptime"] = ResetTrainingCampTime
    CommandFuncs["setshipfiringdebugenabled"] = SetShipFiringDebugEnabled
    CommandFuncs["toggleaishipvisibilityenable"] = ToggleAIShipVisibilityEnable
    CommandFuncs["setaiagentlevel"] = SetAIAgentLevel
    CommandFuncs["aicmd"] = AICmd
end

local function NotifyPlayers(tbPlayer, szParam)
    if not tbPlayer then
        return
    end

    local szCommand = szParam
    local nSize = string.len(szParam)
    local COMMAND_LENGTH = 50
    if nSize > COMMAND_LENGTH then
        szCommand = string.sub(szParam, 1, COMMAND_LENGTH)
    end
    BattleSpecialToastHelper:ShowSpecialToast(nil, 6,
    tbPlayer.szName, szCommand, "", ProtoDC.BattleToastInfo_EToastType.SPECIAL, 0, 3, 0, 0)
end

local function OnServerExecGM(pPlayerController, szParam)
    local tbPlayer = GetPlayerSelfByPlayerController(pPlayerController)
    if tbPlayer then
        if IsValidPlayer(tbPlayer) then
            local StringUtil = require("StringUtil")
            local tbParams = StringUtil.Split(szParam, " ")
            if tbParams then
                local CommandFunc = CommandFuncs[tbParams[1]]
                if CommandFunc then
                    log('OnServerExecGM, szParam:', szParam, tbPlayer.szName)
                    CommandFunc(tbPlayer, tbParams)
                    NotifyPlayers(tbPlayer, szParam)
                end
            else
                logwarning('OnServerExecGM failed, tbParams is nil.')
            end
        else
            if szParam == "cleardmenabled" then
                ClearOwnerPlayer()
            else
                local D2CHelper = require("D2CHelper")
                D2CHelper:SendCommonToast(tbPlayer, "FFA_DM_DISABLED", tbOwnerPlayerName)
                log('OnServerExecGM failed, dm is disabled. szParam:', szParam, tbPlayer.szName)
            end
        end
    else
        logerror("Cannot find player!")
    end

end

function BattleGMCppDelegateProcessor:Init()
    BattleGMCppDelegateProcessor.super.Init(self)

    RegisterGMCommand()

    -- Register Gameplay Delegate
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager()
    self:Register(DelegateMgr.Player.OnServerExecGM, OnServerExecGM)
    return true
end

function BattleGMCppDelegateProcessor:Uninit()
    ClearOwnerPlayer()
    BattleGMCppDelegateProcessor.super.Uninit(self)
end

return BattleGMCppDelegateProcessor