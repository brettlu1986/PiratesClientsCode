-----------------------------------------------------
--File Name    : MapOpFFAPoisonCircle.lua
--Author       : Ran Jie
--Create Time  : 2018-9-12
--Description  : MapOpFFAPoisonCircle
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFAPoisonCircle = luaclass("MapOpFFAPoisonCircle",MapOpBase)

local PoisonCircleSystem = require("PoisonCircleSystem")
local UISetUtils = require("UISetUtils")


local COLLAPSED = ESlateVisibility.Collapsed

local function InitPoisonProgress(self)
    self.pWidgetRef.txtSafeDistance:SetVisibility(COLLAPSED)
    self.pWidgetRef.pgbPoison:SetPercent(0)
end

function MapOpFFAPoisonCircle:Init(Parent)
    MapOpFFAPoisonCircle.super.Init(self,Parent)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbFFASafeCircle:SetVisibility(COLLAPSED)
    pWidgetRef.kmFFAPoisonCircle:SetVisibility(COLLAPSED)
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpFFAPoisonCircle:Init,ViewerActor is nil")
        return
    end
    local MapOpFFAObj = self:GetOpObj(UIMapOpPoisonCircle)
    MapOpFFAObj:InitParam(pViewerActor, pWidgetRef, pWidgetRef.pbFFASafeCircle, pWidgetRef.kmFFAPoisonCircle)
    --self:TryMirrorMap()
    pWidgetRef:RegisterOperation(MapOpFFAObj)
    
    PoisonCircleSystem:AddMapOp(MapOpFFAObj)
    if not self.bMMap then
        InitPoisonProgress(self)
        local l10FomatText = UISetUtils.GetTextByKey("FFA_FLAG_DISTANCE")
        self.MapOpObj:SetPoisonProgress(pWidgetRef.txtSafeDistance, pWidgetRef.pgbPoison, pWidgetRef.imgSelfPos, l10FomatText)
    end
    
end


function MapOpFFAPoisonCircle:Uninit()
    PoisonCircleSystem:RemoveMapOp(self.MapOpObj)
    MapOpFFAPoisonCircle.super.Uninit(self)
end

function MapOpFFAPoisonCircle:Reinit()
    MapOpFFAPoisonCircle.super.Reinit(self)
    if self.MapOpObj then
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpFFAPoisonCircle:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(pViewerActor, self.pWidgetRef, self.pWidgetRef.pbFFASafeCircle, self.pWidgetRef.kmFFAPoisonCircle)
    end
    --self:TryMirrorMap()
end

return MapOpFFAPoisonCircle
