local luaclass = require ("luaclass")
local WndBase = require("WndBase")

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UIScheduleSeaAdventure = luaclass("UIScheduleSeaAdventure", WndBase)
local SeaAdventureHelper = require("SeaAdventureHelper")
local ScheduleTypeDef = require("ScheduleTypeDef")
local Proto = require("ClientProtoNames")
local ScheduleSystem = require("ScheduleSystem")
local DelayTimer = require("DelayTimer")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local TimeUtil = require("TimeUtil")
local ClientEventDef = require("ClientEventDef")
local AwardSystem = require("AwardSystem")
local AwardSessionType = require("AwardSessionType")
local Timer = require("Timer")
local UIUtils = require("UIUtils")

UIScheduleSeaAdventure.tbStepTiles = nil
UIScheduleSeaAdventure.tbCircleRewards = nil
UIScheduleSeaAdventure.bShowInfo = false
UIScheduleSeaAdventure.DelayToStep = nil
UIScheduleSeaAdventure.DelayRefresh = nil

UIScheduleSeaAdventure.tbTileItems = nil
UIScheduleSeaAdventure.pbStart = nil

UIScheduleSeaAdventure.nCurrentRollCount = 0
UIScheduleSeaAdventure.nCurrentTile = SeaAdventureHelper.TILE_START
UIScheduleSeaAdventure.nMoveResult = nil

local STEP_INTERVAL = 0.8
local DICE_ANIM_TIME = 2
local UNKOWN_DELAY_TIME = 1
local STEP_TIMER = "STEP_TIMER"

local function LOG(...)
    log("[DICE]:", ...)
end

local function OnCloseClicked(self)
    self:CloseSelf()
    if self.tbOpenArgs.szFrom ~= nil and self.tbOpenArgs.szFrom ~= "LobbyMain" then
        UIManager:OpenWnd(self.tbOpenArgs.szFrom, {szFrom = UIDef.UI_SCHEDULE_SEAADVENTURE, nId = self.tbOpenArgs.nId})
    end 
end

local function OnDiceCountChange(self)
    local pWidgetRef = self.pWidgetRef
    local nDiceId = self.tbInstance:GetDiceId()
    local nDiceCount = ItemSystem:GetItemCount(nDiceId) 
    pWidgetRef.txtDiceleft:SetText(nDiceCount)
end

local function RefreshDiceInfo(self)
    local pWidgetRef = self.pWidgetRef
    OnDiceCountChange(self)

    local tbTemplate = self.tbInstance:GetTemplate()
    local nStartMonth, nStartDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStartTime)
    local nEndMonth, nEndDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStopTime)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgStartMon1, pWidgetRef.ImgStartMon2, pWidgetRef.ImgStartDay1, pWidgetRef.ImgStartDay2,
    nStartMonth, nStartDay)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgEndMon1, pWidgetRef.ImgEndMon2, pWidgetRef.ImgEndDay1, pWidgetRef.ImgEndDay2,
    nEndMonth, nEndDay)
end

local function OnTileSelectChanged(self)
    self.nCurrentTile = self.tbInstance:GetCurrentTile()
    LOG("Open SeaAdventure, current tile :", self.nCurrentTile)
    self.pbStart:SetSelect(self.nCurrentTile == SeaAdventureHelper.TILE_START)
    for i = 1, SeaAdventureHelper.TILE_MAX do
        local pbTile = self.tbStepTiles[i]
        pbTile:SetSelect(i == self.nCurrentTile)
    end
end

local function RefreshDiceTileInfo(self)
    local tbCounts = nil
    if SeaAdventureHelper.bTest then 
        self.tbTileItems = SeaAdventureHelper.tbTestTileItems
        tbCounts = SeaAdventureHelper.tbTestTileCounts
    else  
        local tbTemplate = self.tbInstance:GetTemplate()
        self.tbTileItems, tbCounts= SeaAdventureHelper.GetTileRewardsTemplateIds(tbTemplate.tbScheduleData.tbTileReward)
    end
    local tbTileItems = self.tbTileItems 
    local nTileTypeDef = SeaAdventureHelper.TILE_TYPE
    self.pbStart:SetTileType(nTileTypeDef.START)
    for i = 1, SeaAdventureHelper.TILE_MAX do
        local pbTile = self.tbStepTiles[i]
        if tbTileItems[i] == SeaAdventureHelper.UNKNOWN_TILE then 
            pbTile:SetTileType(nTileTypeDef.UNKNOWN)
        else  
            pbTile:SetTileType(nTileTypeDef.NORMAL)
            pbTile:SetTileTemplateId(tbTileItems[i], tbCounts[i])
        end
    end
    OnTileSelectChanged(self)
end

local function RefreshDiceReward(self)
    local tbDiceRewards = nil
    if SeaAdventureHelper.bTest then 
        tbDiceRewards = SeaAdventureHelper.tbTestDiceRewards
    else  
        local tbTemplate = self.tbInstance:GetTemplate()
        tbDiceRewards = SeaAdventureHelper.GetTileRewardsTemplateIds(tbTemplate.tbScheduleData.tbCircleReward)
    end
    for i = 1, SeaAdventureHelper.CIRCLE_REWARD_MAX do
        local pbReward = self.tbCircleRewards[i]
        pbReward:SetRewardData(tbDiceRewards[i], i)
    end
end

local function RefreshRewardState(self, bDelayRefresh)

    local fnRefreshRewardState = function()
        local tbDiceRewardsState = nil
        if SeaAdventureHelper.bTest then 
            tbDiceRewardsState = SeaAdventureHelper.tbTestDiceRewardsState
        else  
            tbDiceRewardsState = self.tbInstance:GetCircleRewardState()
        end
        for i = 1, SeaAdventureHelper.CIRCLE_REWARD_MAX do
            local pbReward = self.tbCircleRewards[i]
            pbReward:SetRewardState(tbDiceRewardsState[i])
        end
    end
    
    if bDelayRefresh then   
        if self.DelayRefresh ~= nil  then 
            DelayTimer:ClearTimer(self.DelayRefresh)
            self.DelayRefresh = nil 
        end
        self.DelayRefresh = DelayTimer:DelayRun(function()
            fnRefreshRewardState()
        end, DICE_ANIM_TIME)
    else  
        fnRefreshRewardState()
    end
end

local function ShowGetDicesInfo(self)
    self.bShowInfo = not self.bShowInfo
    local VISIBLE, COLLAPSED = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    self.pWidgetRef.pbSeaActivityInfo:SetVisibility(self.bShowInfo and VISIBLE or COLLAPSED)
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    if self.bShowInfo then
        ShowGetDicesInfo(self)
    end
    return WidgetBlueprintLibrary.Handled()
end

local function ShowUnknonwnTileTip(self, bVisible, state)
    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    self.pWidgetRef.bdrAdventureTip:SetVisibility(bVisible and VISIBLE or COLLAPSED)
    if bVisible then  
        local MoveState = Proto.s2c_RollDice_Move
        if state == MoveState.FORWARD then 
            LOG("DICE TO FORWARD")
            self.pWidgetRef.txtAdventureTip:SetText(UISetUtils.GetL10NTextByKey("UI_UNKNONW_FORWARD"))
        elseif state == MoveState.BACKWARD then 
            LOG("DICE TO BACKWARD")
            self.pWidgetRef.txtAdventureTip:SetText(UISetUtils.GetL10NTextByKey("UI_UNKNONW_BACKWARD"))
        elseif state == MoveState.ORIGIN then 
            LOG("DICE TO ORIGIN")
            self.pWidgetRef.txtAdventureTip:SetText(UISetUtils.GetL10NTextByKey("UI_UNKNONW_ORIGIN"))
        end
        self:PlayAnimation("animAdventureTipIn", 0, 1,  EUMGSequencePlayMode.Forward, 1)
    end
end

local function ShowForbiddenTouchUi(self, bShow)
    self.pWidgetRef.bdrForbidden:SetVisibility(bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end


local function ShowTileAward()
    local ScheduleAwardSession = AwardSystem:GetAlivedSession(AwardSessionType.ScheduleRouletteAwardSession)
    if ScheduleAwardSession then
        AwardSystem:FinishSession(ScheduleAwardSession)
    else
        log("OnAwardSchedule not find roulette session")
    end
end
-- FORWARD  = 0,
-- BACKWARD = 1,
-- ORIGIN   = 2,
-- STILL    = 3,
local function ProcessTileReward(self)
    local MoveState = Proto.s2c_RollDice_Move
    if self.tbTileItems[self.nCurrentTile] == SeaAdventureHelper.UNKNOWN_TILE then 
        local state = self.nMoveResult
        ShowUnknonwnTileTip(self, true, state)
        self.DelayToStep = DelayTimer:DelayRun(function()
            ShowUnknonwnTileTip(self, false)
            if state == MoveState.FORWARD then  
                if self.nCurrentTile >= SeaAdventureHelper.TILE_MAX then  
                    self.nCurrentTile = SeaAdventureHelper.TILE_START
                end
                self.nCurrentTile = self.nCurrentTile + 1
            elseif state == MoveState.BACKWARD then  
                self.nCurrentTile = self.nCurrentTile - 1
                if self.nCurrentTile <= SeaAdventureHelper.TILE_START then  
                    self.nCurrentTile = SeaAdventureHelper.TILE_MAX
                end
            elseif state == MoveState.ORIGIN then   
                self.nCurrentTile = SeaAdventureHelper.TILE_START
            end

            for i = 1, SeaAdventureHelper.TILE_MAX do
                self.tbStepTiles[i]:SetSelect(i == self.nCurrentTile)
                if i == self.nCurrentTile then 
                    self.tbStepTiles[i]:PlayFinalSelectAnim()
                end
            end
            self.pbStart:SetSelect(self.nCurrentTile == SeaAdventureHelper.TILE_START)
            if self.nCurrentTile == SeaAdventureHelper.TILE_START then   
                self.pbStart:PlayFinalSelectAnim()
            end
            if self.nCurrentTile ~= SeaAdventureHelper.TILE_START and 
                self.tbTileItems[self.nCurrentTile] ~= SeaAdventureHelper.UNKNOWN_TILE then  
                -- self.tbInstance:RequestGetTileReward()
                ShowTileAward()
            end
            LOG("unknown final tile is :", self.nCurrentTile)
            ShowForbiddenTouchUi(self, false)
        end, UNKOWN_DELAY_TIME)
    else  
        ShowForbiddenTouchUi(self, false)
        ShowTileAward()
        -- self.tbInstance:RequestGetTileReward()
    end
end

local function StepOnce(self)
    self.nCurrentRollCount = self.nCurrentRollCount - 1
    if self.nCurrentTile >= SeaAdventureHelper.TILE_MAX then  
        self.nCurrentTile = SeaAdventureHelper.TILE_START
    end
    self.nCurrentTile = self.nCurrentTile + 1

    local state = self.nMoveResult
    local bFinalStill = state ==  Proto.s2c_RollDice_Move.STILL
    for i = 1, SeaAdventureHelper.TILE_MAX do
        self.tbStepTiles[i]:SetSelect(i == self.nCurrentTile)
        if self.nCurrentRollCount == 0 and i == self.nCurrentTile and bFinalStill then 
            self.tbStepTiles[i]:PlayFinalSelectAnim()
        elseif i == self.nCurrentTile then 
            self.tbStepTiles[i]:PlayNormalSelectAnim()
        end
    end
    self.pbStart:SetSelect(false)
    LOG("value is :", self.nCurrentTile)
end

local function StartDiceAnim(self)
    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.fwDice:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.pWidgetRef.fwDice:Play(-1, 0)
    self:PlayAnimation("animRoll", 0, 1,  EUMGSequencePlayMode.Forward, 1)
end

local function StopDiceAnim(self)
    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Visible)
    local szDiceRes = SeaAdventureHelper.DICE_NUM[self.nCurrentRollCount]
    UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnStart, szDiceRes:load())
    self.pWidgetRef.fwDice:Stop()
    self.pWidgetRef.fwDice:SetVisibility(ESlateVisibility.Collapsed)
end

local function StartStepToTile(self)
    StopDiceAnim(self)
    StepOnce(self)
    Timer.StartOwnerTimer(self, STEP_TIMER, function()
        if self.nCurrentRollCount > 0 then 
            StepOnce(self)
        else 
            ProcessTileReward(self)
            Timer.StopOwnerTimer(self, STEP_TIMER)
        end
    end, STEP_INTERVAL, true)
end

local function RollProcess(self)
    StartDiceAnim(self)
    if self.DelayToStep ~= nil  then 
        DelayTimer:ClearTimer(self.DelayToStep)
        self.DelayToStep = nil 
    end
    self.DelayToStep = DelayTimer:DelayRun(function()
        StartStepToTile(self)
    end, DICE_ANIM_TIME)
end

local function StartRoll(self)
    --need to show full screen forbidden touch border
    local nDiceId = self.tbInstance:GetDiceId()
    local nDiceCount = ItemSystem:GetItemCount(nDiceId) 
    if nDiceCount <= 0 then 
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("DICE_NUN_NOT_ENOUGH"))
    else 
        self.tbInstance:RequestRollDice()
        ShowForbiddenTouchUi(self, true)
    end
end

local function OnDiceRollResult(self, bSuccess, nRollNum, nCurrentTile, nMoveResult)
    LOG("dice roll result ", bSuccess, nRollNum, nCurrentTile, nMoveResult)
    if bSuccess then 
        self.nCurrentRollCount = nRollNum
        self.nMoveResult = nMoveResult
        RollProcess(self)
    else  
        ShowForbiddenTouchUi(self, false)
    end
end

function UIScheduleSeaAdventure:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbSeaActivityInfo, UIDef.UP_SEA_ADVENTURE_INFO)
    self.pbStart = self.PrefabHelper:BindPrefab(self.pWidgetRef.up_start, UIDef.UP_SEA_ADVENTURE_TILE)
    if self.tbStepTiles == nil then self.tbStepTiles = {} end
    for i = 1, SeaAdventureHelper.TILE_MAX do
        local pbTile = self.PrefabHelper:BindPrefab(self.pWidgetRef["sea_tile"..i], UIDef.UP_SEA_ADVENTURE_TILE)
        table.insert(self.tbStepTiles, pbTile)
    end
    if self.tbCircleRewards == nil then self.tbCircleRewards = {} end 
    for i = 1, SeaAdventureHelper.CIRCLE_REWARD_MAX do
        local pbReward = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbCircleReward"..i], UIDef.UP_SEA_ADVENTURE_REWARD)
        table.insert(self.tbCircleRewards, pbReward)
    end
end

local function OnEnterForeground(self)
    RefreshDiceInfo(self)
    RefreshDiceTileInfo(self)
    RefreshDiceReward(self)
    RefreshRewardState(self, false)
end

function UIScheduleSeaAdventure:OnUnload()
end

function UIScheduleSeaAdventure:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnCloseClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnStart.OnClicked, self, StartRoll)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGetDices.OnClicked, self, ShowGetDicesInfo)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrForTouch.OnMouseButtonUpEvent, self, OnMouseButtonUp)

    EventHelper:RegisterEvent(ClientEventDef.EV_SEA_DICE_COUNT_CHANGE, self, OnDiceCountChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEA_ADVENTURE_DICE_ROLL, self, OnDiceRollResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH_CIRLEREWARD, self, RefreshRewardState)
    EventHelper:RegisterEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND, self, OnEnterForeground)
end

function UIScheduleSeaAdventure:OnCreate()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROLL)
end

function UIScheduleSeaAdventure:OnDestroy()
    self.tbInstance = nil
    if self.DelayToStep ~= nil  then 
        DelayTimer:ClearTimer(self.DelayToStep)
        self.DelayToStep = nil 
    end
    if self.DelayRefresh ~= nil  then 
        DelayTimer:ClearTimer(self.DelayRefresh)
        self.DelayRefresh = nil 
    end
    Timer.StopOwnerTimer(self, STEP_TIMER)
end

function UIScheduleSeaAdventure:OnShow()
    RefreshDiceInfo(self)
    RefreshDiceTileInfo(self)
    RefreshDiceReward(self)
    RefreshRewardState(self, false)
    self:PlayAnimation("animSeaAdventureIn", 0, 1,  EUMGSequencePlayMode.Forward, 1, function()
        self:PlayAnimation("animSeaAdventureLoop", 0, 0,  EUMGSequencePlayMode.Forward, 1)
    end)
end

return UIScheduleSeaAdventure
