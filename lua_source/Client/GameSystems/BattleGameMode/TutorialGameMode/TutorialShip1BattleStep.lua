-- 新手第1次战斗（1艘船只）
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
local TutorialShip1BattleStep = luaclass("TutorialShip1BattleStep", BattleStepBaseClass)

local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local SelfTimerHelper = require("SelfTimerHelper")

local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local TutorialStep = require("TutorialStep")

local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")

local GlobalVariableSystem = require("GlobalVariableSystem_C")

local TutorialOctopusBattleStepClass = require("TutorialOctopusBattleStep")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NpcDialogBoardHelper = require("NpcDialogBoardHelper")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local BattleTargetTrackHelper = require("BattleTargetTrackHelper")

---------------------------------------------------------------------------------------
-- local variable

------------------------------------------------------ 配置信息 begin

local nJackGroupId = 0         -- jack的groupid

local nEnemyShipGroupId = 0    -- 敌船的groupid

local ENEMY_SKILL_1 = 411      -- 敌船的技能id
local ENEMY_SKILL_2 = 412
local ENEMY_SKILL_3 = 413
local ENEMY_SKILL_4 = 414

local SKILL_SECOND_1 = 0.5        -- 释放技能1时间差
local CAST_SKILL_1_MAX = 10       -- 最多尝试释放技能1的次数   
local SKILL_SECOND_2 = 10         -- 释放技能2时间差
local SKILL_SECOND_3 = 10         -- 释放技能3时间差
local GENERAL_ATTACK_SECOND = 6   -- 普通攻击时间差
local SKILL_SECOND_4 = 60         -- 释放技能4时间差
local SKILL_SECOND_4_CD = 15      -- 释放技能4cd
local CAST_SKILL_4_MAX = 3        -- 每次释放技能4的次数

local ENEMY_SHIP_SINK_SECOND = 1       -- 敌船沉船时间

local INVINCIBLE_BUFFER_ID = 10056     -- 锁血20%的bufferid
local NO_ATTACK_BUFFER_ID  = 5505      -- 禁止普通攻击bufferid
local NO_SKILL_BUFFER_ID = 5504        -- 禁止技能攻击bufferid

local Dialog_ID_500117 = 500117        -- 伴随对话ID
local Dialog_ID_500118 = 500118
local Dialog_ID_500119 = 500119
local Dialog_ID_500120 = 500120
local Dialog_ID_500121 = 500121
local Dialog_ID_500122 = 500122
local Dialog_ID_500123 = 500123

local ATTACK_DIALOG_SECOND_1 = 30       -- 普通攻击时候，伴随对话出现时机
local ATTACK_DIALOG_SECOND_2 = 50

local DUNGEON_OBJECTIVE_ID_90012 = 90012   -- 副本目标ID
local DUNGEON_OBJECTIVE_ID_90013 = 90013
local DUNGEON_OBJECTIVE_ID_90017 = 90017

local nGuideStep_4 = 4      -- 副本与指引交互ID
local nGuideStep_5 = 5
local nGuideStep_6 = 6
--local nGuideStep_8 = 8

--local TRIGGER_ID = 1         -- Trigger Id

local TARGET_TRACK_ID = 2    -- Trigger 指引

------------------------------------------------------ 配置信息 end

local tbJsonData = nil          -- 副本json data
local tbTimerHelper = nil       -- 定时器

local tbJackObject = nil        -- jack
local tbEnemyObject = nil       -- 敌船
--local tbTriggerObjective = nil  -- trigger

local nCastSkill1Count = 0      -- 当前技能1的释放次数
local nCastSkill4Count = 0      -- 当前技能4的释放次数

local bGuideStep5 = false       -- 指引第五步的标志位

local nStartTime = 0            -- 该步骤开始时间
local nEnterTriggerTime = 0     -- 进入trigger时间

local bShowDialogFlag = true    -- 是否显示伴随对话标识

---------------------------------------------------------------------------------------
-- local function

-- 初始化local variable, 考虑返回登录界面的情况
local function InitVar()
    nCastSkill1Count = 0     -- 当前技能1的释放次数
    nCastSkill4Count = 0     -- 当前技能4的释放次数
    bGuideStep5 = false      -- 指引第五步的标志位
    nStartTime = 0           -- 该步骤开始时间
    nEnterTriggerTime = 0    -- 进入trigger时间
    bShowDialogFlag = true   -- 是否显示伴随对话标识
end

-- 初始化trigger 指引，设置指引目标，但不显示
local function InitTargetTrack(nTargetTrackId)
    for _, tbTransform in ipairs(tbJsonData.tbContainer.Transforms) do
        if tbTransform.TransformId == nTargetTrackId then
            BattleTargetTrackHelper:ShowTargetTrackPos(nil, tbTransform.Transform.X, tbTransform.Transform.Y, tbTransform.Transform.Z)
            BattleTargetTrackHelper:SetTargetTrackVisible(nil, false) -- Init but not display.
            return
        end 
    end
end

-- 创建trigger
local function CreateTrigger(self)
    local tbTriggers = tbJsonData.tbContainer.Triggers
    if tbTriggers == nil then return end

    -- local nCount = #tbTriggers
    -- for i=1, nCount do
    --     local tbJson = tbTriggers[i]
    --     if tbJson.TriggerId == TRIGGER_ID then
    --         --local tbData = {tbJsonData = tbJson}
    --         --tbTriggerObjective = GameObjectSystem:CreateTriggerInGameMode(tbData)
    --     end
    -- end
end

-- 删除trigger，隐藏trigger指引
local function RemoveAllTrigger(self)
    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Trigger then
            GameObjectSystem:DestroyNpcInGameMode(GameObject:GetUEActorUniqueId())
        end
    end
    BattleTargetTrackHelper:SetTargetTrackVisible(nil, false)
end

-- 设置副本目标
local function SendObjectiveInfo(id)
    BattleObjectiveHelper:SendObjectiveInfo(id, true, "", "", "")
end

-- 暂停或者启动npc和玩家。
-- 在暂停的时候，敌船不能技能攻击，不能显示伴随对话。
-- 在启动的时候，敌船能技能攻击，能显示伴随对话。
local function AllNpcPaused(bPaused)

    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Npc or GameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
            GameObject:SetPaused(bPaused)
        end
    end

    if bPaused then
        if tbEnemyObject and tbEnemyObject.BuffComponentServer then
            tbEnemyObject.BuffComponentServer:AddBuffById(NO_SKILL_BUFFER_ID) 
        end
        
        bShowDialogFlag = false 
    else
        if tbEnemyObject and tbEnemyObject.BuffComponentServer then
            tbEnemyObject.BuffComponentServer:RemoveBuffById(NO_SKILL_BUFFER_ID)
        end
        
        bShowDialogFlag = true
    end 
end

-- jack锁血
-- 敌船禁止普通攻击
local function AddBuffer(self)
    if tbJackObject.BuffComponentServer then
        tbJackObject.BuffComponentServer:AddBuffById(INVINCIBLE_BUFFER_ID)
    end
    
    if tbEnemyObject.BuffComponentServer then
        tbEnemyObject.BuffComponentServer:AddBuffById(NO_ATTACK_BUFFER_ID)
    end 
end

-- 创建jack
local function CreateJack(self)
    local tbObjects = SpawnerSystem:SpawnByGroupIndex(nJackGroupId, SpawnerDef.SpawnerType.ALL_NPC)
    tbJackObject = tbObjects[1]
end

-- 创建敌船，并初始化敌船技能
local function CreateEnemyShip(self)
    local tbObjects = SpawnerSystem:SpawnByGroupIndex(1, SpawnerDef.SpawnerType.ALL_NPC)
    tbEnemyObject = tbObjects[1]
    
    tbEnemyObject.SkillComponentServer:AcquireSkill(ENEMY_SKILL_1, 1)
    tbEnemyObject.SkillComponentServer:AcquireSkill(ENEMY_SKILL_2, 1)
    tbEnemyObject.SkillComponentServer:AcquireSkill(ENEMY_SKILL_3, 1)
    tbEnemyObject.SkillComponentServer:AcquireSkill(ENEMY_SKILL_4, 1)

    if not tbTimerHelper then 
        tbTimerHelper = SelfTimerHelper()
    end
end

-- 将jack赋值给章鱼战斗模块
local function SetJack(self)
    TutorialOctopusBattleStepClass:SetJack(tbJackObject)
end

-- 删除所有npc和trigger
local function RemoveAllNpcAndTrigger()
    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Npc or GameObject.ObjectType == GameObjectTypeDef.Trigger then
            GameObjectSystem:DestroyNpcInGameMode(GameObject:GetUEActorUniqueId())
        end
    end
end

---------------------------------------------------------------------------------------
-- iface

-- 设置配置信息
function TutorialShip1BattleStep:SetParams(JsonData, EnemyShipGroupId, JackGroupId)
    tbJsonData = JsonData
    nEnemyShipGroupId = nEnemyShipGroupId
    nJackGroupId = JackGroupId
end

function TutorialShip1BattleStep:Init()
    TutorialShip1BattleStep.super.Init(self)
    self.szName = "TutorialShip1BattleStep"
end

function TutorialShip1BattleStep:Start()
    -- 初始化local variable
    InitVar()
    TutorialShip1BattleStep.super.Start(self)

    -- 跳过
    if TutorialStep.STEP_IS_SKIP then
        TutorialShip1BattleStep.super.Complete(self)
        return
    end

    UIManager:OpenWnd(UIDef.UI_SKIP_GUIDE)

    -- 开始时间点
    nStartTime = GlobalVariableSystem:GetLocalTime()
    -- 数据埋点
    TutorialStep:SendDungeonCompleteStep(TutorialStep.STEP_PLAYER_SPAWN_1, 0)
    -- 初始化trigger 指引，设置指引目标，但不显示
    InitTargetTrack(TARGET_TRACK_ID)

    -- spawn npc
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_DUNGEON_SPAWN_NPC, self, self.SpawnNpc)
    -- 跳过
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_SKIP_DUNGEON, self, self.Skip)
    -- 处理npc死亡
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    -- 与指引交互
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_STEP_END, self, self.GuideStepEnd)
    -- 进入trigger
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, self.OnActorEnterTrigger)

    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_TUTORIAL_START)
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 1)
end

-- 进入trigger
function TutorialShip1BattleStep:OnActorEnterTrigger(tbGameTrigger, tbGameObject)
    -- npc进入trigger不处理
    if tbGameObject.ObjectType == GameObjectTypeDef.Npc then return end
    -- 删除trigger
    RemoveAllTrigger(self)
    -- 修改副本目标
    SendObjectiveInfo(DUNGEON_OBJECTIVE_ID_90013)

    -- 数据埋点
    nEnterTriggerTime = GlobalVariableSystem:GetLocalTime()
    TutorialStep:SendDungeonCompleteStep(TutorialStep.STEP_ENTER_TRIGGER_2,  nEnterTriggerTime - nStartTime)
    
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 9)
end

-- 指引与新手副本交互
function TutorialShip1BattleStep:GuideStepEnd(nStep)
    -- 暂停npc
    if nStep == nGuideStep_4 then 
        AllNpcPaused(true)
    end

    -- 开启npc
    if nStep == nGuideStep_5 then 
        AllNpcPaused(false)
    end

    -- 敌船是否技能1
    if nStep == nGuideStep_6 then 
        AllNpcPaused(false)
        self:CastSkill1()
    end

    -- 玩家朝向敌船
    -- if nStep == nGuideStep_8 then 
    --     --local PlayerSelf = GamePlayerSelfHelper:Get()
    --     if tbEnemyObject then
    --         local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    --         CameraControlManager.CurrentActiveModeComponent:LookForActor(tbEnemyObject.pUEActor)
    --     end
    -- end
end

-- 释放技能1
function TutorialShip1BattleStep:CastSkill1()
    if not tbEnemyObject then return end

    -- 设置可以释放技能
    if tbEnemyObject.BuffComponentServer then
        tbEnemyObject.BuffComponentServer:RemoveBuffById(NO_SKILL_BUFFER_ID)
    end
    
    -- 由于ai的延迟查找，所以允许失败，采用延迟释放技能的方式解决
    local ret = tbEnemyObject.SkillComponentServer:RequestCastSkill(ENEMY_SKILL_1)

    if not ret then
        nCastSkill1Count = nCastSkill1Count + 1
        if nCastSkill1Count <= CAST_SKILL_1_MAX then
            tbTimerHelper:NewTimerMethod(self, self.CastSkill1, SKILL_SECOND_1, false)
            return
        end
    end

    -- 船只默认1档
    -- HandlerManagerHelper.SetNavStateDispatcher:call(1)
    -- 伴随对话
    NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500117)
    -- 副本目标
    SendObjectiveInfo(DUNGEON_OBJECTIVE_ID_90012)

    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 2)

    -- 指定时间后，释放技能2
    tbTimerHelper:NewTimerMethod(self, self.CastSkill2, SKILL_SECOND_2, false)
end

-- 释放技能2
function TutorialShip1BattleStep:CastSkill2()
    if not tbEnemyObject then return end
    -- 释放技能2
    tbEnemyObject.SkillComponentServer:RequestCastSkill(ENEMY_SKILL_2)
    -- 伴随对话
    NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500118)

    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 3)
    -- 指定时间后，释放技能3
    tbTimerHelper:NewTimerMethod(self, self.CastSkill3, SKILL_SECOND_3, false)
end

--释放技能3
function TutorialShip1BattleStep:CastSkill3()
    if not tbEnemyObject then return end
    --释放技能3
    tbEnemyObject.SkillComponentServer:RequestCastSkill(ENEMY_SKILL_3)
    -- 伴随对话
    NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500119)
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 4)
    -- 指定时间后，普通攻击
    tbTimerHelper:NewTimerMethod(self, self.CastGeneralAttack, GENERAL_ATTACK_SECOND, false)
end

-- 普遍攻击
function TutorialShip1BattleStep:CastGeneralAttack()
    if not tbEnemyObject then return end
    -- 允许普通攻击
    if tbEnemyObject.BuffComponentServer then
        tbEnemyObject.BuffComponentServer:RemoveBuffById(NO_ATTACK_BUFFER_ID)
    end
    -- 第一次普攻
    if not bGuideStep5 then 
        bGuideStep5 = true
        
        -- 副本目标
        SendObjectiveInfo(DUNGEON_OBJECTIVE_ID_90017)
        -- 创建trigger
        CreateTrigger(self)
        BattleTargetTrackHelper:SetTargetTrackVisible(nil, true)
        -- 玩家朝向trigger
        --local PlayerSelf = GamePlayerSelfHelper:Get()
        --if tbTriggerObjective then
            --local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            --CameraControlManager.CurrentActiveModeComponent:LookForActor(tbTriggerObjective.pUEActor)
        --end

        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 5)
    else 
        -- 只要不是在暂停状态，显示伴随对话
        if bShowDialogFlag then
            NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500120)
        end
    end 

    -- 在指定时间后，显示伴随对话
    tbTimerHelper:NewTimerMethod(self, self.GeneralAttackDialog1, ATTACK_DIALOG_SECOND_1, false)
    tbTimerHelper:NewTimerMethod(self, self.GeneralAttackDialog2, ATTACK_DIALOG_SECOND_2, false)
    -- 在指定时间后，播放技能4
    tbTimerHelper:NewTimerMethod(self, self.CastSkill4, SKILL_SECOND_4, false)
end

-- 普遍攻击时候，播放伴随对话
function TutorialShip1BattleStep:GeneralAttackDialog1()
    if bShowDialogFlag then
        NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500121)
    end 
end

-- 普遍攻击时候，播放伴随对话
function TutorialShip1BattleStep:GeneralAttackDialog2()
    if bShowDialogFlag then
        NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500122)
    end
end

-- 释放技能4
function TutorialShip1BattleStep:CastSkill4()
    if not tbEnemyObject then return end
    -- 敌船禁止普通攻击
    if tbEnemyObject.BuffComponentServer then
        tbEnemyObject.BuffComponentServer:AddBuffById(NO_ATTACK_BUFFER_ID)
    end
    -- 敌船释放技能4
    tbEnemyObject.SkillComponentServer:RequestCastSkill(ENEMY_SKILL_4)
    -- 第一次释放要有伴随对话
    if nCastSkill4Count == 0 then 
        if bShowDialogFlag then
            NpcDialogBoardHelper:OpenDialogBoard(Dialog_ID_500123)
        end
    end
    
    nCastSkill4Count = nCastSkill4Count + 1

    -- 连续释放3次技能4，然后继续普通攻击
    if nCastSkill4Count ==  CAST_SKILL_4_MAX then
        nCastSkill4Count = 0
        tbTimerHelper:NewTimerMethod(self, self.CastGeneralAttack, GENERAL_ATTACK_SECOND, false)
    else 
        tbTimerHelper:NewTimerMethod(self, self.CastSkill4, SKILL_SECOND_4_CD, false)
    end
end

-- spawn npc,并设置初始状态
function TutorialShip1BattleStep:SpawnNpc()
    -- 刷新敌船
    CreateEnemyShip(self)
    -- 刷新jack
    CreateJack(self)
    -- 将jack赋值给章鱼战斗模块
    SetJack(self)
    -- 敌船、jack设置初始buffer
    AddBuffer(self)
    -- 敌船强制攻击玩家
    local player = GamePlayerSelfHelper:Get()
    tbEnemyObject.BattleAIComponent:SetForcedTargetToAttack(player)
    -- 所有npc和玩家暂停
    AllNpcPaused(true)
end

function TutorialShip1BattleStep:Skip()
    TutorialStep.STEP_IS_SKIP = true

    if tbTimerHelper ~= nil then 
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end 

    -- 清掉所有npc和trigger
    RemoveAllNpcAndTrigger()

    tbEnemyObject = nil

    BattleTargetTrackHelper:SetTargetTrackVisible(nil, false)

    TutorialShip1BattleStep.super.Complete(self)
end

-- 敌船死亡处理
function TutorialShip1BattleStep:OnPawnDead(tbDeadObject)
    if not tbTimerHelper then 
        tbTimerHelper = SelfTimerHelper()
    end
    tbTimerHelper:NewTimerMethod(self, self.Complete, ENEMY_SHIP_SINK_SECOND, false)
    -- 直接删除沉船
    -- GameObjectSystem:DestroyNpcInGameMode(tbEnemyObject:GetUEActorUniqueId())
    tbEnemyObject = nil
end

function TutorialShip1BattleStep:Complete()
    if tbTimerHelper ~= nil then 
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end

    -- 删除trigger
    RemoveAllTrigger(self)
    TutorialShip1BattleStep.super.Complete(self)
    -- 玩家初速度设为1档
    -- HandlerManagerHelper.SetNavStateDispatcher:call(1)

    -- 数据埋点 考虑到没有进入trigger前打死敌船的情况
    local nPreTime = nEnterTriggerTime
    if nPreTime == 0 then nPreTime = nStartTime end
    TutorialStep:SendDungeonCompleteStep(TutorialStep.STEP_ENEMY_SHIP_DIE_3, GlobalVariableSystem:GetLocalTime() - nPreTime)
    
    -- 所有npc暂停
    AllNpcPaused(true)
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, 6)

end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function TutorialShip1BattleStep:SnapshotToReplicatedProperty()
    return true
end

-- 强制退出，要清空timer
function TutorialShip1BattleStep:UnregisterEvent()
    if tbTimerHelper ~= nil then 
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end 
    TutorialShip1BattleStep.super.UnregisterEvent(self)
end

return TutorialShip1BattleStep