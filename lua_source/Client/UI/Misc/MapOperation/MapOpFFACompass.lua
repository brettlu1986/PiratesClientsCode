-----------------------------------------------------
--File Name    : MapOpFFACompass.lua
--Author       : Ran Jie
--Create Time  : 2018-9-12
--Description  : MapOpFFACompass 方向罗盘
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFACompass = luaclass("MapOpFFACompass", MapOpBase)

local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local DCProto = require("DungeonCommonProtoNames")
local MapObjType = require("MapObjType")


local ROTATION_START = Rotator {
    Pitch = 180.0,
    Roll = 180.0,
    Yaw = 180.0
} 
local PIXEL_PER_ANGEL = 6.58

local CRITICAL_DEGREE_OFFSET = 75  --角度临界点的上下偏移范围，现在角度临界点是玩家的正东方向标记点
local ANCHOR_TOP_CENTER = Anchors{Minimum=Vector2D{X=0.5, Y=0}, Maximum=Vector2D{X=0.5, Y=0}}
local ALIGNMENT_X_CENTER = Vector2D{X = 0.5, Y = 0}
local POINT_SIZE = Vector2D{X = 28, Y = 38}

MapOpFFACompass.tbPlayerFlagPoint = {}


local function OnFlagInfoUpdated(self, tbFlagPoints)
    if not self.MapOpObj then
        return
    end
    local l10FomatText = UISetUtils.GetTextByKey("FFA_FLAG_DISTANCE")
    local ParentCanvas = self.pWidgetRef.cvsCompass
    for k, v in pairs(tbFlagPoints) do
        local nInstanceId = k
        local tbData = self.tbPlayerFlagPoint[nInstanceId]
        if v.SignType == DCProto.ESignType.SIGN then
            if not tbData then
                tbData = {}
                tbData.Obj = self:GetOneObj(MapObjType.FFA_FLAG_POINT,false, 10, ParentCanvas)
                local ObjWidgetSlot = tbData.Obj.pWidgetRef.Slot
                ObjWidgetSlot:SetAlignment(ALIGNMENT_X_CENTER)
                ObjWidgetSlot:SetAnchors(ANCHOR_TOP_CENTER)
                ObjWidgetSlot:SetAutoSize(false)
                ObjWidgetSlot:SetSize(POINT_SIZE)
                self.tbPlayerFlagPoint[nInstanceId] = tbData
            end
            if tbData.X ~= v.nSignX or tbData.Y ~= v.nSignY or tbData.SignType ~= DCProto.ESignType.SIGN then
                tbData.nIndex = v.nIndex
                tbData.SignType = v.SignType
                tbData.X = v.nSignX
                tbData.Y = v.nSignY
                tbData.Obj:ShowContent(tbData)
                local pObjWidgetRef = tbData.Obj.pWidgetRef
                tbData.nPointIndex = self.MapOpObj:AddFlagPoint(pObjWidgetRef, pObjWidgetRef.txtDistance, l10FomatText, Vector{X = tbData.X, Y = tbData.Y, Z = 0})
            end
        elseif tbData and tbData.SignType == DCProto.ESignType.SIGN then
            tbData.SignType = v.SignType
            tbData.Obj:HideContent(tbData)
            self.MapOpObj:RemoveFlagPoint(tbData.nPointIndex)
        end
    end
end


function MapOpFFACompass:Init(Parent)
    MapOpFFACompass.super.Init(self, Parent)
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpFFACompass:Init,ViewerActor is nil")
        return
    end
    local MapOpFFAObj = self:GetOpObj(UIMapOpCompass)
    local pWidgetRef = self.pWidgetRef
    
    
    MapOpFFAObj:InitParam(pViewerActor, pWidgetRef, pWidgetRef.cvsCompass, PIXEL_PER_ANGEL, ROTATION_START, CRITICAL_DEGREE_OFFSET)
    self.pWidgetRef:RegisterOperation(MapOpFFAObj)
    --self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_FLAG_POINT_UPDATE, self, OnFlagInfoUpdated)
end


function MapOpFFACompass:Uninit()
    --logdebug("MapOpFFACompass:Uninit")
    MapOpFFACompass.super.Uninit(self)
    self.pWidgetRef:UnregisterAllOperation()
end

function MapOpFFACompass:Reinit()
    MapOpFFACompass.super.Reinit(self)
    if self.MapOpObj then
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpFFACompass:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(pViewerActor, self.pWidgetRef, self.pWidgetRef.cvsCompass, PIXEL_PER_ANGEL, ROTATION_START, CRITICAL_DEGREE_OFFSET)
    end
end

function MapOpFFACompass:BindEvent()
    MapOpFFACompass.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_FLAG_POINT_UPDATE, self, OnFlagInfoUpdated)
end

return MapOpFFACompass
