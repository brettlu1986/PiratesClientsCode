-- 新手章鱼战斗副本
--
-- 注意：
-- 新手副本使用local 变量，要考虑 “返回登录” 操作
-- local 变量要注意初始化，避免使用上次的错误数据
--
-- 
--
---------------------------------------------------------------------------------------
-- require

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local TutorialOctopusBattleStep = luaclass("TutorialOctopusBattleStep", BattleStepBaseClass)

local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

local TutorialStep = require("TutorialStep")

local NpcDialogBoardHelper = require("NpcDialogBoardHelper")

local SelfTimerHelper = require("SelfTimerHelper")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local BattleObjectiveHelper = require("BattleObjectiveHelper")

-- local HandlerManagerHelper = require("HandlerManagerHelper")

---------------------------------------------------------------------------------------
-- local variable

------------------------------------------------------ 配置信息 begin

local tbJsonData = nil

-- 玩家初始位置
local nPlayerStartGroupId = 0

-- Jack初始位置
local nJackStartGroupId = 0

-- 章鱼group id
local nOctopusGroupId = 0

-- 队友group id
local nSameCampGroupId = 0

-- 通过章鱼血量达到80%时候，切换第二阶段
local nSecondStageRatio = 0.8

-- 通过章鱼血量达到20%时候，副本结束，通知指引
local nFinishRatio = 0.2

-- 支持根据血量播放伴随对话 
-- 如果需要播放，将0设置为dialog_id
local tbHpRatioDialog = 
{
    [0.8] = 0,
    [0.7] = 0,
    [0.6] = 0,
    [0.4] = 0,
    [0.2] = 0,
}

-- jack初始的ai
local nJackOctopusAiId = 1525
local nJackOctopusPathId = 0

-- jack离开时候的ai
local nJackLeaveAiId = 1523
local nJackLeavePathId = 2

-- 结束喊话时长
local nFinishDialogSecond = 2

-- Jack离开多长时间后消失
local nJackLeaveSecond = 10

-- 副本与指引交互
local nGuideStep_1 = 1
local nGuideStep_2 = 2
local nGuideStep_3 = 3
local nGuideStep_4 = 4
local nGuideStep_5 = 5
local nGuideStep_7 = 7

-- 震屏技能ID
local SHAKE_SCREEN_SKILL_ID = 407
-- 震屏BP路径
local SHAKE_SCREEN_BP_PATH = "Blueprint'/Game/Game/Ships/CameraShake/BP_Tutorial.BP_Tutorial_C'"

-- 天空盒BP路径
local SKY_CINEMA_BP_PATH = "Blueprint'/Game/Resources/FFA/Sky/Blueprints/BP_Sky_Cinema.BP_Sky_Cinema_C'"
-- 渐变时长  单位：Second
local SKY_CHANGE_SECOND = 10.0
-- 渐变次数
local SKY_CHANGE_NUMBER = 10.0
local nSkyAlpha = 0.0
local tbSky = nil

local NO_SKILL_BUFFER_ID = 5504        -- 禁止技能攻击bufferid

-- 副本目标
local DUNGEON_OBJECTIVE_ID_90014 = 90014
local DUNGEON_OBJECTIVE_ID_90015 = 90015

------------------------------------------------------ 配置信息 end

-- 节点开始时间点
local nStartTime = 0

-- spawn npc 时间点
local nSpawnNpcTime = 0

-- 章鱼npcobject
local tbOctopusNpc = nil

-- 定时器
local tbTimerHelper = nil

-- jack
local tbJackObject = nil

-- -- 章鱼的默认材质
-- local tbMaterials = nil
-- -- 章鱼开镜材质路径
-- local OPEN_MATERIAL_PATH = -- 这个资源已从库里删除，所以把地址干掉了，需要看是什么资源，可以showlog一下

---------------------------------------------------------------------------------------
-- local function 

-- 设置副本目标
local function SendObjectiveInfo(id)
    BattleObjectiveHelper:SendObjectiveInfo(id, true, "", "", "")
end

-- 设置玩家和npc暂停和开启
-- 章鱼暂停时候，不能技能攻击
-- 章鱼开启时候，能技能攻击
local function AllNpcPaused(bPaused)

    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Npc or GameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
            GameObject:SetPaused(bPaused)
        end
    end

    if tbOctopusNpc then 
        if bPaused then
            if tbOctopusNpc.BuffComponentServer then
                tbOctopusNpc.BuffComponentServer:AddBuffById(NO_SKILL_BUFFER_ID)
            end 
        else 
            if tbOctopusNpc.BuffComponentServer then
                tbOctopusNpc.BuffComponentServer:RemoveBuffById(NO_SKILL_BUFFER_ID)
            end
        end
    end

end

-- 战斗完成时，清空timer
local function Complete(self)
    if tbTimerHelper ~= nil then 
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end

    TutorialOctopusBattleStep.super.Complete(self)
end

-- timer处理函数，通知指引
local function NotifyGuide()
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 8)
end

-- 删除jack
local function RemoveJack()
    if tbJackObject then
        GameObjectSystem:DestroyNpcInGameMode(tbJackObject:GetUEActorUniqueId())
    end
end

-- jack离开  修改jack的ai和pathid，指定时间后删除jack
local function JackLeave()
    if not tbJackObject then return end

    local AIComponent = tbJackObject.BattleAIComponent
    AIComponent:DestroyAI()
    AIComponent:CreateAI(nJackLeaveAiId, nJackLeavePathId)

    if not tbTimerHelper then tbTimerHelper = SelfTimerHelper() end
    tbTimerHelper:NewTimerMethod(nil, RemoveJack, nJackLeaveSecond, false)
end

-- 删除所有npc
local function RemoveAllNpc()
    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Npc then
            GameObjectSystem:DestroyNpcInGameMode(GameObject:GetUEActorUniqueId())
        end
    end
    tbJackObject = nil
end

-- 根据章鱼血量，处理逻辑
local function LastNpcHPLessthanTarget(nRatio)
    local tbBattleShipPropertyComponent = tbOctopusNpc.BattleShipPropertyComponent
    -- 解绑处理函数
    tbBattleShipPropertyComponent:UnBindHPReachRatioEvent(LastNpcHPLessthanTarget, nRatio)
    -- 播放伴随对话
    local nDialogId = tbHpRatioDialog[nRatio]
    if nDialogId ~= 0 then
        NpcDialogBoardHelper:OpenDialogBoard(nDialogId)
    end
    -- 章鱼血量80%时候，修改副本目标
    if nRatio == nSecondStageRatio then 
        SendObjectiveInfo(DUNGEON_OBJECTIVE_ID_90015)
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 7)
    end

    -- 章鱼血量20%时候，过nFinishDialogSecond时间后，通知指引
    if nRatio == nFinishRatio then 
        if not tbTimerHelper then tbTimerHelper = SelfTimerHelper() end
        tbTimerHelper:NewTimerMethod(nil, NotifyGuide, nFinishDialogSecond, false)
    end

end

-- 根据章鱼血量，绑定处理函数
local function BindOctopusHPReachRatioEvent(self)
    local tbBattleShipPropertyComponent = tbOctopusNpc.BattleShipPropertyComponent

    for k,v in pairs(tbHpRatioDialog) do
         tbBattleShipPropertyComponent:BindHPReachRatioEvent(k, true, LastNpcHPLessthanTarget, k)
    end
end

-- 通过地图配置文件，找到jack出生点
local function FindNewJsonStart(self, nGroupId)
    local tbJsonStarts = tbJsonData.tbContainer.DungeonPlayerStarts
    if(tbJsonStarts == nil) then
        error("TutorialOctopusBattleStep:FindPlayerNewJsonStart failed")
        return
    end

    local nCount = #tbJsonStarts
    for i=1, nCount do
        local tbJson = tbJsonStarts[i]
        if tbJson.GroupIndex == nGroupId then
            return tbJson
        end
    end
end

-- 将objective设置到指定start point
local function SetLocation(tbObjective, tbStartData)
    local ShipMovementComponent = tbObjective.pUEActor.ShipMovementComponent
    local tbTransform = tbStartData.Transform
    local LocationVector = Vector{X = tbTransform.X, Y = tbTransform.Y, Z = tbTransform.Z}
    ShipMovementComponent:TeleportShip(LocationVector, tbTransform.Yaw, false)

    -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    -- CameraControlManager.CurrentActiveModeComponent:ResetToDefaultParam()
end

-- 设置玩家初始化位置,并暂停所有npc和玩家
local function SetPlayerLocation(self)
    local tbStartData = FindNewJsonStart(self, nPlayerStartGroupId)
    if(tbStartData == nil) then return end

    local PlayerSelf = GamePlayerSelfHelper:Get()
    SetLocation(PlayerSelf, tbStartData)
    AllNpcPaused(true)

end

--  设置Jack初始位置
local function SetJackLocation(self)
    local tbStartData = FindNewJsonStart(self, nJackStartGroupId)
    if(tbStartData == nil) then return end

    SetLocation(tbJackObject, tbStartData)
end

-- 设置jack ai
local function ChangeJackAIAction(self)
    local AIComponent = tbJackObject.BattleAIComponent
    AIComponent:DestroyAI()

    AIComponent:CreateAI(nJackOctopusAiId, nJackOctopusPathId)
end

-- 启动jack
local function ActivateJackShip(self)
    tbJackObject:SetPaused(false)
end

-- 删除所用npc和trigger
local function RemoveAllNpcAndTrigger()
    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Npc or GameObject.ObjectType == GameObjectTypeDef.Trigger then
            GameObjectSystem:DestroyNpcInGameMode(GameObject:GetUEActorUniqueId())
        end
    end
end

-- 震屏效果
local function ShakeScreen()
    local szShakeClass = SHAKE_SCREEN_BP_PATH
    local pShakeClass = szShakeClass:load()
    if pShakeClass then
        local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        if pCameraManager then
            pCameraManager:PlayCameraShake(pShakeClass, 1.0, ECameraAnimPlaySpace.CameraLocal, Rotator())
        end
    end
end

-- 渐变修改天空盒alpha
local function ChangeSky()
    if tbSky then
        nSkyAlpha = nSkyAlpha + 1.0/SKY_CHANGE_NUMBER
        tbSky:ChangeAlpha(nSkyAlpha)
    end

    if nSkyAlpha < 1.0 then
        if not tbTimerHelper then tbTimerHelper = SelfTimerHelper() end
        tbTimerHelper:NewTimerMethod(nil, ChangeSky, SKY_CHANGE_SECOND/SKY_CHANGE_NUMBER, false)
    end
end

-- 修改天空盒
local function StartChangeSky()
    local szSkyCinemaClass = SKY_CINEMA_BP_PATH
    local pSkyCinemaClass = szSkyCinemaClass:load()
    if not pSkyCinemaClass then return end

    local Skys = GameplayStatics.GetAllActorsOfClass(GWorld, pSkyCinemaClass)
    if Skys and #Skys >= 1 then 
        tbSky = Skys[1]
        ChangeSky()
    end
end

-- 开启和关闭瞄准的时候，修改章鱼头部材质
-- local function OnHandlerModeSwitch( self, pMode )
--     if not tbOctopusNpc then return end
--     if not tbOctopusNpc.pUEActor then return end
--     local kraken = tbOctopusNpc.pUEActor.SK_Kraken
--     if not kraken then return end
--     if pMode == Enum_HandlerMode.ShipAimMode then
--         local pOpenMaterial = OPEN_MATERIAL_PATH:load()
--         if pOpenMaterial then
--             kraken:SetMaterial(0, pOpenMaterial)
--         end
--     else
--         kraken:SetMaterial(0, tbMaterials[1])
--     end
-- end

---------------------------------------------------------------------------------------
-- iface 

function TutorialOctopusBattleStep:Init()
    TutorialOctopusBattleStep.super.Init(self)
    self.szName = "TutorialOctopusBattleStep"
end

-- 设置jack外部接口
function TutorialOctopusBattleStep:SetJack(tbJack)	
    tbJackObject = tbJack
end

-- 设置配置信息
function TutorialOctopusBattleStep:SetParams(JsonData, tbTemplateData)
    tbJsonData = JsonData
    nPlayerStartGroupId = tbTemplateData.nAttackOcotpusStartGroupId
    nOctopusGroupId = tbTemplateData.nOctopusGroupId
    nSameCampGroupId = tbTemplateData.nSameCampGroupId
    nJackStartGroupId = tbTemplateData.nJackStartGroupId
end

function TutorialOctopusBattleStep:Start()
    TutorialOctopusBattleStep.super.Start(self)
    -- 检测是否跳过
    if TutorialStep.STEP_IS_SKIP then
        TutorialOctopusBattleStep.super.Complete(self)
        return
    end

    -- 开始时间
    nStartTime = GlobalVariableSystem:GetLocalTime()

    -- 指引通知副本结束
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_DUNGEON_COMPLETED, self, self.OnComplete)
    -- 指引通知spawn npc
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_DUNGEON_SPAWN_NPC, self, self.SpawnNpc)
    -- 副本和指引交互
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_STEP_END, self, self.GuideStepEnd)
    -- 指引通知跳过副本
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_SKIP_DUNGEON, self, self.Skip)
    -- 释放技能
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_PAWN_CAST_SKILL, self, self.OnPawnCastSkill)
    -- 切换瞄准模式
    -- self.SelfEventHelper:RegisterLuaDelegate(HandlerManagerHelper.OnModeSwitchDelegate, OnHandlerModeSwitch, self)

    -- 设置玩家、jack位置
    SetPlayerLocation(self)
    if not tbJackObject then return end
    SetJackLocation(self)

end

-- 释放指定技能时候，播放震屏效果
function TutorialOctopusBattleStep:OnPawnCastSkill(tbPawn, nSkillId)
    if nSkillId == SHAKE_SCREEN_SKILL_ID then 
        ShakeScreen()
    end
end

-- 指引和副本交互
function TutorialOctopusBattleStep:GuideStepEnd(nStep)
    -- jack 离开
    if nStep == nGuideStep_1 then
        JackLeave() 
    end
    -- 删除所有npc
    if nStep == nGuideStep_2 then 
        RemoveAllNpc() 
    end
    -- 开始修改天空盒
    if nStep == nGuideStep_3 then 
        StartChangeSky() 
    end
    -- 玩家和npc暂停
    if nStep == nGuideStep_4 then 
        AllNpcPaused(true)
    end
    -- 玩家和npc启动
    if nStep == nGuideStep_5 then 
        AllNpcPaused(false)
    end

    -- 开场对话结束，调整摄像头视角，设置副本目标
    if nStep == nGuideStep_7 then  
        -- if tbOctopusNpc then 
        --     --local PlayerSelf = GamePlayerSelfHelper:Get()

        --     -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        --     -- CameraControlManager.CurrentActiveModeComponent:LookForActor(tbOctopusNpc.pUEActor)

        --     tbMaterials = tbOctopusNpc.pUEActor.SK_Kraken:GetMaterials()
        -- end

        SendObjectiveInfo(DUNGEON_OBJECTIVE_ID_90014)
    end

end

-- spawn npc
function TutorialOctopusBattleStep:SpawnNpc()
    -- 刷新章鱼
    local tbObjs = SpawnerSystem:SpawnByGroupIndex(nOctopusGroupId, SpawnerDef.SpawnerType.ALL_NPC)
    tbOctopusNpc = tbObjs[1]

    -- 刷新友军船只
    SpawnerSystem:SpawnByGroupIndex(nSameCampGroupId, SpawnerDef.SpawnerType.ALL_NPC)

    -- 绑定章鱼血量处理函数
    BindOctopusHPReachRatioEvent(self)

    -- 玩家朝向章鱼
    local PlayerSelf = GamePlayerSelfHelper:Get()
    -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    -- CameraControlManager.CurrentActiveModeComponent:LookForActor(tbOctopusNpc.pUEActor)

    -- 章鱼强制攻击玩家
    tbOctopusNpc.BattleAIComponent:SetForcedTargetToAttack(PlayerSelf)

    -- 修改jack的ai，并启动jack
    if not tbJackObject then return end
    ChangeJackAIAction(self)
    ActivateJackShip(self)

    -- 数据埋点
    nSpawnNpcTime = GlobalVariableSystem:GetLocalTime()
    TutorialStep:SendDungeonCompleteStep(TutorialStep.STEP_QTE_4, nSpawnNpcTime - nStartTime)

end

-- 跳过处理
function TutorialOctopusBattleStep:Skip()
    if tbTimerHelper ~= nil then 
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end

    TutorialStep.STEP_IS_SKIP = true

    -- 删除所有npc和trigger
    RemoveAllNpcAndTrigger()
    
    TutorialOctopusBattleStep.super.Complete(self)
end

-- 完成处理
function TutorialOctopusBattleStep:OnComplete()
    -- 数据埋点
    TutorialStep:SendDungeonCompleteStep(TutorialStep.STEP_OCTOPUS_5, GlobalVariableSystem:GetLocalTime() - nSpawnNpcTime)
    Complete(self)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function TutorialOctopusBattleStep:SnapshotToReplicatedProperty()
    return true
end

-- 强制退出，清空timer
function TutorialOctopusBattleStep:UnregisterEvent()
    if tbTimerHelper ~= nil then 
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end 
    TutorialOctopusBattleStep.super.UnregisterEvent(self)
end

return TutorialOctopusBattleStep
