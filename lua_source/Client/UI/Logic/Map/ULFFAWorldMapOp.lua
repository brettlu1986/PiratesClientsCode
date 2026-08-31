-----------------------------------------------------
--File Name    : ULFFAWorldMapOp.lua
--Author       : Ran Jie
--Create Time  : 2019-9-9
--Description  : ULFFAWorldMapOp
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMapOp = require("ULMapOp")
local ULFFAWorldMapOp = luaclass("ULFFAWorldMapOp", ULMapOp)
--import
local MiniMapSystem = require("MiniMapSystem")
local ControlModeSystem = require("ControlModeSystem")
local FlagMapLocationSystem = require("FlagMapLocationSystem")
local ClientEventDef = require("ClientEventDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local BattleTeammateSystem = require("BattleTeammateSystem")

local WAIT_OP_GROUP = 2001
local BATTLE_OP_GROUP = 2002

ULFFAWorldMapOp.bFFAWaitState = nil

--------------------------------------------------------------
local function OnClearAllFlagPoint(self)
    self:UnregisterOperation("MapOpFFAFlagLine")
end

local function OnRefreshViewForNewMate(self, tbNewMateObj)
    self.Owner.ViewerObj = tbNewMateObj
    self:Reinit()
end

--override
function ULFFAWorldMapOp:OnRegisterOperations(nGroupId, szOperationName)
    local bFFAWaitState = MiniMapSystem:IsFFAWaitStage()
    log("ULFFAWorldMapOp:OnRegisterOperations,self.Owner=",self.Owner,self.bFFAWaitState,bFFAWaitState)
    if bFFAWaitState == nil then
        self:RegisterGroupOperations(WAIT_OP_GROUP)
        return
    end
    if bFFAWaitState then
        self.Owner.Owner.pWidgetRef.ovlDelFlag:SetVisibility(ESlateVisibility_Collapsed)
        self.Owner.Owner.pWidgetRef.ovlFlagSelf:SetVisibility(ESlateVisibility_Collapsed)
        self.Owner.Owner.pWidgetRef.btnLocationPlayer:SetVisibility(ESlateVisibility_Collapsed)
    else
        self.Owner.Owner.pWidgetRef.ovlDelFlag:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self.Owner.Owner.pWidgetRef.ovlFlagSelf:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self.Owner.Owner.pWidgetRef.btnLocationPlayer:SetVisibility(ESlateVisibility_Visible)
    end
    if self.bFFAWaitState == bFFAWaitState then
        if ControlModeSystem.bParachutionEnd then
            self:UnregisterOperation("MapOpForSelfBornPoint")
        end
        self:OpenRegisterOperations()
    else
        self.bFFAWaitState = bFFAWaitState
        --self:UnregisterAllOperations()
        if bFFAWaitState then
            self:RegisterGroupOperations(WAIT_OP_GROUP)
        else
            self:RegisterGroupOperations(BATTLE_OP_GROUP)
            if ControlModeSystem.bParachutionEnd then
                self:UnregisterOperation("MapOpForSelfBornPoint")
            end
            if BattleTeammateSystem:GetTeamMode() == 1 then
                self:UnregisterOperation("MapOpFFATeamMember")
            end
        end
    end
end

function ULFFAWorldMapOp:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_FLAG_POINT, self, OnClearAllFlagPoint) 
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnRefreshViewForNewMate)
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BOT, self, OnRefreshViewForNewMate)
end

function ULFFAWorldMapOp:OnClickMapWorldPos(nWorldPosX, nWorldPosY)
    local bFFAWaitState = MiniMapSystem:IsFFAWaitStage()
    if bFFAWaitState then
        return
    end
    if TeamWatchClientHelper.IsOtherTeamWatch() then
        return
    end
    FlagMapLocationSystem:SetFlagPos(true, nWorldPosX, nWorldPosY)
end

return ULFFAWorldMapOp
