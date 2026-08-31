-----------------------------------------------------
--File Name    : ULFFARadarMapOp.lua
--Author       : Ran Jie
--Create Time  : 2019-9-9
--Description  : ULFFARadarMapOp
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMapOp = require("ULMapOp")
local ULFFARadarMapOp = luaclass("ULFFARadarMapOp", ULMapOp)
--import
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
local FFAMapModeDef = require("FFAMapModeDef")
local BattleTeammateSystem = require("BattleTeammateSystem")
local MiniMapSystem = require("MiniMapSystem")

local WAIT_OP_GROUP = 1001
local BATTLE_OP_GROUP = 1002


--起飞后，正常显示雷达图
local function OnControlModeActive(self, nState)
    log("OnControlModeActive, state=",nState)
    self.nLastState = nState
end

local function OnControlModeDeactivate(self, nState)
    self.bOpenWorldMap = false
    if nState == ControlModeDef.TRANSPORTNEW then
        self:UnregisterOperation("MapOpForSelfBornPoint")
    end
end

local function GetScopeByFFAMode(self, nFFAMode)
    local tbMapResData = self.Owner.tbMapResData
    local nScope = tbMapResData.nScope
    if nFFAMode == FFAMapModeDef.PREPARE then
        nScope = tbMapResData.nMapSizeX
    elseif nFFAMode == FFAMapModeDef.TRANSPORT or nFFAMode == FFAMapModeDef.TRANSPORT_NEW then
        nScope = tbMapResData.nTransportScope
    elseif nFFAMode == FFAMapModeDef.TRANSPORT_NEW_MAX then
        nScope = tbMapResData.nTransportMaxScope
    elseif nFFAMode == FFAMapModeDef.HUMAN then
        nScope = tbMapResData.nLandScope
    end
    log("GetScopeByFFAMode,",nFFAMode, nScope)
    return nScope
end


local function OnMapScopeChange(self, nFFAMode, nScope)
    if not nScope then
        nScope = GetScopeByFFAMode(self, nFFAMode)
    end
    if math.abs(self.Owner.nCurrentScope - nScope) >= 1 then
        self.Owner:RefreshMap(nScope)
    end
end

local function OnRecvWaitStageInfo(self, rWaitStage)
    log("OnRecvWaitStageInfo")
    --local tbGameState = BattleGameModeSystem:GetGameState()
    local bWaitStage = rWaitStage.bWaitStage
    self.bPrepareTimer = bWaitStage
end

local function OnStateChangedComposite(self)
    if self.bPrepareTimer == nil then
        self.bPrepareTimer = MiniMapSystem:IsFFAWaitStage()
    end
    if self.nLastState == nil or
       self.bPrepareTimer == nil then
        return
    end

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsMapContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.hbxPoisonProgress:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.Collapsed)

    local bWaitStage = self.bPrepareTimer
    local nState = self.nLastState
    log("ULFFARadarMapOp:OnStateChangedComposite",bWaitStage,nState)
    if nState == ControlModeDef.TRANSPORT or nState == ControlModeDef.TRANSPORTNEW then
        pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        --self:UnregisterAllOperations()
        self:RegisterGroupOperations(BATTLE_OP_GROUP)
        --self.bPrepareTimer = false

        local nMode = FFAMapModeDef.TRANSPORT
        if nState == ControlModeDef.TRANSPORTNEW then
            nMode = FFAMapModeDef.TRANSPORT_NEW
        end
        self.Owner:RefreshMap(GetScopeByFFAMode(self, nMode))
        self.bOpenWorldMap = true
    else
        if bWaitStage then
            self.Owner:RefreshMap(GetScopeByFFAMode(self, FFAMapModeDef.PREPARE))
            --self:UnregisterAllOperations()
            self:RegisterGroupOperations(WAIT_OP_GROUP)
            self.bOpenWorldMap = true
        else
            pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            --self:UnregisterAllOperations()
            self:RegisterGroupOperations(BATTLE_OP_GROUP)
            self:UnregisterOperation("MapOpForSelfBornPoint") --仅仅在跳伞阶段生效
            if BattleTeammateSystem:GetTeamMode() == 1 then
                self:UnregisterOperation("MapOpFFATeamMember")
            end
            if nState == ControlModeDef.HUMAN then
                self.Owner:RefreshMap(GetScopeByFFAMode(self, FFAMapModeDef.HUMAN))
                --self:Reinit()
            elseif nState == ControlModeDef.SHIP then
                self.Owner:RefreshMap(GetScopeByFFAMode(self, FFAMapModeDef.SHIP))
                --SetMapData(self, tbMapResData, FFAMapModeDef.SHIP)
                --self:Reinit()
            end
            self.bOpenWorldMap = true
        end
    end

    self.nLastState = nil
end

local function OnClearAllFlagPoint(self)
    self:UnregisterOperation("MapOpFFAFlagLine")
end

--------------------------------------------------------------
--override
function ULFFARadarMapOp:OnBindEvent(EventHelper)
    ULFFARadarMapOp.super.OnBindEvent(self, EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, self, OnControlModeDeactivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, self, OnMapScopeChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_FLAG_POINT, self, OnClearAllFlagPoint) 

    --组合事件
    self.tbCompositeEventHandle = EventHelper:BeginCompositeOrEvent(self, OnStateChangedComposite)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_WAIT_STAGE_STATE_CHANGED, self, OnRecvWaitStageInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnControlModeActive)
    EventHelper:EndCompositeEvent()
end

return ULFFARadarMapOp
