-----------------------------------------------------
--File Name    : MapOpFFAFlagLine.lua
--Author       : Ran Jie
--Create Time  : 2018-9-12
--Description  : MapOpFFAFlagLine(当前版本只有单人标记)
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFAFlagLine = luaclass("MapOpFFAFlagLine",MapOpBase)


local ClientEventDef = require("ClientEventDef")
local FlagMapLocationSystem = require("FlagMapLocationSystem")
--local UISetUtils = require("UISetUtils")
local MapObjType = require("MapObjType")
local DCProto = require("DungeonCommonProtoNames")
local UIResourceDef = require("UIResourceDef")
local CameraGameHelper = require("CameraGameHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIMapIni = require("UIMapIni")
local ControlModeDef = require("ControlModeDef")
local ControlModeSystem = require("ControlModeSystem")
local MiniMapSystem = require("MiniMapSystem")

local LAND_WEIGHT = UIMapIni.tbMMap.nLandWeight
local OCEAN_WEIGHT = UIMapIni.tbMMap.nOceanWeight

MapOpFFAFlagLine.tbMemberObjs = nil


local function OnFlagInfoUpdated(self, tbFlagPoints)
    --local l10FomatText = UISetUtils.GetTextByKey("FFA_FLAG_DISTANCE")
    if not self.MapOpObj then
        return
    end
    local nPointCount = 0
    for k, v in pairs(tbFlagPoints) do
        local nInstanceId = k
        local tbData = self.tbMemberObjs[nInstanceId]
        if v.SignType == DCProto.ESignType.SIGN then
            if not tbData or not tbData.Obj then
                if not tbData then
                    tbData = {}
                    self.tbMemberObjs[nInstanceId] = tbData
                end
                tbData.nInstanceId = nInstanceId
                tbData.Obj = self:GetOneObj(MapObjType.FFA_FLAG_INFO)
                tbData.Obj:SetMapOp(self.MapOpObj)
                tbData.Obj.MapOpScript = self
            end
            local UIX, UIY = self:CalculateUIMapLocation({X = v.nSignX, Y = v.nSignY})
            if tbData.X ~= v.nSignX or tbData.Y ~= v.nSignY or tbData.SignType ~= DCProto.ESignType.SIGN or tbData.UILocation.X ~= UIX or tbData.UILocation.Y ~= UIY then
                tbData.nIndex = v.nIndex
                tbData.SignType = v.SignType
                tbData.X = v.nSignX
                tbData.Y = v.nSignY
                tbData.UILocation = {X = UIX, Y = UIY}
                tbData.pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[tbData.nIndex]

                local bWatchBattle = CameraGameHelper.IsWatchBattleMode()
                if tbData.nInstanceId == GamePlayerSelfHelper:GetServerInstanceId() and not bWatchBattle then
                    tbData.bShowLine = true
                else
                    tbData.bShowLine = false
                end
                tbData.bShowPoint = true
                tbData.Obj:ShowContent(tbData)
            end
        elseif tbData and tbData.SignType == DCProto.ESignType.SIGN then
            tbData.SignType = v.SignType
            tbData.Obj:HideContent(tbData)
            tbData.Obj = nil
        end
        nPointCount = nPointCount + 1
    end
    if nPointCount == 0 then
        self:ResetObjPool(MapObjType.FFA_FLAG_INFO)
        self.tbMemberObjs = {}
    end
end

local function OnShowCoreArea(self)
    if self.MapOpObj then
        local nCurrentMode = ControlModeSystem:GetCurrentModeType()
        if nCurrentMode == ControlModeDef.TRANSPORTNEW then
            self.MapOpObj:SetTargetRegionVisible(false)
        else
            self.MapOpObj:SetTargetRegionVisible(true)
        end
    end
end

-- local function SetIsSwimming(self)
--     local HumanMovementStateComponent = GamePlayerSelfHelper:Get().HumanMovementStateComponent
--     if HumanMovementStateComponent ~= nil then
--         local nCurState = HumanMovementStateComponent:GetCurrentState()
--         if nCurState == HumanMovementStateType.Swimming then
--             self.MapOpObj:SetSelfIsSwimming(true)
--         else
--             self.MapOpObj:SetSelfIsSwimming(false)
--         end
--     end
-- end

-- local function OnHumanMovementStateChanged(self, tbPlayer, nLastState, nNewState)
--     if nLastState == nNewState then
--         return
--     end
--     if nNewState == HumanMovementStateType.Swimming then
--         self.MapOpObj:SetSelfIsSwimming(true)
--     else
--         self.MapOpObj:SetSelfIsSwimming(false)
--     end
-- end

function MapOpFFAFlagLine:Init(Parent)
    MapOpFFAFlagLine.super.Init(self, Parent)
    
    local pWidgetRef = self.pWidgetRef
    self.tbMemberObjs = {}
    --line
    
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpFFAFlagLine:Init,ViewerActor is nil")
        return
    end
    local MapOpFFAObj = self:GetOpObj(UIMapOpFlagPointLine)
    MapOpFFAObj:InitParam(pWidgetRef, pViewerActor, LAND_WEIGHT, OCEAN_WEIGHT, self:GetCurrentViewerObj():IsHuman(), MiniMapSystem:GetLandId())
    MapOpFFAObj:SetTickInterval(2)
    local nCurrentMode = ControlModeSystem:GetCurrentModeType()
    if nCurrentMode == ControlModeDef.TRANSPORTNEW then
        MapOpFFAObj:SetTargetRegionVisible(false)
        self.MapOpObj:SetSelfRegionVisible(false)
    else
        MapOpFFAObj:SetTargetRegionVisible(true)
        MapOpFFAObj:SetSelfRegionVisible(true)
    end
    --SetIsSwimming(self)
    self.pWidgetRef:RegisterOperation(MapOpFFAObj)

    --self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_FLAG_POINT_UPDATE, self, OnFlagInfoUpdated)
    OnFlagInfoUpdated(self, FlagMapLocationSystem:GetAllFlag())
end


function MapOpFFAFlagLine:Uninit()
    --logdebug("MapOpFFAFlagLine:Uninit")
    MapOpFFAFlagLine.super.Uninit(self)
end

function MapOpFFAFlagLine:Reinit()
    MapOpFFAFlagLine.super.Reinit(self)
    if self.MapOpObj then
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpFFAFlagLine:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(self.pWidgetRef, pViewerActor, LAND_WEIGHT, OCEAN_WEIGHT, self:GetCurrentViewerObj():IsHuman(), MiniMapSystem:GetLandId())
        local nCurrentMode = ControlModeSystem:GetCurrentModeType()
        if nCurrentMode == ControlModeDef.TRANSPORTNEW then
            self.MapOpObj:SetTargetRegionVisible(false)
            self.MapOpObj:SetSelfRegionVisible(false)
        else
            self.MapOpObj:SetTargetRegionVisible(true)
            self.MapOpObj:SetSelfRegionVisible(true)
        end
        --SetIsSwimming(self)
    end
    OnFlagInfoUpdated(self, FlagMapLocationSystem:GetAllFlag())
end

function MapOpFFAFlagLine:BindEvent()
    MapOpFFAFlagLine.super.BindEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_FLAG_POINT_UPDATE, self, OnFlagInfoUpdated)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_CORE_AREA, self, OnShowCoreArea)
    --EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChanged)
end


return MapOpFFAFlagLine
