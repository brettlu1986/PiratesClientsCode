local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFASelectBornPoint = luaclass("UIFFASelectBornPoint", WndBase)

---import
local UIDef = require("UIDef")
local GameWorldSystem = require("GameWorldSystem")
local WorldMapUtil = require("WorldMapUtil")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DungeonDataTable = require("DungeonDataTable")
local SceneTable = require("SceneDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TransporterDataTable = require("TransporterDataTable")
local FFADialogDataTable = require("FFADialogDataTable")
local UISetUtils = require("UISetUtils")
local SoundManager = require("SoundManager")
local UIResourceDef = require("UIResourceDef")
local ProtoDR = require("DungeonRepProtoNames")
local ParachutionSystem_C = require("ParachutionSystem_C")
local UIManager = require("UIManager")
local ParachutingNewIni = require("ParachutingNewIni")
local L10N = require("L10N")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDP = require("DungeonCommonProtoNames")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")

local DELAY_TIME = 0.5
local PLAYER_COUNT = 5
local OTHER_INDEX = 5
local ANIM_NAME = "animNoSelect"
local DEFAULT_SLIDER_VALUE = 0

UIFFASelectBornPoint.pbMap = nil
UIFFASelectBornPoint.nCurrentGrade = 1
UIFFASelectBornPoint.nCurrentSceneID = nil
UIFFASelectBornPoint.OneSecondTimer = nil
UIFFASelectBornPoint.nTime = nil
-- UIFFASelectBornPoint.tbDelayTimer = nil
UIFFASelectBornPoint.nTransporterId = 0
UIFFASelectBornPoint.tbTransporterSound = nil
UIFFASelectBornPoint.tbPBMember = nil
UIFFASelectBornPoint.pbDialog = nil
UIFFASelectBornPoint.bDialogIngoreEvent = nil

local function GetMapResData(nSceneId)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    local tbSceneTemplate = nil
    if bIsInDungeon then
        local nDungeonId = BattleGameModeSystem.nDungeonId
        tbSceneTemplate = DungeonDataTable:GetTemplate(nDungeonId)
    else
        tbSceneTemplate = SceneTable:GetTemplate(nSceneId)
    end
    local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneTemplate.nUIMapId)
    return tbMapResData
end


local nAdjustFactor = 1

local function ConvertToZoomFactor(self, nValue)
    local tbMapResData = GetMapResData(self.nCurrentSceneID)
    local nScope = tbMapResData.nScope
    local ViewSize = self.pWidgetRef.cvsPanel.Slot:GetSize()
    local nZoomFactor = 1
    if nScope ~= 0 then
        local nMapSizeX = tbMapResData.nMapSizeX
        local nUIMapSizeX = tbMapResData.nUIMapSizeX - tbMapResData.nUIMapOffsetX * 2
        local nScale = (nMapSizeX / nScope) * ViewSize.X / nUIMapSizeX
        nZoomFactor = (nScale * nAdjustFactor - 1) * nValue + 1
    end
    return nZoomFactor
end

-- local function OnSliderValueChanged(self, nValue)
--     local nZoomFactor = ConvertToZoomFactor(self, nValue)
--     if nZoomFactor == 1 then
--         self.nCurrentGrade = WorldMapUtil.tbMapGrade.None
--     else
--         self.nCurrentGrade = WorldMapUtil.tbMapGrade.Second
--     end
--     ZoomMap(self, nZoomFactor, true)
-- end

local function OnSliderValueChanged(self, nValue)
    local nZoomFactor = ConvertToZoomFactor(self, nValue)
    --self.nCurrentSliderValue = nValue
    if nZoomFactor == 1 then
        self.nCurrentGrade = WorldMapUtil.tbMapGrade.None
    else
        self.nCurrentGrade = WorldMapUtil.tbMapGrade.Second
    end
    --self:ZoomMap(nZoomFactor, true)
    -- local nDeltaValue = nValue - self.nLastSliderValue
    -- self.nLastSliderValue = nValue
    -- local nDeltaChangeDistance = nDeltaValue * WorldMapUtil.PinchSize
    -- self.pbMap:OnPinch(nDeltaChangeDistance)
    self.pbMap:SetMapSizeZoomFactor(nZoomFactor)
end

-- local function OnZoomUpClick(self)
--     local nValue = self.pWidgetRef.sldrZoom:GetValue()
--     nValue = math.min(nValue + 0.1, 1)
--     self.pWidgetRef.sldrZoom:SetValue(nValue)
--     OnSliderValueChanged(self, nValue)
-- end

-- local function OnZoomDownClick(self)
--     local nValue = self.pWidgetRef.sldrZoom:GetValue()
--     nValue = math.max(nValue - 0.1, 0)
--     self.pWidgetRef.sldrZoom:SetValue(nValue)
--     OnSliderValueChanged(self, nValue)
-- end

local function OnZoomUpClick(self)
    local nValue = self.pWidgetRef.sldrZoom:GetValue()
    nValue = math.min(nValue + 0.1, 1)
    if math.abs(1 - nValue) < 0.05 then
        nValue = 1
    end
    self.nLastSliderValue = nValue
    self.pWidgetRef.sldrZoom:SetValue(nValue)
    OnSliderValueChanged(self, nValue)
end

local function OnZoomDownClick(self)
    local nValue = self.pWidgetRef.sldrZoom:GetValue()
    nValue = math.max(nValue - 0.1, 0)
    if nValue < 0.05 then
        nValue = 0
    end
    self.nLastSliderValue = nValue
    self.pWidgetRef.sldrZoom:SetValue(nValue)
    OnSliderValueChanged(self, nValue)
end

local function OnDelFlagPosClick(self)
    self.pbMap:ClearCachePoint()
    if ParachutionSystem_C:GetState() == ProtoDR.rFFAProcessState_EState.SELECTION then
        local bSelected = false
        local nInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
        local tbPointes = ParachutionSystem_C:GetSelectionPointes()
        for _, value in ipairs(tbPointes) do
            if value.nInstanceId == nInstanceId then
                bSelected = true
                break
            end
        end
        if bSelected then
            NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDP.c2d_FFACancelSelectionPoint)
        else
            log("cancel select point but no selected")
        end
    else
        UIUtils.ShowToast(UITextDef.FFA_CANCEL_SELECT_POINT_ISLOCK)
    end
end

local function DestroyTimer(self)
    if self.OneSecondTimer ~= nil then
        self.TimerHelper:ClearTimer(self.OneSecondTimer)
        self.OneSecondTimer = nil
    end
end

local function OnOneSecondPass(self)
    local txtCoolTime = self.pWidgetRef.cdtxtTimer
    local nTime = math.max(self.nTime, 0)
    -- nTime = nTime / GameplayStatics.GetGlobalTimeDilation(GWorld)
    local nMinute = math.floor(nTime / 60)
    local nSecond = nTime % 60
    local szTime = string.format("%02.0f:%02.0f", nMinute, nSecond)
    txtCoolTime:SetText(szTime)
end

local function StartTimer(self)
    if self.OneSecondTimer == nil then
        self.OneSecondTimer = self.TimerHelper:NewTimerMethod(self, function()
            self.nTime = self.nTime - DELAY_TIME 
            OnOneSecondPass(self)
        end, DELAY_TIME, true)
    end
    OnOneSecondPass(self)
end

local function OnRecvRepairStepRemainTime(self, rStepRemainTime)
    self.nTime = rStepRemainTime.nTime
    if self.OneSecondTimer == nil then
        StartTimer(self)
    end
end

-- local function DestroyDelayTimer(self)
--     if self.tbDelayTimer ~= nil then
--         self.TimerHelper:ClearTimer(self.tbDelayTimer)
--         self.tbDelayTimer = nil
--     end
-- end

local function OnHideDialog(self)
    -- self.pbDialog.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.ovlTitle:SetVisibility(ESlateVisibility_Visible)
    self.nTransporterId = 0
    -- DestroyDelayTimer(self)
end

local function ShowDialog(self, nTransporterId)
    if self.nTransporterId == nTransporterId then
        return
    end

    local tbTransporterTemp = TransporterDataTable:GetTemplate(nTransporterId)
    if tbTransporterTemp == nil then
        logwarning("UIFFASelectBornPoint show dialog invalid transporterid ", nTransporterId)
        return
    end
    local nIndex = math.random(1, #tbTransporterTemp.tbDialogIds)
    local nDialogId = tbTransporterTemp.tbDialogIds[nIndex]
    local tbDialogTemp = FFADialogDataTable:GetTemplate(nDialogId, 1)
    if tbDialogTemp == nil then
        logwarning("UIFFASelectBornPoint show dialog invalid dialog id ", nTransporterId, nDialogId)
        return
    end
    self.pbDialog:OnRefresh(nDialogId, OnHideDialog, false)
    self.nTransporterId = nTransporterId
    if tbDialogTemp.nSoundId > 0 then
        if self.tbTransporterSound ~= nil then
            self.tbTransporterSound:Stop()
            self.tbTransporterSound:OnDestroy()
            self.tbTransporterSound = nil
        end
        self.tbTransporterSound = SoundManager:PlaySoundEffect(tbDialogTemp.nSoundId, false)
    end

    self.pbDialog.pWidgetRef:SetVisibility(ESlateVisibility_Visible)
    self.pWidgetRef.ovlTitle:SetVisibility(ESlateVisibility_Collapsed)
end

local function OnFFASelectPoint(self, nTransporterId)
    ShowDialog(self, nTransporterId)
end

local function RefreshTeamMember(self)
    local Visible, Collapsed = ESlateVisibility_Visible, ESlateVisibility_Collapsed
    local tbPlayer = GamePlayerSelfHelper:Get()

    local BattleTeamComponent = tbPlayer and tbPlayer.BattleTeamComponent
    if BattleTeamComponent then
        local tbBaseInfos = BattleTeamComponent:GetTeamBaseInfo()
        if tbBaseInfos then
            local nMemberCount = #tbBaseInfos
            if nMemberCount > PLAYER_COUNT - 1 then
                logerror("team member count is over ", nMemberCount)
            end
            
            log("RefreshTeamMember count ", nMemberCount)
            for _, v in ipairs(tbBaseInfos) do
                local nIndex = v.nIndex
                local szName = v.name
                if szName then
                    self.tbPBMember[nIndex]:SetPlayerInfo(szName, UIResourceDef.TEAM_INDEX_SLATECOLOR[nIndex])
                end
                self.tbPBMember[nIndex].pWidgetRef:SetVisibility(Visible)
            end
            for i = nMemberCount + 1, PLAYER_COUNT - 1 do
                self.tbPBMember[i].pWidgetRef:SetVisibility(Collapsed)
            end
        end
    end
end

local function InitNamePanel(self)
    local bShowOther = ParachutingNewIni.tbReadyArea.bOtherSelectionPoint-- ParachutionSystem_C:IsShowOtherPoint()
    self.tbPBMember[OTHER_INDEX].pWidgetRef:SetVisibility(bShowOther and ESlateVisibility_Visible or ESlateVisibility_Collapsed)
    if bShowOther then
        self.tbPBMember[OTHER_INDEX]:SetPlayerInfo(UISetUtils.GetL10NTextByKey("FFA_OTHER_PLAYER"), UIResourceDef.COLOR.RED.SLATE_COLOR)
    end
    RefreshTeamMember(self)

    self.pWidgetRef.txtCount:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("TRANSPORT_PLAYER_COUNT"), 0))
end

local function OnFFAProcessStateChanged(self, nState)
    if nState and nState == ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        self:PlayAnimation(ANIM_NAME, 0, 1, EUMGSequencePlayMode.Reverse)
        self.pWidgetRef.imgLock:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    end
end

local function OnTeamInfoChanged(self)
    log("OnTeamInfoChanged")
    RefreshTeamMember(self)
end

local function SetSliderEnable(self, bEnable)
    self.pWidgetRef.vboxSlider:SetVisibility(bEnable and ESlateVisibility_Visible or ESlateVisibility_HitTestInvisible)
end

function UIFFASelectBornPoint:OnCreate()
end

function UIFFASelectBornPoint:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.pbMap = self.PrefabHelper:BindPrefab(pWidgetRef.pbMap, UIDef.UP_FFA_SELECTPOINT_MAP)
    self.tbPBMember = {}
    for i = 1, PLAYER_COUNT do
        local pbMember = self.PrefabHelper:BindPrefab(pWidgetRef["pbFFASelectBornSub0"..i], UIDef.UP_FFA_SELECTBORN_SUB)
        table.insert(self.tbPBMember, pbMember)
    end
    self.pbDialog = self.PrefabHelper:BindPrefab(pWidgetRef.pbMainTips)
    self.UILogicHelper:CreateUILogic("ULMapPointSymbol")
    self.bDialogIngoreEvent = true
    self.nLastSliderValue = DEFAULT_SLIDER_VALUE

    
    local World = GameWorldSystem:GetWorld()
    self.nCurrentSceneID = World.nSceneId

    pWidgetRef.vboxSlider:SetVisibility(ESlateVisibility_Visible)
    pWidgetRef.imgLock:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.sldrZoom:SetValue(self.nLastSliderValue)
    --self.nLastSliderValue = DEFAULT_SLIDER_VALUE
    -- local nZoomFactor = ConvertToZoomFactor(self, self.nLastSliderValue)
    -- --ZoomMap(self, nZoomFactor, true)

    -- self.pbMap:SliderToZoomMap(nZoomFactor, self.nCurrentSceneID)
    -- OnSliderValueChanged(self, self.nLastSliderValue)

    InitNamePanel(self)
end

function UIFFASelectBornPoint:OnBindEvent()
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, self.CloseSelf)
    Helper:RegisterCppDelegate(pWidgetRef.sldrZoom.OnValueChanged, self, OnSliderValueChanged)
    Helper:RegisterCppDelegate(pWidgetRef.btnZoomUp.OnClicked, self, OnZoomUpClick)
    Helper:RegisterCppDelegate(pWidgetRef.btnZoomDown.OnClicked, self, OnZoomDownClick)
    Helper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvRepairStepRemainTime)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINT_TRANSPORTER, self, OnFFASelectPoint)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnTeamInfoChanged)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_ENABLE_SELECTPOINT_MAP_PINCH, self, SetSliderEnable)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_TRANSPORTER_PLAYER_COUNT, self, self.SetTransporterPlayerCount)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_TRANSPORTER_SET_NOOB_DUNGEON, self, self.SetNoobDungeon)
    Helper:RegisterCppDelegate(pWidgetRef.btnDelFlagPos.OnClicked, self, OnDelFlagPosClick)
end

function UIFFASelectBornPoint:OnShow()
    log("UIFFASelectBornPoint:OnShow")
    UIManager:CloseWnd(UIDef.UI_WORLD_MAP)

    local nZoomFactor = ConvertToZoomFactor(self, self.nLastSliderValue)
    self.pbMap:SliderToZoomMap(nZoomFactor, self.nCurrentSceneID)
    OnSliderValueChanged(self, self.nLastSliderValue)

    self.nTime = ParachutionSystem_C:GetCountDownTime()
    if self.nTime ~= nil then
        StartTimer(self)
    end

    local nState = ParachutionSystem_C:GetState()
    OnFFAProcessStateChanged(self, nState)

    local bPlayAni = self.tbOpenArgs.bPlayAni ~= nil and self.tbOpenArgs.bPlayAni or true
    if bPlayAni then
        self:PlayAnimation("animCome", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    OnTeamInfoChanged(self)
end

function UIFFASelectBornPoint:OnHide()
    log("UIFFASelectBornPoint:OnHide")
    DestroyTimer(self)
    self:PlayAnimation("animCome", 0, 1, EUMGSequencePlayMode.Reverse, 1)
end


function UIFFASelectBornPoint:OnDestroy()
    if self.tbTransporterSound ~= nil then
        SoundManager:DeleteSound(self.tbTransporterSound)
        self.tbTransporterSound = nil
    end
    self.pbMap = nil
    self.pbDialog = nil
end

function UIFFASelectBornPoint:GetNoobParachutingArea()
    if self.pbMap then
        return self.pbMap:GetNoobParachutingArea()
    end
end

function UIFFASelectBornPoint:SetBorderCheckEnable(bEnable)
    self.pWidgetRef.btnSymbol:SetIsEnabled(bEnable)
end

function UIFFASelectBornPoint:SetNoobDungeon(bValue)
    if self.pbMap then
        self.pbMap.bNoobDungeon = bValue
    end
end

function UIFFASelectBornPoint:GetMaxZoomFactor()
    return ConvertToZoomFactor(self, 1)
end

function UIFFASelectBornPoint:SetTransporterPlayerCount(nCount)
    self.pWidgetRef.txtCount:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("TRANSPORT_PLAYER_COUNT"), nCount))
end

return UIFFASelectBornPoint