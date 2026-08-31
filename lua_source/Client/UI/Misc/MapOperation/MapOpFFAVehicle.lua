-----------------------------------------------------
--File Name    : MapOpFFAVehicle.lua
--Author       : Ran Jie
--Description  : 最近载具显示
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFAVehicle = luaclass("MapOpFFAVehicle",MapOpBase)


local MapObjType = require("MapObjType")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamHeadNameSystem = require("TeamHeadNameSystem")
local DCProto = require("DungeonCommonProtoNames")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local CommonEventDef = require("CommonEventDef")
local MiniMapSystem = require("MiniMapSystem")
local UIResourceDef = require("UIResourceDef")
local ControlModeDef = require("ControlModeDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")

local pLastVehicleLocation = Vector()

MapOpFFAVehicle.nVehicleId = nil
MapOpFFAVehicle.nVehicleUniqueId = nil
MapOpFFAVehicle.tbMapObj = nil
MapOpFFAVehicle.MapOpPoint = nil

local function ShowMapObj(self)
    local tbObj = self.tbMapObj
    local tbData = nil
    if tbObj then
        tbData = tbObj.tbData
    else
        tbObj = self:GetOneObj(MapObjType.OTHER, false, 9)
        self.tbMapObj = tbObj
    end
    if not tbData then
        tbData = {}
        --tbData.bMatchSize = true
        tbData.UISize = {X = 50, Y = 50}
        tbData.szIcon = UIResourceDef.LAST_USED_VEHICLE
    end
    tbObj:ShowContent(tbData)
    return tbObj, tbData
end

local function HideMapObj(self)
    local tbObj = self.tbMapObj
    if tbObj and tbObj.tbData then
        local tbData = tbObj.tbData
        tbData.bTeammateDrive = false
        tbData.pUEActor = nil
        tbObj:HideContent()
    end
    if self.nVehicleUniqueId then
        self.MapOpObj:RemoveContentPoint(self.nVehicleUniqueId)
        self.MapOpPoint:RemoveContentPoint(self.nVehicleUniqueId)
        self.nVehicleUniqueId = nil
    end
end

local function RefreshMemberObjPos(self)
    local SelfObj = GamePlayerSelfHelper:Get()
    local SelfInstanceId = SelfObj:GetServerInstanceId()

    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
    if not tbTeamInfo then
        return
    end
    local nVehicleId = MiniMapSystem:GetLastVehicleId()
    if not nVehicleId then
        return
    end
    local tbObj, tbData = ShowMapObj(self)
    local bTeammateDrive = false
    for k, v in ipairs(tbTeamInfo) do
        local nInstanceId = v.nInstanceId
        if nInstanceId == SelfInstanceId then
            if v.nVehicleId ~= 0 then
                --self.nVehicleId = v.nVehicleId
                if v.nState == DCProto.TeamInfo_EState.DRIVING then
                    HideMapObj(self)
                    return
                --else
                    --ShowMapObj(self)
                    -- tbData.bTeammateDrive = false
                    -- tbData.pUEActor = nil
                    -- if self.nVehicleUniqueId then
                    --     self.MapOpObj:RemoveContentPoint(self.nVehicleUniqueId)
                    --     self.MapOpPoint:RemoveContentPoint(self.nVehicleUniqueId)
                    -- end
                    -- logdebug("show contentpoint")
                    -- self.nVehicleUniqueId = self.MapOpPoint:AddContentPoint(self.tbMapObj.pWidgetRef, MiniMapSystem:GetLastVehicleLocation())
                end
            else
                --self.nVehicleId = nil
                HideMapObj(self)
                return
            end
        else
            local tbMemberHeadNameData = TeamHeadNameSystem:GetMemberObjByInstanceId(nInstanceId)
            if tbMemberHeadNameData then
                local ObjWidgetRef = tbObj.pWidgetRef
                local pUEActor = nil
                if tbMemberHeadNameData.tbGameObject then
                    pUEActor = tbMemberHeadNameData.tbGameObject.pUEActor
                else
                    pUEActor = tbMemberHeadNameData.tbDummyObject.pUEActor
                end
                if pUEActor then
                    if v.nState == DCProto.TeamInfo_EState.DRIVING and nVehicleId == v.nVehicleId then
                        bTeammateDrive = true
                        if not tbData.pUEActor or pUEActor ~= tbData.pUEActor then
                            tbData.bTeammateDrive = true
                            tbData.pUEActor = pUEActor
                            tbData.nInstanceId = nInstanceId
                            if self.nVehicleUniqueId then
                                self.MapOpObj:RemoveContentPoint(self.nVehicleUniqueId)
                                self.MapOpPoint:RemoveContentPoint(self.nVehicleUniqueId)
                            end
                            self.nVehicleUniqueId = self.MapOpObj:AddContentPoint(pUEActor, ObjWidgetRef, false)
                            return
                        end
                    end
                end 
            end
        end
    end
    
    if tbData.pUEActor and tbData.bTeammateDrive and not bTeammateDrive then
        --logdebug("队友下马")
        local pLocation = tbData.pUEActor:K2_GetActorLocation()
        MiniMapSystem:SetLastVehicleLocation(pLocation.X, pLocation.Y)
        tbData.bTeammateDrive = false
        tbData.pUEActor = nil
        tbData.nInstanceId = nil

        if self.nVehicleUniqueId then
            self.MapOpObj:RemoveContentPoint(self.nVehicleUniqueId)
            self.MapOpPoint:RemoveContentPoint(self.nVehicleUniqueId)
        end
        local tbLastVehicleLocation = MiniMapSystem:GetLastVehicleLocation()
        if tbLastVehicleLocation then
            pLastVehicleLocation.X = tbLastVehicleLocation.X
            pLastVehicleLocation.Y = tbLastVehicleLocation.Y
            self.nVehicleUniqueId = self.MapOpPoint:AddContentPoint(self.tbMapObj.pWidgetRef, pLastVehicleLocation)
        end
    --elseif not bTeammateDrive then

    end
    

    
end

local function OnMemberHeadNameObjChanged(self, nInstanceId, tbGameObject)
    local tbMapObj = self.tbMapObj
    if tbMapObj then
        local tbData = tbMapObj.tbData
        if tbData and self.nVehicleUniqueId and tbData.nInstanceId == nInstanceId and tbData.bTeammateDrive then
            self.MapOpObj:RemoveContentPoint(self.nVehicleUniqueId)
            tbData.pUEActor = tbGameObject.pUEActor
            local ObjWidgetRef = tbMapObj.pWidgetRef
            self.nVehicleUniqueId = self.MapOpObj:AddContentPoint(tbData.pUEActor, ObjWidgetRef, false)
        end
    end
end

local function OnVehicleStateChange(self, Player, nState, nVehicleId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nLastVehicleId = MiniMapSystem:GetLastVehicleId()
    if Player:GetServerInstanceId() == PlayerSelf:GetServerInstanceId() then
        --logdebug("OnVehicleStateChange:nState=",nState,nVehicleId,MiniMapSystem:GetLastVehicleId())
        if nState == HumanVehicleStateDef.AttachToVehicle then
            local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
            --self.nVehicleId = HumanMovementStateComponent:GetVehicleInstanceId()  
            MiniMapSystem:SetLastVehicleId(HumanMovementStateComponent:GetVehicleInstanceId())
            --logdebug("OnVehicleStateChange:AttachToVehicle")
            HideMapObj(self)
        elseif nState == HumanVehicleStateDef.None and nLastVehicleId then
            --logdebug("OnVehicleStateChange:DetachFromVehicle")
            local _, tbData = ShowMapObj(self, PlayerSelf:GetLocation())
            tbData.bTeammateDrive = false
            tbData.pUEActor = nil
            if self.nVehicleUniqueId then
                self.MapOpObj:RemoveContentPoint(self.nVehicleUniqueId)
                self.MapOpPoint:RemoveContentPoint(self.nVehicleUniqueId)
            end
            
            if nLastVehicleId == nVehicleId then
                local pLocation = PlayerSelf:GetLocation()
                MiniMapSystem:SetLastVehicleLocation(pLocation.X, pLocation.Y)
                
                
            end
            local tbLastVehicleLocation = MiniMapSystem:GetLastVehicleLocation()
            --logdebug("tbLastVehicleLocation=",tbLastVehicleLocation)
            if tbLastVehicleLocation then
                pLastVehicleLocation.X = tbLastVehicleLocation.X
                pLastVehicleLocation.Y = tbLastVehicleLocation.Y
                self.nVehicleUniqueId = self.MapOpPoint:AddContentPoint(self.tbMapObj.pWidgetRef, pLastVehicleLocation)
            end
        end
    end 
end

local function OnControlModeDeactive(self, nControlMode)
    if nControlMode == ControlModeDef.HUMAN then
        local PlayerSelf = GamePlayerSelfHelper:Get()
        local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
        if HumanMovementStateComponent and HumanMovementStateComponent:GetVehicleState() == HumanVehicleStateDef.AttachToVehicle then
            
            OnVehicleStateChange(self, PlayerSelf, HumanVehicleStateDef.None, nil)
        end
    end
end

function MapOpFFAVehicle:Refresh()
    
end

function MapOpFFAVehicle:Init(Parent)
    MapOpFFAVehicle.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPointWithActor)
    self.MapOpObj:InitParam(self.pWidgetRef, 1)
    self.pWidgetRef:RegisterOperation(MapOpObj)

    self.MapOpPoint = ExtendBlueprintFunctions.CreateObject(UIMapOpPoint, GameplayStatics.GetGameInstance(GWorld))
    self.MapOpPoint:InitParam(self.pWidgetRef, 0, 0, 0)
    --self.MapOpPoint:SetEnable(false)
    self.pWidgetRef:RegisterOperation(self.MapOpPoint)
    
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent then
        --logdebug("1HumanMovementStateComponent:GetVehicleInstanceId()=",HumanMovementStateComponent:GetVehicleInstanceId())
        local nVehicleInstanceId = HumanMovementStateComponent:GetVehicleInstanceId()
        if HumanMovementStateComponent:GetVehicleState() == HumanVehicleStateDef.None then
            nVehicleInstanceId = 0
        end
        OnVehicleStateChange(self, PlayerSelf, HumanMovementStateComponent:GetVehicleState(), nVehicleInstanceId)
    else
        OnVehicleStateChange(self, PlayerSelf, HumanVehicleStateDef.None, nil)
    end
    RefreshMemberObjPos(self)
end

function MapOpFFAVehicle:Uninit()
    MapOpFFAVehicle.super.Uninit(self)
end

function MapOpFFAVehicle:Reinit()
    MapOpFFAVehicle.super.Reinit(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent then
        --logdebug("2HumanMovementStateComponent:GetVehicleInstanceId()=",HumanMovementStateComponent:GetVehicleInstanceId())
        local nVehicleInstanceId = HumanMovementStateComponent:GetVehicleInstanceId()
        if HumanMovementStateComponent:GetVehicleState() == HumanVehicleStateDef.None then
            nVehicleInstanceId = 0
        end
        OnVehicleStateChange(self, PlayerSelf, HumanMovementStateComponent:GetVehicleState(), nVehicleInstanceId)
    else
        OnVehicleStateChange(self, PlayerSelf, HumanVehicleStateDef.None, nil)
    end
    RefreshMemberObjPos(self)
    
end

function MapOpFFAVehicle:BindEvent()
    MapOpFFAVehicle.super.BindEvent(self)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_UPDATED, self, RefreshMemberObjPos)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, self, OnMemberHeadNameObjChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, self, OnControlModeDeactive)
end

return MapOpFFAVehicle