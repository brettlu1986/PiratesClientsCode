-----------------------------------------------------
--File Name    : MapOpSelf.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : MapOpSelf
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpSelf = luaclass("MapOpSelf",MapOpBase)

local DCProto = require("DungeonCommonProtoNames")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local BattleTeammateSystem = require("BattleTeammateSystem")
local ClientEventDef = require("ClientEventDef")

MapOpSelf.nSelfId = nil
MapOpSelf.MapOpPoint = nil
MapOpSelf.nTeamMode = nil
--------------------------------------------------------
-- local function OnShipDie(self)
--     self.MapOpObj:RemoveContentPoint(self.nSelfId)
--     self.MapOpObj:SetEnable(false)
-- end

-- local function OnShipRespawn(self)
--     self.nSelfId = self.MapOpObj:AddContentPoint(self.SelfObj.pUEActor, self.pWidgetRef.ovlArrow, true)
--     self.MapOpObj:SetEnable(true)
-- end

-- local function BindEvent(self)
    -- local EventHelper = self.EventHelper
    -- local ShipLifecycleComponent = self.SelfObj.ShipLifecycleComponent
    -- if(ShipLifecycleComponent ~= nil)then
    --     EventHelper:RegisterLuaDelegate(ShipLifecycleComponent.CheckSelfDead, OnShipDie, self)
    --     EventHelper:RegisterLuaDelegate(ShipLifecycleComponent.OnPawnReborn, OnShipRespawn, self)
    -- end
-- end

local function RefreshSelfData(self)
    local tbSelfObj = GamePlayerSelfHelper:Get()
    local imgSelfIcon = self.pWidgetRef.imgSelfIcon
    local szIcon = UIResourceDef.MAP_SELF_ICON
    local pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
    if self.nSelfId then
        self.MapOpObj:RemoveContentPoint(self.nSelfId)
        self.MapOpPoint:RemoveContentPoint(self.nSelfId)
        self.nSelfId = nil
    end
    log("MapOpSelf:RefreshSelfData",self.nTeamMode)
    -- if not self.nTeamMode then
    --     return
    -- end
    if tbSelfObj:IsDead() then
        if not TeamWatchClientHelper.IsOtherTeamWatch() and self.nTeamMode and self.nTeamMode > 1 then
            local tbMemberInfo = tbSelfObj.BattleTeamComponent:GetMemberInfo(tbSelfObj:GetServerInstanceId())
            if tbMemberInfo then
                local nIndex = tbMemberInfo.nIndex
                szIcon = UIResourceDef.TEAM_MEMBER_STATE_ICON[DCProto.TeamInfo_EState.DEAD]
                pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[nIndex]
                self.pWidgetRef.imgSelfArrow:SetVisibility(ESlateVisibility_Collapsed)
                self.nSelfId = self.MapOpPoint:AddContentPoint(self.pWidgetRef.ovlArrow, tbSelfObj:GetLocation())
            end
        elseif TeamWatchClientHelper.IsOtherTeamWatch() and self.nTeamMode and self.nTeamMode > 1 then
            self.pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility_Collapsed)
        else
            local pViewerActor = self:GetCurrentViewerActor()
            if pViewerActor then
                self.nSelfId = self.MapOpObj:AddContentPoint(pViewerActor, self.pWidgetRef.ovlArrow, false)
            end
        end
        self.pWidgetRef.ovlArrow:SetRenderTransformAngle(0)
    else
        local pViewerActor = self:GetCurrentViewerActor()
        if pViewerActor then
            self.nSelfId = self.MapOpObj:AddContentPoint(pViewerActor, self.pWidgetRef.ovlArrow, true)
        end
    end
    UISetUtils.SetImageBrushRes(imgSelfIcon, szIcon:load())
    if pLinearColor then
        imgSelfIcon:SetColorAndOpacity(pLinearColor)
    end 
end

local function OnTeamMode(self, tbPacket)
    self.nTeamMode = tbPacket.nTeamModeId
    RefreshSelfData(self)
end

function MapOpSelf:Init(Parent)
    MapOpSelf.super.Init(self, Parent)
    self.MapOpPoint = ExtendBlueprintFunctions.CreateObject(UIMapOpPoint, GameplayStatics.GetGameInstance(GWorld))
    self.MapOpPoint:InitParam(self.pWidgetRef, 0, 0, 0)
    local MapOpSelfObj = self:GetOpObj(UIMapOpPointWithActor)
    self.nTeamMode = BattleTeammateSystem:GetTeamMode()
    local pWidgetRef = self.pWidgetRef
    MapOpSelfObj:InitParam(self.pWidgetRef, 1)
    pWidgetRef:RegisterOperation(MapOpSelfObj)
    pWidgetRef:RegisterOperation(self.MapOpPoint)
    self.pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    RefreshSelfData(self)
end

function MapOpSelf:Uninit()
    MapOpSelf.super.Uninit(self)
end

function MapOpSelf:Reinit()
    MapOpSelf.super.Reinit(self)
    self.nTeamMode = BattleTeammateSystem:GetTeamMode()
    if self.MapOpPoint then
        self.MapOpPoint:SetEnable(true)
    end
    self.pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    RefreshSelfData(self)
end

function MapOpSelf:Close()
    MapOpSelf.super.Close(self)
    if self.MapOpPoint then
        self.MapOpPoint:SetEnable(false)
    end
end

function MapOpSelf:BindEvent()
    MapOpSelf.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MODE_INFO, self, OnTeamMode)
end


return MapOpSelf
