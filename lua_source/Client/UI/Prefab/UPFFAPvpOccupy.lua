-----------------------------------------------------
--File Name    : UPBattleOccupy.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-12
--Description  : 占圈玩法ModeUI
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPGameMode = require("UPGameMode")
local UPBattleOccupy = luaclass("UPBattleOccupy", UPGameMode)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTeamSystem = require("BattleTeamSystem")
--local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ShipDataTable = require("ShipDataTable")
local DungeonRepProtoNames = require("DungeonRepProtoNames")
local UITextDef = require("UITextDef")
local SoundManager = require("SoundManager")
local GameObjectSystem = require("GameObjectSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")

local AREA_STATE_OCCUPIED = DungeonRepProtoNames.PVPOccupyAreaInfo_OccupyState.OCCUPIED
local AREA_STATE_OCCUPING = DungeonRepProtoNames.PVPOccupyAreaInfo_OccupyState.OCCUPING
local AREA_STATE_STALEMATE = DungeonRepProtoNames.PVPOccupyAreaInfo_OccupyState.STALEMATE

--[[
    local variable
]]
local COLOR_OCCUPY_NONE     = UIResourceDef.COLOR.BLUE.LINEAR_COLOR
local COLOR_OCCUPY_SELF     = UIResourceDef.COLOR.BLUE1.LINEAR_COLOR
local COLOR_OCCUPY_ENEMY    = UIResourceDef.COLOR.PINK.LINEAR_COLOR
local TICK_CD_INTERVAL      = 1 / 15
local MAX_AREA_COUNT        = 3
local MAX_TEAM_PLAYER_COUNT = 6
local NONE_TEAM_ID          = -1
local TAG_OCCUPY = "ArenaOccupyMarker"
local OCCUPYMARKER_MAP_RES_ID = 112

--[[
    memeber variable
]]
UPBattleOccupy.tbAreaInfoList           = {}
UPBattleOccupy.tbOccupyTimerList        = {}
UPBattleOccupy.tbProgressBar            = {}
UPBattleOccupy.tbTextblock              = {}
UPBattleOccupy.tbSelfTeamPlayerWidgets  = {}
UPBattleOccupy.tbEnemyTeamPlayerWidgets = {}
UPBattleOccupy.TickTimer                = nil

--[[
    local function
]]
local function RefreshOccupyPercent( self, nAreaId, bOccupying )
    local tbAreaInfo = self.tbAreaInfoList[nAreaId]
    local nOccupyingMaxTime = tbAreaInfo.nOccupyingMaxTime
    local nOccupyingRemainTime = tbAreaInfo.nOccupyingRemainTime

    local OccupyTimer = self.tbOccupyTimerList[nAreaId]
    local nElapsedTimeSinceLastRefresh = 0
    if OccupyTimer ~= nil then
        nElapsedTimeSinceLastRefresh = OccupyTimer:GetElapsedTime()
    end
    local nElapsedTime = nElapsedTimeSinceLastRefresh + nOccupyingMaxTime - nOccupyingRemainTime
    local nPercent = math.min( nElapsedTime / nOccupyingMaxTime, 1)
    self.tbProgressBar[nAreaId]:SetPercent(nPercent)

    local pTextblock = self.tbTextblock[nAreaId]
    if pTextblock then
        if (nPercent <= 0) and (not bOccupying) then
            pTextblock:SetText(UITextDef.L10N_OCCUPY_BEGIN)
        elseif nPercent >= 1 then
            pTextblock:SetText(UITextDef.L10N_OCCUPY_END)
        else
            pTextblock:SetText(string.format("%ds", math.ceil(nOccupyingMaxTime - nElapsedTime)))
        end
    end
end

local function OnTick( self )
    for k,v in pairs(self.tbOccupyTimerList) do
        RefreshOccupyPercent(self, k, true)
    end
end

-- 获取正在占领的区域个数
local function GetOccupyingCount( self )
    local nCount = 0
    local tbOccupyTimerList = self.tbOccupyTimerList
    local nIdx = next(tbOccupyTimerList)
    while nIdx ~= nil do
        nCount = nCount + 1
        nIdx = next(tbOccupyTimerList, nIdx)
    end
    return nCount
end

-- 清除占领Timer
local function ClearOccupyTimer( self, nAreaId )
    self.TimerHelper:ClearTimer(self.tbOccupyTimerList[nAreaId])
    self.tbOccupyTimerList[nAreaId] = nil

    local pTextblock = self.tbTextblock[nAreaId]
    pTextblock:SetText(UITextDef.L10N_OCCUPY_BEGIN)

    if GetOccupyingCount(self) == 0 then
        self.TickTimer:Pause()
    end
end

-- 占领Timer时间结束
local function OnOccupyTimeOver( self, nAreaId )
    ClearOccupyTimer(self,  nAreaId)
    self.tbProgressBar[nAreaId]:SetPercent(1)
end

-- 开始占领Timer
local function StartOccupyTimer( self, nAreaId, nTime )
    self.TimerHelper:ClearTimer(self.tbOccupyTimerList[nAreaId])
    self.tbOccupyTimerList[nAreaId] = self.TimerHelper:NewTimer(function() OnOccupyTimeOver(self, nAreaId) end, nTime)

    if not self.TickTimer:IsActive() then
        self.TickTimer:Resume()
    end
end

-- 获取占领圈颜色
local function GetColorByIdx( self, nTeamId, nOwnerTeamId, nSelfTeamId )
    if nTeamId == NONE_TEAM_ID then
        if nOwnerTeamId ~= NONE_TEAM_ID then
            return GetColorByIdx(self, nOwnerTeamId)
        else
            return COLOR_OCCUPY_NONE
        end
    elseif nTeamId == nSelfTeamId then
        return COLOR_OCCUPY_SELF
    end
    return COLOR_OCCUPY_ENEMY
end

-- 刷新占领圈颜色
local function RefreshOccupyStyle( self, nAreaId, bDefault )
    local nSelfTeamId = GamePlayerSelfHelper:Get().BattleTeamComponent.nTeamId
    local tbAreaInfo = self.tbAreaInfoList[nAreaId]
    local pProgressBar = self.tbProgressBar[nAreaId]
    if bDefault then
        pProgressBar:SetFillTint(COLOR_OCCUPY_NONE)
        pProgressBar:SetBackgroundTint(COLOR_OCCUPY_NONE)
        pProgressBar:SetOpacity(0.5)
        pProgressBar:SetPercent(0)
    else
        local nState = tbAreaInfo.nState
        if nState == AREA_STATE_OCCUPIED then
            pProgressBar:SetFillTint(GetColorByIdx(self, tbAreaInfo.nOwnerTeamId, tbAreaInfo.nOwnerTeamId, nSelfTeamId))
        elseif nState == AREA_STATE_OCCUPING then
            pProgressBar:SetFillTint(GetColorByIdx(self, tbAreaInfo.nOccupyingTeamId, tbAreaInfo.nOwnerTeamId, nSelfTeamId))
        end
        pProgressBar:SetBackgroundTint(GetColorByIdx(self, tbAreaInfo.nOwnerTeamId, tbAreaInfo.nOwnerTeamId, nSelfTeamId))

        if nState == AREA_STATE_STALEMATE then
            pProgressBar:SetOpacity(0.5)
        else
            pProgressBar:SetOpacity(0.8)
        end
    end
end

-- 顶部队伍信息条需要排序
local function fnSortPlayer(tbShipA, tbShipB)
    if tbShipA:IsDead() ~= tbShipB:IsDead() then
        if tbShipA:IsDead() then
            return false
        end
        if tbShipB:IsDead() then
            return true
        end
    end

    local nShipCategoryA = ShipDataTable:GetShipCategoryData(tbShipA:GetTemplateId())
    local nShipCategoryB = ShipDataTable:GetShipCategoryData(tbShipB:GetTemplateId())
    if nShipCategoryA ~= nShipCategoryB then
        return nShipCategoryA > nShipCategoryB
    end
    return tbShipA.nServerInstanceId > tbShipB.nServerInstanceId
end

-- 同步队伍信息
local function RefrshTeamInfo( self )
    local nSelfTeamId = GamePlayerSelfHelper:Get().BattleTeamComponent.nTeamId
    for nTeamId, tbTeamPlayer in pairs(BattleTeamSystem.tbTeams) do
        local tbPlayers = {}
        for i,tbGameObject in ipairs(tbTeamPlayer.tbGameObjects) do
            tbPlayers[i] = tbGameObject
        end
        table.sort(tbPlayers, fnSortPlayer)

        local tbTeamPlayerWidgets = (nTeamId == nSelfTeamId) and self.tbSelfTeamPlayerWidgets or self.tbEnemyTeamPlayerWidgets
        for i,pTeamPlayerWidget in ipairs(tbTeamPlayerWidgets) do
            if i <= #tbPlayers then
                pTeamPlayerWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                local tbPlayer = tbPlayers[i]
                local bLive = not tbPlayer:IsDead()
                pTeamPlayerWidget:SetIsEnabled(bLive)

                --local nCategory = ShipDataTable:GetShipCategoryData(tbPlayer:GetTemplateId())
                --local pShipFlag = UIResourceDef.SHIP_FLAG_BORDER[nCategory]:load()
                --logdebug("i,nCategory=",i,nCategory)
                --UISetUtils.SetImageBrushRes(pTeamPlayerWidget, pShipFlag, false)
            else
                pTeamPlayerWidget:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end
end

-- 同步双方分数
local function OnRecvTeamScores( self, rTeamScores )
    local nSelfTeamId = GamePlayerSelfHelper:Get().BattleTeamComponent.nTeamId
    for _,tbTeamScore in ipairs(rTeamScores.TeamScores) do
        if tbTeamScore.nTeamId == nSelfTeamId then
            self.pWidgetRef.txtSelfTeamScore:SetText(tbTeamScore.nScore)
        else
            self.pWidgetRef.txtEnemyTeamScore:SetText(tbTeamScore.nScore)
        end
    end
end

local function RefreshMap()
    local tbObjects  = GameObjectSystem:GetAllGameObjects()
    for _, v in pairs(tbObjects) do
        if v.szTag == TAG_OCCUPY then
            v:SetDynamicFlagId(OCCUPYMARKER_MAP_RES_ID)
        elseif v:GetObjectType() == GameObjectTypeDef.Npc then
            v:SetDynamicFlagId(nil)
        end
    end
end

-- 占圈状态变化
local function OnRecvOccupyAreaState( self, rPVPOccupyChangedAreaState )
    for _,tbArea in ipairs(rPVPOccupyChangedAreaState.Areas) do
        local nAreaId = tbArea.nAreaIndex
        self.tbAreaInfoList[nAreaId] = tbArea
        if tbArea.nState == AREA_STATE_OCCUPIED then -- 已占领
            OnOccupyTimeOver(self, nAreaId)
            local pTextblock = self.tbTextblock[nAreaId]
            if pTextblock then
                pTextblock:SetText(UITextDef.L10N_OCCUPY_END)
            end
            SoundManager:PlaySoundEffect(UIResourceDef.SC_OCCUPY_SUCCESS)
        elseif tbArea.nState == AREA_STATE_OCCUPING then -- 占领中
            StartOccupyTimer(self, nAreaId, tbArea.nOccupyingRemainTime)
            RefreshOccupyPercent(self, nAreaId, true)
        elseif tbArea.nState == AREA_STATE_STALEMATE then -- 僵持中
            ClearOccupyTimer(self, nAreaId)
            RefreshOccupyPercent(self, nAreaId, tbArea.nOccupyingRemainTime, false)
        else
            self.tbProgressBar[nAreaId]:SetPercent(0)
            ClearOccupyTimer(self, nAreaId)
        end
        RefreshOccupyStyle(self, nAreaId)
    end
end

-- 剩余时间同步
local function OnRecvStepRemainTime( self, rStepRemainTime )
    self:StartGameCD(self.pWidgetRef.txtCountDown, rStepRemainTime.nTime)
end

local function BattleGameStart( self )
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_GAME_START)
end

-- 阶段信息变化
local function OnRecvStepInfo( self, rCurrentStepInfo )
    local tbGameState = BattleGameModeSystem:GetGameState()
    local nStepId = rCurrentStepInfo.nStepId
    local nState = rCurrentStepInfo.nState

    if nStepId == tbGameState.nCountDownStepId then
        if nState ~= 2 then
            self.pbPvpCountDown:Start(tbGameState.rBattleTimerStepInfo.nStepTime)
            RefreshMap()
        end
    elseif nStepId == tbGameState.nMatchStepId then
        if nState ~= 2 then
            BattleGameStart(self)
            self:StartGameCD(self.pWidgetRef.txtCountDown, tbGameState.rPVPOccupyStepInfo.nStepTime)
        else
            self:EndGameCD()
        end
    end
end

--[[
    override function
]]
function UPBattleOccupy:OnLoad()
    self.pbPvpCountDown = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPvpCountDown)
end

function UPBattleOccupy:OnEnter()
    self.TickTimer = self.TimerHelper:NewTimerMethod(self, OnTick, TICK_CD_INTERVAL, true)
    self.TickTimer:Pause()

    for i=1, MAX_AREA_COUNT do
        local cpgbOverlay = self.pWidgetRef['cpgbOccupy0'..i]
        if cpgbOverlay then
            self.tbProgressBar[i] = cpgbOverlay
            self.tbTextblock[i] = self.pWidgetRef['txtOccupy0'..i]
            RefreshOccupyStyle(self, i, true)
        else
            break
        end
    end

    for i=1, MAX_TEAM_PLAYER_COUNT do
        self.tbSelfTeamPlayerWidgets[i] = self.pWidgetRef['imgSelfTeamPlayer0'..i]
        self.tbEnemyTeamPlayerWidgets[i] = self.pWidgetRef['imgEnemyTeamPlayer0'..i]
    end
    RefrshTeamInfo(self)
end

function UPBattleOccupy:OnBindEvent( EventHelper )
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_PVP_OCCUPY_AREA_STATE, self, OnRecvOccupyAreaState)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvStepRemainTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_INFO, self, OnRecvStepInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_TEAM_SCORES, self, OnRecvTeamScores)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_TEAM_INFOS, self, RefrshTeamInfo)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, RefrshTeamInfo)
end

return UPBattleOccupy
