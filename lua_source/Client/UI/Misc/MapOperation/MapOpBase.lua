-----------------------------------------------------
--File Name    : MapOpBase.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : RadarContentBase
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = luaclass("MapOpBase")

local MapObjType = require("MapObjType")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfEventHelper = require("SelfEventHelper")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")

MapOpBase.Parent = nil
MapOpBase.pWidgetRef = nil
MapOpBase.EventHelper = nil
MapOpBase.PrefabHelper = nil
MapOpBase.tbObjPool = nil
MapOpBase.SelfObj = nil
MapOpBase.ViewerObj = nil             -- 战斗副本中当前使用的视角所对应的玩家[一定是友方]
MapOpBase.MapOpObj = nil
MapOpBase.WidgetHelper = nil
MapOpBase.bMMap = nil
MapOpBase.ParentCanvas = nil
MapOpBase.nObjCount = 0
MapOpBase.bOpen = nil

function MapOpBase:Init(Parent, ...)
    self.tbObjPool = {}
    self.nObjCount = 0
    self.Parent = Parent
    self.pWidgetRef = Parent.pWidgetRef
    if not self.EventHelper then
        self.EventHelper = SelfEventHelper()
    else
        self.EventHelper:UnregisterAll()
    end
    self.PrefabHelper = Parent.PrefabHelper
    self.WidgetHelper = Parent.WidgetHelper
    self.SelfObj = GamePlayerSelfHelper:Get()
    self.ViewerObj = self.Parent.ViewerObj

    if Parent.IsMMap and Parent.IsMMap() then
        self.bMMap = true
    end
    self.bOpen = true
end

function MapOpBase:Close()
    self.EventHelper:UnregisterAll()
    if self.MapOpObj then
        self.MapOpObj:SetEnable(false)
        -- for _, v in pairs(self.tbObjPool) do
        --     for _, ObjScript in pairs(v) do
        --         ObjScript:SetUseState(false)
        --     end
        -- end
    end
    self.bOpen = false
end

function MapOpBase:Open()
    self.bOpen = true
    self:Reinit()
    self:BindEvent()
end

function MapOpBase:Uninit()
    self.bOpen = false
    self.EventHelper:UnregisterAll()
    self.MapOpObj = nil
    
    for _, v in pairs(self.tbObjPool) do
        for _, ObjScript in pairs(v) do
            if self.pWidgetRef.cvsMapContent then
                self.pWidgetRef.cvsMapContent:RemoveChild(ObjScript.pWidgetRef)
            end
            if self.pWidgetRef.cvsPanel then
                self.pWidgetRef.cvsPanel:RemoveChild(ObjScript.pWidgetRef)
            end
            if self.ParentCanvas then
                self.ParentCanvas:RemoveChild(ObjScript.pWidgetRef)
            end
            self.PrefabHelper:UnbindPrefab(ObjScript)
        end
    end
   
    self.tbObjPool = nil
    
end

function MapOpBase:Reinit()
    self.ViewerObj = self.Parent.ViewerObj
    self.SelfObj = GamePlayerSelfHelper:Get()
    if self.MapOpObj then
        self.MapOpObj:SetEnable(true)
    end
end

function MapOpBase:BindEvent()
    
end

function MapOpBase:GetOpObj(pClass)
    local MapOpObj = self.MapOpObj
    if(MapOpObj == nil)then
        MapOpObj = ExtendBlueprintFunctions.CreateObject(pClass,GameplayStatics.GetGameInstance(GWorld))
        self.MapOpObj = MapOpObj
    end
    return MapOpObj
end

function MapOpBase:GetOneObj(nObjType, bOrientation, nZOrder, ParentCanvas)
    nZOrder = nZOrder == nil and 10 or nZOrder
    local tbObj = self.tbObjPool[nObjType]
    --logdebug("MapOpBase:GetOneObj", nObjType,tbObj)
    if(tbObj ~= nil)then
        for _, v in pairs(tbObj) do
            if(v:GetUseState() == false)then
                v.pWidgetRef.Slot:SetZOrder(nZOrder)
                --logdebug("MapOpBase:GetOneObj", nObjType)
                return v
            end
        end
    end
    local ObjScriptIns = self:CreateOneObj(nObjType, bOrientation, nZOrder, ParentCanvas)
    if(tbObj == nil)then
        tbObj = {}
        self.tbObjPool[nObjType] = tbObj
    end 
    table.insert(tbObj, ObjScriptIns)
    return ObjScriptIns
end

function MapOpBase:CreateOneObj(nObjType, bOrientation, nZOrder, ParentCanvas)
    --local pbContentObj
    local szPrefabName = MapObjType:GetPrefabByType(nObjType, self.bMMap)
    --logdebug("CreateOneObj:nObjType=",nObjType)
    --local tbPrefabTemplate = PrefabDataTable:GetTemplate(szPrefabName)
    local pbContentObj, _ = self.PrefabHelper:CreatePrefab( szPrefabName )
    
    -- local pWidgetRef = UIManager:CreateUMG(tbPrefabTemplate.szUIPath)
    -- local pbContentObj = nil
    -- if pWidgetRef and self.bMMap then
    --     self.nObjCount = self.nObjCount + 1
    --     --logdebug("CreateOneObj,",self.nObjCount, self)
    --     pbContentObj = self.PrefabHelper:BindPrefab( pWidgetRef, szPrefabName )
    -- else
    --     pbContentObj = self.PrefabHelper:CreatePrefab(szPrefabName)
    -- end
    
    --pbContentObj:SetOwner(self.Parent)
    local ObjWidget = pbContentObj.pWidgetRef
    if self.bMMap and ObjWidget.imgIcon and pbContentObj.OnClickedImgIcon then
        local Helper = pbContentObj.EventHelper
        Helper:RegisterCppDelegate(ObjWidget.imgIcon.OnMouseButtonDownEvent, pbContentObj, pbContentObj.OnClickedImgIcon)
    end
    
    if ParentCanvas then
        ParentCanvas:AddChildToCanvas(ObjWidget)
        self.ParentCanvas = ParentCanvas
    else
        if bOrientation then
            self.pWidgetRef.cvsPanel:AddChildToCanvas(ObjWidget)
        else
            self.pWidgetRef.cvsMapContent:AddChildToCanvas(ObjWidget)
        end
    end
    ObjWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
    local ObjWidgetSlot = ObjWidget.Slot
    ObjWidgetSlot:SetZOrder(nZOrder)
    ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
    ObjWidgetSlot:SetAutoSize(true)
    return pbContentObj
end

function MapOpBase:ResetObjPool(nObjType)
    local tbCurrentPool = self.tbObjPool[nObjType]
    if tbCurrentPool then
        for _, v in ipairs(tbCurrentPool) do
            if v:GetUseState() then
                v:HideContent()
            end
        end
    end
end

function MapOpBase:CalculateUIMapLocation(Location)
    local Parent = self.Parent
    local MapOrigin = Parent.MapOrigin
    local UIMapValidSize = Parent.UIMapValidSize
    local tbMapResData = Parent.tbMapResData
    local nUIX = (Location.X - MapOrigin.X) * UIMapValidSize.X / tbMapResData.nMapSizeX + Parent.UIMapValidOffset.X
    local nUIY = (Location.Y - MapOrigin.Y) * UIMapValidSize.Y / tbMapResData.nMapSizeY + Parent.UIMapValidOffset.Y
    return nUIX, nUIY
end

function MapOpBase:CalculateUISize(nSceneSizeX, nSceneSizeY)
    local Parent = self.Parent
    local tbMapResData = Parent.tbMapResData
    local nUIRealMapSizeX = Parent.UIMapValidSize.X + 2 * Parent.UIMapValidOffset.X
    local nUIRealMapSizeY = Parent.UIMapValidSize.Y + 2 * Parent.UIMapValidOffset.Y
    local nUISizeX = nSceneSizeX / tbMapResData.nMapSizeX * nUIRealMapSizeX
    local nUISizeY = nSceneSizeY / tbMapResData.nMapSizeY * nUIRealMapSizeY 
    return nUISizeX, nUISizeY
end

function MapOpBase:CalculateSceneSize(nUISizeX, nUISizeY)
    local Parent = self.Parent
    local tbMapResData = Parent.tbMapResData
    local nUIRealMapSizeX = Parent.UIMapValidSize.X + 2 * Parent.UIMapValidOffset.X
    local nUIRealMapSizeY = Parent.UIMapValidSize.Y + 2 * Parent.UIMapValidOffset.Y
    local nSceneSizeX = nUISizeX / nUIRealMapSizeX * tbMapResData.nMapSizeX
    local nSceneSizeY = nUISizeY / nUIRealMapSizeY * tbMapResData.nMapSizeY
    return nSceneSizeX, nSceneSizeY
end

function MapOpBase:SetWorldPointInUI(pWidget, WorldPos)
    local UIPosX, UIPosY = self:CalculateUIMapLocation(WorldPos)
    pWidget.Slot:SetPosition(Vector2D{X = UIPosX, Y = UIPosY})
end

function MapOpBase:GetCurrentViewerObj()
    local ViewerObj = self.ViewerObj
    if not ViewerObj then
        ViewerObj = self.SelfObj
    end
    return ViewerObj
end

function MapOpBase:GetCurrentViewerActor()
    local ViewerObj = self:GetCurrentViewerObj()
    if ViewerObj then
        return ViewerObj:GetModelActor()
    end
    return nil
end

function MapOpBase:GetSelfShipWorldPos()
    local SelfActor = self:GetCurrentViewerActor()
    if(SelfActor == nil)then
        return
    end
    return SelfActor:K2_GetActorLocation()
end

function MapOpBase:TryMirrorMap()
    local CurrentControlMode = ControlModeSystem:GetCurrentModeType()
    local bMirror = false
    if CurrentControlMode == ControlModeDef.TRANSPORT then
        bMirror = true
    end
    if self.MapOpObj then
        self.MapOpObj:SetMirror(bMirror)
    end
    return bMirror
end

function MapOpBase:Refresh()
end


return MapOpBase
