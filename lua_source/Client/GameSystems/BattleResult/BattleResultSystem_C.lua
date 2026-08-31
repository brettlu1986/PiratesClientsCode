local luaclass = require("luaclass")
local BattleResultSystem = require("BattleResultSystem")
local BattleResultSystem_C = luaclass("BattleResultSystem_C", BattleResultSystem)

local UIManager = require("UIManager")
local ClientEventDef = require ("ClientEventDef")
local UIStateDef = require("UIStateDef")
local SelfTimerHelper = require("SelfTimerHelper")
local UIDef = require("UIDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UEActorHelper = require("UEActorHelper")
local WidgetConfig = require("WidgetDataTable")
local TeamHeadNameSystem = require("TeamHeadNameSystem")
local SelfAnimationHelper = require("SelfAnimationHelper")
local DelayTimer = require("DelayTimer")
local BattleResultAvatarPositionDataTable = require("BattleResultAvatarPositionDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local ResourceManager = require("ResourceManager")
local ProtoDC = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local BattleResultIni = require("BattleResultIni")
local BattleResultDef = require("BattleResultDef")
local SoundManager = require("SoundManager")
local CameraGameHelper = require("CameraGameHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
--local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanVehicleHelper = require("HumanVehicleHelper")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local BattleSkySystem = dynamic_require("BattleSkySystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local LobbyHumanFashion3DOperator = require("LobbyHumanFashion3DOperator")
local TutorialDungeonIni = require("TutorialDungeonIni")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ProcedureTool = require("ProcedureTool")

BattleResultSystem_C.bWaitEvent = true
BattleResultSystem_C.pLevelLoadedDelegate = nil
BattleResultSystem_C.tbSortTeamMemberDatas = nil
BattleResultSystem_C.pSubLevel = nil
BattleResultSystem_C.bHasKilledBoss = false
BattleResultSystem_C.tbSuccessDelayHandle = nil
BattleResultSystem_C.tbOpenResultDelayHandle = nil
BattleResultSystem_C.tbDeadPlaybackData = nil
BattleResultSystem_C.RenderParams = nil
BattleResultSystem_C.tbHuman3DOperator = nil

local MODE_SINGLE_PLAYER = 1 --单人模式

local SHIP_WIN_EFFECT_BP_CLASS = "Class'/Game/Resources/FFA/Effects/BluePrints/BP_FX_Scale_VictoryShip_01.BP_FX_Scale_VictoryShip_01_C'"
local HUMAN_WIN_EFFECT_BP_CLASS = "Class'/Game/Resources/FFA/Effects/BluePrints/BP_FX_VictoryRole_01.BP_FX_VictoryRole_01_C'"
local SCENE_LEVEL = '/Game/Resources/FFA/Maps/MatchResult/Map_FFA_Battleresult'--'/Game/UI/FFA/Map/Map_FFA_Battleresult'
local CAMERA_TAG = "CameraResult"
local MVP_OFFSET = Vector{X = 0, Y = 0, Z = 190} --210
local SHIP_EFFECT_SCALE = 15

local TAG_FRONT_LEFT_CENTER = "HumanFrontLeftCenter"       --前排中间偏左
local TAG_FRONT_CENTER = "HumanFrontCenter"                --前排居中
local TAG_BACK_LEFT_MOST = "HumanBackLeftMost"             --后排最左
local TAG_BACK_LEFT_CENTER = "HumanBackLeftCenter"         --后排中间偏左
local TAG_BACK_RIGHT_CENTER = "HumanBackRightCenter"       --后排中间偏右
local TAG_BACK_RIGHT_CENTER2 = "HumanBackRightCenter2"     --后排中间偏右2
local TAG_BACK_RIGHT_MOST = "HumanBackRightMost"           --后排最右
local WIN_SOUND_EFFECT_ID = 900039                         --胜利音效

--tag对应的位置索引
local TAG_POS_INDEX =
{
    [TAG_FRONT_LEFT_CENTER] = 1,
    [TAG_FRONT_CENTER] = 2,
    [TAG_BACK_LEFT_MOST] = 3,
    [TAG_BACK_LEFT_CENTER] = 4,
    [TAG_BACK_RIGHT_CENTER] = 5,
    [TAG_BACK_RIGHT_CENTER2] = 6,
    [TAG_BACK_RIGHT_MOST] = 7,
}

--队友从左到右的排序序号
local SORT_INDEX =
{
    [TAG_BACK_LEFT_MOST] = 1,
    [TAG_BACK_LEFT_CENTER] = 2,
    [TAG_FRONT_LEFT_CENTER] = 3,
    [TAG_FRONT_CENTER] = 4,
    [TAG_BACK_RIGHT_CENTER] = 5,
    [TAG_BACK_RIGHT_CENTER2] = 6,
    [TAG_BACK_RIGHT_MOST] = 7,
}

local SELF_POS_TAG =
{
    [1] = TAG_FRONT_CENTER,
    [2] = TAG_FRONT_LEFT_CENTER,
    [3] = TAG_FRONT_CENTER,
    [4] = TAG_FRONT_LEFT_CENTER,
}

local OTHER_MEMBER_POS_TAG =
{
    [2] = {TAG_BACK_RIGHT_CENTER},
    [3] = {TAG_BACK_LEFT_MOST, TAG_BACK_RIGHT_MOST},
    [4] = {TAG_BACK_LEFT_MOST, TAG_BACK_RIGHT_CENTER,TAG_BACK_RIGHT_MOST},
}

local RENDER_PARAMS_TAG = "RPOW"

BattleResultSystem_C.nResult = nil
BattleResultSystem_C.nLoadResourceAsyncHandler = nil

local function GetSelfResultData(self)
    return self:GetPlayerResultData(GamePlayerSelfHelper:Get().nServerInstanceId)
end


local function UnloadSublevel(self)
    if self.nLoadResourceAsyncHandler then
        ResourceManager:CancelLoadAsync(self.nLoadResourceAsyncHandler)
        self.nLoadResourceAsyncHandler = nil
    end
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end


local function CreateSinglePlayer(self, nAvatarId, tbAppearanceIds,  tbFashionIds, szPosActorTag, bMVP)
    log("CreateSinglePlayer:nAvatarId, nFashionId, szPosActorTag=",nAvatarId, tbFashionIds, szPosActorTag)
    local pPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pSubLevel, szPosActorTag)
    local location = pPosActor:K2_GetActorLocation()
    local rotation = pPosActor:K2_GetActorRotation()
    local szAnimKey = BattleResultAvatarPositionDataTable:GetShowAnimation(nAvatarId, TAG_POS_INDEX[szPosActorTag])

    local Human3DOperator = LobbyHumanFashion3DOperator()
    Human3DOperator:SetActorLocation(location)
    Human3DOperator:SetActorRotator(rotation)
    Human3DOperator:SetAnimation(szAnimKey)
    local pHuman = Human3DOperator:DisplayWithAppearanceData(nAvatarId, tbFashionIds, tbAppearanceIds)

    local tbHuman3DOperator = self.tbHuman3DOperator
    if not tbHuman3DOperator then
        tbHuman3DOperator = {}
        self.tbHuman3DOperator = tbHuman3DOperator
    end
    table.insert(tbHuman3DOperator, Human3DOperator)

    --MVP
    if bMVP then
        local tbTemplate = WidgetConfig:GetTemplate(UIDef.UW_MVP)
        local pWidgetRef = UIManager:CreateUMG(tbTemplate.szUIPath)
        local pWidgetComponent = pHuman.HeadInfo
        if not pWidgetComponent then
            error('CreateSinglePlayer CreateWidget failed, WidgetComponent is nil. nAvatarId ' .. nAvatarId)
        end
        pWidgetComponent:K2_AttachToComponent(pHuman.Mesh, "root01", EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
        pWidgetComponent:K2_SetRelativeLocation(MVP_OFFSET)
        pWidgetComponent:SetWidget(pWidgetRef)
        pWidgetComponent.Space = EWidgetSpace.Screen
    end
end

local function CreatePlayers(self)
    local tbResultData = GetSelfResultData(self)
    local nMode = tbResultData.nMode
    local tbTeamMemberData = tbResultData.tbTeamPlayerStaticsData
    local nSelfInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nPlayerCount = #tbTeamMemberData
    local nOtherMemberIndex = 1
    local nMVPInstanceId = tbResultData.nMVPInstanceId
    local tbTeamMemberDataSortMap = {}
    local tbTeamMemberPosSortIndex = {}
    for k, v in ipairs(tbTeamMemberData) do
        local szPosActorTag = nil
        local bMVP = nMode ~= MODE_SINGLE_PLAYER and v.nInstanceId == nMVPInstanceId and tbResultData.bTeamDead
        if nSelfInstanceId == v.nInstanceId then
            --自己
            szPosActorTag = SELF_POS_TAG[nPlayerCount]
        elseif nPlayerCount > 1 then
            --队友
            szPosActorTag = OTHER_MEMBER_POS_TAG[nPlayerCount][nOtherMemberIndex]
            nOtherMemberIndex = nOtherMemberIndex + 1
        end
        if szPosActorTag then
            CreateSinglePlayer(self, v.nAvatarId, v.appearances, v.nFashionId, szPosActorTag, bMVP)
            local nSortIndex = SORT_INDEX[szPosActorTag]
            tbTeamMemberDataSortMap[nSortIndex] = v
            table.insert(tbTeamMemberPosSortIndex, nSortIndex)
        else
            logerror("BattleResultSystem_C:CreatePlayers, szPosActorTag is nil,",v.nInstanceId, v.name)
        end
        local tbGameObject = GameObjectSystem:FindByInstanceId(v.nInstanceId)
        if tbGameObject and tbGameObject.pUEActor and tbGameObject.pUEActor.CharacterMovement then
            tbGameObject.pUEActor.CharacterMovement:SetComponentTickEnabled(false)
        end
    end
    --按照队友人物模型从左到右排序
    table.sort(tbTeamMemberPosSortIndex)
    for k, v in ipairs(tbTeamMemberPosSortIndex) do
        table.insert(self.tbSortTeamMemberDatas, tbTeamMemberDataSortMap[v])
    end
end

local function PlayWinAnimAndEffect(self)
    local tbSelfObj = GamePlayerSelfHelper:Get()
    if tbSelfObj:IsDead() then
        local tbViewerObj = TeamWatchClientHelper.GetCurrentWatchPlayer()
        if tbViewerObj then
            tbSelfObj = tbViewerObj
        end
    end
    tbSelfObj:StopMove(true)
    local szPawnClassName = nil
    local nScale = 1
    if tbSelfObj:IsHuman() then
        --清载具
        local GameVehicleComponent = tbSelfObj.GameVehicleComponent
        if GameVehicleComponent then
            if GameVehicleComponent:GetVehicleState() == HumanVehicleStateDef.AttachToVehicle then
                HumanVehicleHelper.ClearVehicle(tbSelfObj, true)
            end
        end
         --收武器
         local HumanWeaponComponent = tbSelfObj.HumanWeaponComponent
         local StateHelper = HumanWeaponComponent.StateHelper
         HumanWeaponHelper.SendSetCurrentWeaponRequest(0)
         HumanWeaponComponent:CancelAttack()
         StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDED, true)

        local pUEActor = tbSelfObj.pUEActor
        local pPlayerInputComponent = pUEActor.PlayerInputComponent
        if pPlayerInputComponent then
            pPlayerInputComponent:StopMoveImmediately()
        end
        szPawnClassName = HUMAN_WIN_EFFECT_BP_CLASS
        SelfAnimationHelper:PlayHumanAnimation(tbSelfObj, SelfAnimationHelper.AnimDef.BATTLE_VICTORY)
    elseif tbSelfObj:IsShip() then

        szPawnClassName = SHIP_WIN_EFFECT_BP_CLASS
        nScale = SHIP_EFFECT_SCALE
    end


    CameraGameHelper.RotateToTargetFront(tbSelfObj)

    local plocation = tbSelfObj:GetLocation()
    if szPawnClassName and szPawnClassName ~= "" then
        UEActorHelper:CreateActor(szPawnClassName, plocation, nil, Vector{X = nScale,Y = nScale,Z = nScale})
    end
end

local function CheckDelayOpenResult(self, nDelayTime)
    local function DelayFunc()
        self.tbOpenResultDelayHandle = nil
        if IsTutorialDungeon() then
            ProcedureTool:EnterCreateRole({bNeedLoadMap = true})
        else
            local tbParams = {}
            local tbResultData = GetSelfResultData(self)
            tbParams.tbTeamInfo = tbResultData
            tbParams.tbTeamMemberData = tbResultData.tbTeamPlayerStaticsData
            UIManager:PushState(UIStateDef.StateName.UI_FFA_RESULT_STATE, tbParams, true, true)
        end
    end
    if nDelayTime and nDelayTime > 0 then
        if not self.tbOpenResultDelayHandle then
            self.tbOpenResultDelayHandle = DelayTimer:DelayRun(DelayFunc, nDelayTime)
        end
    else
        DelayFunc()
    end
end

local function OpenBattleResult(self, nResult, bImmadiately)
    local ActiveUIState = UIManager:GetActiveState()
    if ActiveUIState and ActiveUIState.szName == UIStateDef.StateName.UI_FFA_RESULT_STATE then
        return
    end

    self.nResult = nResult
    self.bWaitEvent = false
    local nDelayTime = nil
    local WinFinishedCallback = function()
        if not bImmadiately then
            nDelayTime = BattleResultIni.tbBattleResult.nWinDelay
        end
        PlayWinAnimAndEffect(self)
        CheckDelayOpenResult(self, nDelayTime)
    end
    if nResult == BattleResultDef.WIN then
        local tbParam = {}
        tbParam.FinishCallback = WinFinishedCallback
        SoundManager:PlaySoundEffect(WIN_SOUND_EFFECT_ID)
        UIManager:OpenWnd(UIDef.UI_BATTLE_WIN_PROMPT, tbParam)
        self.EventHelper:FireEvent(ClientEventDef.EV_CHECK_WIN_AIM_CAMERA)
    elseif nResult == BattleResultDef.LOSE then
        if not bImmadiately then
            nDelayTime = BattleResultIni.tbBattleResult.nLoseDelay
        end
        CheckDelayOpenResult(self, nDelayTime)
    end
end

local function OpenBattleStatistics(self)
    UIManager:CloseWnd(UIDef.UI_FFA_BATTLE_RESULT)
    local tbParams = {}
    local tbResultData = GetSelfResultData(self)
    tbParams.tbTeamInfo = tbResultData
    tbParams.tbSortTeamMemberData = self.tbSortTeamMemberDatas
    UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_STATISTICS, tbParams)
end

local function OnFFAResult(self, tbPacket)
    if not self.bWaitEvent then
        return
    end
    local bFirstReceive = true
    local tbResultData = GetSelfResultData(self)
    if tbResultData and next(tbResultData) then
        bFirstReceive = false
    end
    --存数据
    tbResultData = self:CreatePlayerResultData(GamePlayerSelfHelper:Get())
    for k, v in pairs(tbPacket) do
        tbResultData[k] = v
    end
    tbResultData.tbTeamPlayerStaticsData = tbPacket.FFATeamResult
    tbResultData.bKillBoss = self.bHasKilledBoss

    if tbPacket.nPlayerCount > 1 and tbPacket.bTeamDead and tbPacket.nTeamRank == 1 then
        --吃鸡直接弹结算 其它死亡情况都是等待相机动画结束
        OpenBattleResult(self, BattleResultDef.WIN)
    elseif not bFirstReceive then
        OpenBattleResult(self, BattleResultDef.LOSE, true)
    end
end

--击杀boss直接弹进入结算
local function OnFFAKillBossResult(self, tbPacket)
    self.bHasKilledBoss = false
    local tbResultData = self:CreatePlayerResultData(GamePlayerSelfHelper:Get())
    for k, v in pairs(tbPacket) do
        tbResultData[k] = v
    end
    tbResultData.tbTeamPlayerStaticsData = tbPacket.FFATeamResult
    tbResultData.bKillBoss = self.bHasKilledBoss
    if tbResultData.bTeamDead then
        OpenBattleResult(self, BattleResultDef.WIN)
    else
        local tbParams = {}
        tbParams.bAdditionSuccess = true
        UIManager:OpenWnd(UIDef.UI_WATCHBATTLE_RESULT,tbParams)
    end
end

local function PostLoadMap(self)
    if self.pLevelLoadedDelegate then
        self.EventHelper:UnregisterCppDelegate(self.pLevelLoadedDelegate)
        self.pLevelLoadedDelegate = nil
    end
    --设置环境光照
    local envControl = ExtendBlueprintFunctions.GetLevelActorByTag(self.pSubLevel, "EnvControlResult")
    if envControl then
        envControl:SetEnvironment()
    end
    
    --结算统计界面强制设置成9点的天空
    BattleSkySystem:ForceSetClientFixSkyTime(9, 0)

    --显示队友人物模型
    CreatePlayers(self)
    --重设相机
    local CameraActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pSubLevel, CAMERA_TAG)
    if CameraActor then
        local pController = GameplayStatics.GetPlayerController(GWorld, 0)
        pController:SetViewTargetWithBlend(CameraActor, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
    end
    --Render Params
    self.RenderParams = ExtendBlueprintFunctions.GetLevelActorByTag(self.pSubLevel, RENDER_PARAMS_TAG)
    self.RenderParams:Apply()
    --隐藏队友名字片
    TeamHeadNameSystem:HideAll()
    local tbAllOther = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerOther)
    for tbObject, _ in pairs(tbAllOther) do
        if isvalidhandle(tbObject.pUEActor) then
            if tbObject:IsHuman() then
                tbObject.pUEActor:HideHumanBotName()
            else
                tbObject.pUEActor:HideShipBotName()
            end
        end
    end
    --显示统计ui
    OpenBattleStatistics(self)
end

local function CreateSubLevel(self)
    self.pLevelLoadedDelegate = self.EventHelper:RegisterCppDelegate(ClientShell.GetClient(GWorld).OnSubLevelLoadEnd, self, PostLoadMap)
    --local pClientShell = ClientShell.GetClient(GWorld)
    --pClientShell:ToggleSceneRendering(true)
    LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
    --ClientShell.GetClient(GWorld):FlushAsyncLoading()
    self.nLoadResourceAsyncHandler = ResourceManager:LoadAsync(SCENE_LEVEL, function()
        UnloadSublevel(self)
        self.pSubLevel = ExtendBlueprintFunctions.LoadSubLevelDynamic(GWorld, SCENE_LEVEL, Vector(), Rotator())
        if self.pLevelLoadedDelegate then
            self.pLevelLoadedDelegate:Unbind()
            self.pLevelLoadedDelegate = nil
        end
        if self.pSubLevel then
            ExtendBlueprintFunctions.SetLevelClientOnlyVisible(self.pSubLevel, true)
            self.pLevelLoadedDelegate = self.EventHelper:RegisterCppDelegate(self.pSubLevel.OnLevelShown, self, PostLoadMap)
        end
    end)
    --SCENE_LEVEL:load()
    -- ClientShell.GetClient(GWorld):LoadStreamLevel(GWorld, SCENE_LEVEL)

end

local function OnDeadCameraOver(self)
    local tbResultData = GetSelfResultData(self)
    log("[dead result]on dead over", tbResultData == nil)
    if tbResultData then
        log("[dead result] on dead over")
        OpenBattleResult(self, BattleResultDef.LOSE)
    end
end

--进入吃鸡结算和统计
local function EnterFFAResult(self, bTeamDead)
    local tbResultData = GetSelfResultData(self)
    if tbResultData and tbResultData.bTeamDead == bTeamDead then
        if tbResultData.bTeamDead == true and tbResultData.nTeamRank == 1 then
            OpenBattleResult(self, BattleResultDef.WIN)
        else
            OpenBattleResult(self, BattleResultDef.LOSE, true)
        end
    else
        self.bWaitEvent = true
    end
end

local function OnLeaveBattle(self)
    if isvalidhandle(self.RenderParams) then
        self.RenderParams:Restore()
    end
    self.RenderParams = nil
end

function BattleResultSystem_C:Init()
    BattleResultSystem_C.super.Init(self)
    self.tbSortTeamMemberDatas = {}
    self.TimerHelper = SelfTimerHelper()

    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_RESULT, self, OnFFAResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_KILL_BOSS_RESULT, self, OnFFAKillBossResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEAD_CAMERA_OVER, self, OnDeadCameraOver)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, self, EnterFFAResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)

end

function BattleResultSystem_C:Uninit()
    BattleResultSystem_C.super.Uninit(self)
    if self.tbOpenResultDelayHandle then
        DelayTimer:ClearTimer(self.tbOpenResultDelayHandle)
        self.tbOpenResultDelayHandle = nil
    end
    local tbHuman3DOperator = self.tbHuman3DOperator
    if tbHuman3DOperator then
        for _, tbOperator in ipairs(tbHuman3DOperator) do
            tbOperator:Uninit()
        end
        self.tbHuman3DOperator = nil
    end

    UnloadSublevel(self)
    self.EventHelper:UnregisterAll()
    self.bWaitEvent = true
    self.pLevelLoadedDelegate = nil
    self.pSubLevel = nil
    self.tbDeadPlaybackData = nil
    self.nResult = nil
end

-------------------------------------


function BattleResultSystem_C:EnterFFAStatistic()
    CreateSubLevel(self)
end

--进入单机结算
--nResult:BattleResultDef.WIN,BattleResultDef.LOSE, BattleResultDef.TIE
--tbParam:其它参数
function BattleResultSystem_C:EnterStandaloneResult(nResult, tbParam)
    self:CreatePlayerResultData(GamePlayerSelfHelper:Get())
    OpenBattleResult(self, nResult)
end

function BattleResultSystem_C:RequestDeadPlayback()
    if not self.tbDeadPlaybackData then
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_FFADeathPlayback)
    end
end

function BattleResultSystem_C:SyncDeadPlaybackData(tbPlaybackData)
    self.tbDeadPlaybackData = tbPlaybackData.DeathPlaybacks
end

function BattleResultSystem_C:GetFFADeadPlaybackData()
    return self.tbDeadPlaybackData
end
--return:BattleResultDef.WIN,BattleResultDef.LOSE, BattleResultDef.TIE
function BattleResultSystem_C:GetBattleResult()
    return self.nResult
end


return BattleResultSystem_C()