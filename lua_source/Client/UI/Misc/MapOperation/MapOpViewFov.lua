-----------------------------------------------------
--File Name    : MapOpViewFov.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : MapOpViewFov
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpViewFov = luaclass("MapOpViewFov",MapOpBase)

local VIEW_RANGE = 330 --目前没有可是范围的变化，暂时固定一个值，纯ui表现

function MapOpViewFov:Init(Parent)
    MapOpViewFov.super.Init(self,Parent)
    local MapOpFovObj = self:GetOpObj(UIMapCameraFov)
    local kmpgbsViewFov = self.pWidgetRef.kmpgbsViewFov
    kmpgbsViewFov:SetVisibility(ESlateVisibility.HitTestInvisible)
    --view Range
    local nUIViewRange = VIEW_RANGE --Parent.UIViewSize.X / Parent.tbMapResData.nScope * nViewRange * 2
    kmpgbsViewFov.Slot:SetSize(Vector2D{X = nUIViewRange, Y = nUIViewRange})
    --fov
    MapOpFovObj:InitParam(90, kmpgbsViewFov)
    self:TryMirrorMap()
    self.pWidgetRef:RegisterOperation(MapOpFovObj)
end


function MapOpViewFov:Uninit()
    MapOpViewFov.super.Uninit(self)
end

function MapOpViewFov:Reinit()
    MapOpViewFov.super.Reinit(self)
    self:TryMirrorMap()
end

return MapOpViewFov
