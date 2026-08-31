-----------------------------------------------------
--File Name    : ULFFAWatchBattleRadarMapOp.lua
--Author       : Ran Jie
--Create Time  : 2019-9-9
--Description  : ULFFAWatchBattleRadarMapOp
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMapOp = require("ULMapOp")
local ULFFAWatchBattleRadarMapOp = luaclass("ULFFAWatchBattleRadarMapOp", ULMapOp)
--import
local ClientEventDef = require("ClientEventDef")
local FFAMapModeDef = require("FFAMapModeDef")
local BattleTeammateSystem = require("BattleTeammateSystem")
local ControlModeSystem = require("ControlModeSystem")


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


local function OnClearAllFlagPoint(self)
    self:UnregisterOperation("MapOpFFAFlagLine")
end

--------------------------------------------------------------
--override
function ULFFAWatchBattleRadarMapOp:OnBindEvent(EventHelper)
    ULFFAWatchBattleRadarMapOp.super.OnBindEvent(self, EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, self, OnMapScopeChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_FLAG_POINT, self, OnClearAllFlagPoint) 
    --EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnRefreshViewForNewMate)

end

function ULFFAWatchBattleRadarMapOp:OnRegisterOperations(nGroupId, szOperationName)
    ULFFAWatchBattleRadarMapOp.super.OnRegisterOperations(self, nGroupId, szOperationName)
    if ControlModeSystem.bParachutionEnd then
        self:UnregisterOperation("MapOpForSelfBornPoint")
    end
    if BattleTeammateSystem:GetTeamMode() == 1 then
        self:UnregisterOperation("MapOpFFATeamMember")
    end
end

return ULFFAWatchBattleRadarMapOp
