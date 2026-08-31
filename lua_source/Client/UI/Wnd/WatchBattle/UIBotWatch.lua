local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBotWatch = luaclass("UIBotWatch", WndBase)
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local StringUtil = require("StringUtil")

UIBotWatch.tbLastWatchObj = nil
UIBotWatch.tbCurrrentWatchObj = nil
UIBotWatch.pbRadarMap = nil
UIBotWatch.ulWatchMateEnergy = nil
UIBotWatch.ulWatchMateWeapon = nil
UIBotWatch.pbCompass = nil
UIBotWatch.pbBuildingCostMaterials = nil
UIBotWatch.ulBattleInfo = nil
UIBotWatch.ulBotHumanArmor = nil
UIBotWatch.ulBotShipArmor = nil
UIBotWatch.ulBattleTeam = nil
UIBotWatch.ulMountainWarning = nil


local function RefreshPing(self)
    local nPing = ExtendBlueprintFunctions.GetPing(GWorld)
    self.pWidgetRef.txtPing:SetText(nPing.."ms")
    -- if nPing < 120  then
    --     self.pWidgetRef.txtPing:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    -- elseif nPing < 200  then
    --     self.pWidgetRef.txtPing:SetColorAndOpacity(UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
    -- else
    --     self.pWidgetRef.txtPing:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
    -- end
end

local function RefreshWatchBot(self, tbNewWatchObj)
    self.tbLastWatchObj = self.tbCurrrentWatchObj
    self.tbCurrrentWatchObj = tbNewWatchObj

    self.pbRadarMap:OnResetMapTarget()
    self.ulWatchMateEnergy:RefreshCurrentMateEnergy()

    local bHuman = tbNewWatchObj:IsHuman()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pBotWatchHuman:SetVisibility(bHuman and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.pBotWatchShip:SetVisibility(not bHuman and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    if bHuman then
        self.pbCurrrentVirtualStick:SetVirtualJoystickIcon(UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON)
        self.pbCurrrentVirtualStick:SetContinuousEnable(false)
        self.ulMountainWarning:Deactivate()
    else
        self.pbCurrrentVirtualStick.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        self.ulMountainWarning:Activate()
    end
end

local function DisableHumanTouchMove(self, bDisable)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf:IsHuman() and PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then
        PlayerSelf.pUEActor.PlayerInputComponent.MoveEnabled = not bDisable
    end
end

function UIBotWatch:OnLoad()
    self.tbCurrrentWatchObj = self.tbOpenArgs.tbCurrentWatchBot

    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local pbCutoutScreenAdapter = PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.nCutoutSpacerWidth = pbCutoutScreenAdapter:GetCutoutSpacerWidth()
    self.pbRadarMap = PrefabHelper:BindPrefab(pWidgetRef.pbRadarMap, UIDef.UP_RADAR_MAP)
    self.pbBotHuman = PrefabHelper:BindPrefab(pWidgetRef.pBotWatchHuman)
    self.pbBotShip = PrefabHelper:BindPrefab(pWidgetRef.pBotWatchShip)
    self.pbCompass = PrefabHelper:BindPrefab(pWidgetRef.pbCompass)
    self.pbBuildingCostMaterials = PrefabHelper:BindPrefab(pWidgetRef.pbBuildingMaterials, UIDef.UP_BOT_BUILDING_MATERIALS)
    self.pbCurrrentVirtualStick = self.PrefabHelper:BindPrefab(pWidgetRef.pbVirtualJoystick, UIDef.UP_BOT_FAKE_JOYSTICK)


    local UILogicHelper = self.UILogicHelper
    self.ulWatchMateEnergy = UILogicHelper:CreateUILogic("ULWatchBotEnergy")
    self.ulWatchMateWeapon = UILogicHelper:CreateUILogic("ULWatchBotWeapon")
    self.ulBattleInfo = UILogicHelper:CreateUILogic("ULWatchBotBattleInfo")
    self.ulBotHumanArmor = UILogicHelper:CreateUILogic("ULWatchBotHumanArmor")
    self.ulBotShipArmor = UILogicHelper:CreateUILogic("ULWatchBotShipArmor")
    self.ulBattleTeam = UILogicHelper:CreateUILogic("ULBotBattleTeam")
    self.ulBotMovement = UILogicHelper:CreateUILogic("ULBotMovement")
    self.ulMountainWarning  = UILogicHelper:CreateUILogic("ULBotMountainWarning")
    self.ulBotAIDebug  = UILogicHelper:CreateUILogic("ULBotAIDebug")

    if GlobalVariableSystem:IsStandalone() then
        self.pWidgetRef.txtPing:SetVisibility(ESlateVisibility.Collapsed)
    else
        -- 非常临时的做法，lua里不应该有这么频繁的Tick
        self.TimerHelper:NewTimerMethod(self, RefreshPing, 1, true)
        -- 设置DungeonSessionId
        local szDungeonSessionId = BattleGameModeSystem:GetShortDungeonSessionId()
        if not StringUtil.IsEmptyString(szDungeonSessionId) then
            self.pWidgetRef.txtDungeonSessionId:SetText(szDungeonSessionId)
        else
            self.pWidgetRef.txtDungeonSessionId:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    DisableHumanTouchMove(self, true)
end

function UIBotWatch:OnUnload()
    DisableHumanTouchMove(self, false)
end

local function SyncBotInfo(self, tbSyncBotInfo)
    local tbCurrentWatchBot = self.tbCurrrentWatchObj
    self.ulWatchMateWeapon:RefreshCurrentMateWeapon(tbSyncBotInfo.state)
    if tbCurrentWatchBot and tbCurrentWatchBot:IsShip() then
        if tbCurrentWatchBot.pUEActor then
            local tbShipCameraState = tbSyncBotInfo.state.camera
            tbCurrentWatchBot.pUEActor.BotPitch = tbShipCameraState.rotation.x
            tbCurrentWatchBot.pUEActor.BotYaw = tbShipCameraState.rotation.y
        end
    end
    self.pbBuildingCostMaterials:RefreshMaterials(tbSyncBotInfo.state.backpack)

    local bMsgHuman = not tbSyncBotInfo.state.state.is_ship
    if tbCurrentWatchBot:IsHuman() and bMsgHuman then
        self.pbBotHuman:RefreshHumanState(tbSyncBotInfo.state)
        self.ulBotHumanArmor:RefreshArmorSlots(tbSyncBotInfo.state)
    elseif tbCurrentWatchBot:IsShip() and not bMsgHuman then
        self.ulBotShipArmor:RefreshArmorSlots(tbSyncBotInfo.state)
    end
    self.ulBattleInfo:RefreshInfo(tbSyncBotInfo.state)
    self.pWidgetRef.txtSyncFrameNumber:SetText(tostring(tbSyncBotInfo.state.auto_increment_key))
    self.ulBotAIDebug:RefreshInfo(tbSyncBotInfo.state)
end

local function SyncBotTeam(self, tbSyncBotTeam)
    self.ulBattleTeam:RefreshAllTeamMember(tbSyncBotTeam.teammates)
end

--init ui content, OnEnter or OnShow
function UIBotWatch:OnShow()
    --self.pbRadarMap:InitWatchBattleRadar()

    local bHuman = self.tbCurrrentWatchObj:IsHuman()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pBotWatchHuman:SetVisibility(bHuman and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.pBotWatchShip:SetVisibility(not bHuman and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.txtSyncFrameNumber:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if bHuman then
        self.pbCurrrentVirtualStick:SetVirtualJoystickIcon(UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON)
        self.pbCurrrentVirtualStick:SetContinuousEnable(false)
        self.ulMountainWarning:Deactivate()
    else
        self.pbCurrrentVirtualStick.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        self.ulMountainWarning:Activate()
    end
end

function UIBotWatch:OnBindEvent(EventHelper)
    -- local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_SYNC_BOT_INFO, self, SyncBotInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_SYNC_BOT_TEAM, self, SyncBotTeam)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_BOT, self, RefreshWatchBot)

end


return UIBotWatch