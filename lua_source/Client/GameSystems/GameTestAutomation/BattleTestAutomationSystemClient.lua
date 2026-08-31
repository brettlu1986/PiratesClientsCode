-----------------------------------------------------
--File Name    : BattleTestAutomationSystemClient.lua
--Author       : WuJizhou
--Create Time  : 7/26/2019, 6:16:57 PM
--Description  : BattleTestAutomationSystemClient
-----------------------------------------------------


local Timer                         = require("Timer")
local GPerfPSOSystem                = require("GPerfPSOSystem")
local ClientEventDef                = require("ClientEventDef")
local SelfEventHelper               = require("SelfEventHelper")
local DungeonDataTable              = require("DungeonDataTable")
local AutoBattleSystem              = require("AutoBattleSystem")
local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local GameTestAutomationMiscDefine  = require("GameTestAutomationMiscDefine")
local GameTestAutomationLogHelper   = require("GameTestAutomationLogHelper")
local GameTestAutomationVariables   = require("GameTestAutomationVariables")
local AutomationBattleDataHelper    = require("GameTestAutomationBattleDataHelper")

local GlobalVariableSystem          = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem          = dynamic_require("BattleGameModeSystem")
local BattleTemplateActorSystem     = dynamic_require("BattleTemplateActorSystem")


local BattleTestAutomationSystemClient = {}

local AutomationTestState = GameTestAutomationMiscDefine.AutomationTestState

local EventHelper = nil
local Signature = U4LDelegateProxy.Fire

local START_NEXT_BATTLE_TIMER = "START_NEXT_BATTLE_TIMER"

BattleTestAutomationSystemClient.OnAutomationTestBeginPlay = nil
BattleTestAutomationSystemClient.OnAutomationTestEndPlay = nil
BattleTestAutomationSystemClient.OnAutomationTestPausePlay = nil
BattleTestAutomationSystemClient.OnAutomationTestResumePlay = nil

BattleTestAutomationSystemClient.OnAutomationTestBeginPlayDelegate = nil
BattleTestAutomationSystemClient.OnAutomationTestEndPlayDelegate = nil
BattleTestAutomationSystemClient.OnAutomationTestPausePlayDelegate = nil
BattleTestAutomationSystemClient.OnAutomationTestResumePlayDelegate = nil


local nCurrentState = AutomationTestState.Idle

local bInit = false

local function UploadPSO()
    GPerfPSOSystem:Upload()
end

-- local function StartGPerf()
--     GPerfSystem:Start()
-- end

-- local function StopGperfAndUpload()
--     GPerfSystem:Stop()
--     GPerfSystem:Upload()
-- end

local function IsEnable()
    -- return true
    return GameTestAutomationVariables.bBattleTestEnable
end

local function RegisterOnStartDelegate(self)
    self.OnAutomationTestBeginPlay = function()
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, OnAutomationTestBeginPlay()")
        self:StartBattleAutoTest()
    end
    self.OnAutomationTestBeginPlayDelegate = createDelegate(Signature, self.OnAutomationTestBeginPlay, "BattleTestAutomationSystemClient.OnAutomationTestBeginPlay")
    GameTestAutomationDelegate.SetBattleAutomationTestBeginPlayDelegate(self.OnAutomationTestBeginPlayDelegate)
end

local function RegisterOnStopDelegate(self)
    self.OnAutomationTestEndPlay = function()
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, OnAutomationTestEndPlay()")
        self:StopBattleAutoTest()
    end
    self.OnAutomationTestEndPlayDelegate = createDelegate(Signature, self.OnAutomationTestEndPlay, "BattleTestAutomationSystemClient.OnAutomationTestEndPlay")
    GameTestAutomationDelegate.SetBattleAutomationTestEndPlayDelegate(self.OnAutomationTestEndPlayDelegate)
end

local function RegisterOnResumeDelegate(self)
    self.OnAutomationTestResumePlay = function()
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, OnAutomationTestResumePlay()")
        self:ResumeBattleAutoTest()
    end
    self.OnAutomationTestResumePlayDelegate = createDelegate(Signature, self.OnAutomationTestResumePlay, "BattleTestAutomationSystemClient.OnAutomationTestResumePlay")
    GameTestAutomationDelegate.SetBattleAutomationTestResumePlayDelegate(self.OnAutomationTestResumePlayDelegate)
end

local function RegisterOnPauseDelegate(self)
    self.OnAutomationTestPausePlay = function()
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, OnAutomationTestPausePlay()")
        self:PauseBattleAutoTest()
    end
    self.OnAutomationTestPausePlayDelegate = createDelegate(Signature, self.OnAutomationTestPausePlay, "BattleTestAutomationSystemClient.OnAutomationTestPausePlay")
    GameTestAutomationDelegate.SetBattleAutomationTestPausePlayDelegate(self.OnAutomationTestPausePlayDelegate)
end

local function RegisterCppDelegates(self)
    RegisterOnStartDelegate(self)
    RegisterOnStopDelegate(self)
    RegisterOnResumeDelegate(self)
    RegisterOnPauseDelegate(self)
end

local function UnregisterCppDelegates(self)
    self.OnAutomationTestBeginPlay = nil
    self.OnAutomationTestEndPlay = nil
    self.OnAutomationTestPausePlay = nil
    self.OnAutomationTestResumePlay = nil

    self.OnAutomationTestBeginPlayDelegate = nil
    self.OnAutomationTestEndPlayDelegate = nil
    self.OnAutomationTestPausePlayDelegate = nil
    self.OnAutomationTestResumePlayDelegate = nil
end


local function OnFFAFinished(self)
    if IsEnable() then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "testbattle stop", nil)
        BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
    end
end

-- local function OnChickenChicken(self, tbPacket)
--     if IsEnable() and tbPacket.bTeamDead and tbPacket.nTeamRank == 1 then
--         KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "testbattle stop", nil)
--     end
-- end

-- local function OnPawnDead(self, tbDeadActor)
--     if IsEnable() and tbDeadActor and tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
--         KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "testbattle stop", nil)
--     end
-- end

local function OnPlayerSelfReady(self)
    if IsEnable() then
        local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
        if bIsInDungeon then
            ClientShell.GetClient(GWorld):SetPlayerPawn(GamePlayerSelfHelper:GetUEActor());
            local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            CameraManager:SetForceUpdateClientCamera(true, GamePlayerSelfHelper:GetUEActor())
        end
    end
end

local function OnParachutionEnd(self)
    if IsEnable() then
        local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
        if bIsInDungeon then
            ClientShell.GetClient(GWorld):SetPlayerPawn(GamePlayerSelfHelper:GetUEActor());
            local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            CameraManager:SetForceUpdateClientCamera(true, GamePlayerSelfHelper:GetUEActor())
            local nSceneId = BattleGameModeSystem.nDungeonId
            local tbTemplate = DungeonDataTable:GetTemplate(nSceneId)
            local bResult = tbTemplate ~= nil
            if bResult and nCurrentState == AutomationTestState.Idle then
                KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "testbattle start", nil)
            end
        end
    end
end

function BattleTestAutomationSystemClient:CheckAutoBattle()
    return GameTestAutomationVariables.bBattleTestEnable
end

function BattleTestAutomationSystemClient:RequestToStartBattle()
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm test-start-matchmaking test-automation 100011 1 false autotest", nil)
end


function BattleTestAutomationSystemClient:StartBattleAutoTest()
    if nCurrentState == AutomationTestState.Idle then
        AutoBattleSystem:Register(self)
        ClientShell.GetClient(GWorld):BindOnCollectingWCOriginDelegate();
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, StartBattleAutoTest()")
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 0", nil)  --设置加载场景是根据相机而不是pawn @jingzhao
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        local nShipTemplateId = AutomationBattleDataHelper:GetThisBattleShipTemplateId()
        local szCmd = "dm battletestautomation start"
        if nShipTemplateId then
            szCmd = szCmd .. " ".. nShipTemplateId
        end
        local nWeaponTemplateId = AutomationBattleDataHelper:GetThisBattleShipWeaponTemplateId()
        if nWeaponTemplateId then
            szCmd = szCmd .. " ".. nWeaponTemplateId
        end
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCmd, nil)
        BattleTemplateActorSystem:SetWatchedTarget(tbPlayerSelf, tbPlayerSelf)
        ClientShell.GetClient(GWorld):SetPlayerPawn(GamePlayerSelfHelper:GetUEActor());
        nCurrentState = AutomationTestState.Running
        if tbPlayerSelf:IsHuman() then
            tbPlayerSelf.pUEActor.PlayerInputComponent.MoveEnabled = false
        end
        local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        CameraManager:SetForceUpdateClientCamera(true, tbPlayerSelf.pUEActor)
    end
end

function BattleTestAutomationSystemClient:StopBattleAutoTest()
    if nCurrentState ~= AutomationTestState.Idle then
        AutoBattleSystem:Unregister(self)
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, StopBattleAutoTest()")
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm battletestautomation stop", nil)
        nCurrentState = AutomationTestState.Idle
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf:IsHuman() then
            tbPlayerSelf.pUEActor.PlayerInputComponent.MoveEnabled = true
        end
        local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        CameraManager:SetForceUpdateClientCamera(false, nil)

        if GameTestAutomationVariables.bUsePSO then
            UploadPSO()
        end
    end
end

function BattleTestAutomationSystemClient:PauseBattleAutoTest()
    if nCurrentState == AutomationTestState.Running then
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, PauseBattleAutoTest()")
        nCurrentState = AutomationTestState.Pausing
    end
end

function BattleTestAutomationSystemClient:ResumeBattleAutoTest()
    if nCurrentState == AutomationTestState.Pausing then
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, ResumeBattleAutoTest()")
        nCurrentState = AutomationTestState.Running
    end
end



function BattleTestAutomationSystemClient:Init()
    if not bInit then
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, Init()")
        nCurrentState = AutomationTestState.Idle
        RegisterCppDelegates(self)
        EventHelper = SelfEventHelper()
        EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
        EventHelper:RegisterEvent(ClientEventDef.EV_NOTIFY_BATTLE_FINISHED, self, OnFFAFinished)
        EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
        bInit = true
    end
end

function BattleTestAutomationSystemClient:Uninit()
    if bInit then
        nCurrentState = AutomationTestState.Idle
        GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemClient, Uninit()")
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "testbattle stop", nil)
        UnregisterCppDelegates(self)
        EventHelper:UnregisterAll()
        EventHelper = nil
        Timer.StopOwnerTimer(self, START_NEXT_BATTLE_TIMER)
        bInit = false
    end
end




return BattleTestAutomationSystemClient