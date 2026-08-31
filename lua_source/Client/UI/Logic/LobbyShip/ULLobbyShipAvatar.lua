-----------------------------------------------------
--File Name    : ULLobbyShipAvatar.lua
--Author       : Song Fuhao
--Create Time  : 2/28/2019, 2:43:34 PM
--Description  : ULLobbyShipAvatar
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipAvatar = luaclass("ULLobbyShipAvatar", UILogicBase)

local L10N = require("L10N")
local StringUtil = require("StringUtil")
local RenderActor = require("RenderActor")
local RenderTargetType = require("RenderTargetType")
local RenderTargetManager = require("RenderTargetManager")

ULLobbyShipAvatar.imgModel = nil
ULLobbyShipAvatar.szModelRes = nil
ULLobbyShipAvatar.tbModelLocationOffset = nil
ULLobbyShipAvatar.tbModelRotationOffset = nil
ULLobbyShipAvatar.tbRenderActor = nil
ULLobbyShipAvatar.tbRenderTarget = nil
ULLobbyShipAvatar.pRawTransform = nil
ULLobbyShipAvatar.bInDragging = false
ULLobbyShipAvatar.bVisible = true

local function SetRenderActorLocation(self, nX, nY, nZ)
    local pRenderActor = self.tbRenderActor.pUEActor
    local pLocation = KismetMathLibrary.TransformLocation(self.pRawTransform, Vector{X=nX, Y=nY, Z=nZ})
    pRenderActor:K2_SetActorLocation(pLocation)
    self.pWidgetRef.editLocationOffset:SetText(string.format("%.0f,%.0f,%.0f", nX, nY, nZ))
end

local function SetRenderActorRotation(self, nPitch, nYaw, nRoll)
    local pRenderActor = self.tbRenderActor.pUEActor
    pRenderActor:K2_SetActorRotation(Rotator{Pitch = nPitch, Yaw = nYaw, Roll = nRoll})
    self.pWidgetRef.editRotationOffset:SetText(string.format("%.0f,%.0f,%.0f", nPitch, nYaw, nRoll))
end

local function OnLocationOffsetTextCommitted(self, l10nText)
    local tbIntParams = {}
    local tbStringParams = StringUtil.Split(L10N:ToString(l10nText), ",")
    for i, v in ipairs(tbStringParams) do
        tbIntParams[i] = tonumber(v)
    end
    SetRenderActorLocation(self, table.unpack(tbIntParams))
end

local function OnRotationOffsetTextCommitted(self, l10nText)
    local tbIntParams = {}
    local tbStringParams = StringUtil.Split(L10N:ToString(l10nText), ",")
    for i, v in ipairs(tbStringParams) do
        tbIntParams[i] = tonumber(v)
    end
    SetRenderActorRotation(self, table.unpack(tbIntParams))
end

local function OnMouseButtonDown(self)
    self.bInDragging = true
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, _, pMouseEvent)
    if self.bInDragging then
        local pMoveDelta = KismetInputLibrary.PointerEvent_GetCursorDelta(pMouseEvent)
        if self.tbRenderActor and self.tbRenderActor.pUEActor then
            local pRotation = self.tbRenderActor.pUEActor:K2_GetActorRotation()
            SetRenderActorRotation(self, pRotation.Pitch, pRotation.Yaw - pMoveDelta.X, pRotation.Roll)
        end
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self)
    self.bInDragging = false
    return WidgetBlueprintLibrary.Handled()
end

local function OnShipLoaded(self)
    self.tbRenderActor:UpdateShipAvatar(nil, -1, self.tbShipResTemplate)
    if self.bVisible then
        self:SetVisible(self.bVisible)
    end
    self.tbRenderTarget:BindShowActor(self.imgModel, self.tbRenderActor)
    self.pRawTransform = self.tbRenderActor.pUEActor:GetTransform()

    self.tbRenderTarget.RenderTargetActor:K2_SetActorRotation(Rotator{Pitch = 0, Yaw = 180, Roll = 0})

    SetRenderActorLocation(self, self.tbModelLocationOffset[1],
                                 self.tbModelLocationOffset[2],
                                 self.tbModelLocationOffset[3])
    SetRenderActorRotation(self, self.tbModelRotationOffset[1],
                                 self.tbModelRotationOffset[2],
                                 self.tbModelRotationOffset[3])
end

local function UpdateRenderActor(self)
    if not self.tbRenderTarget then
        self.tbRenderTarget = RenderTargetManager:TryGetRenderTarget(RenderTargetType.Human)
    end
    if self.tbRenderActor then
        self.tbRenderActor:Destroy()
        self.tbRenderActor = nil
    end
    self.tbRenderActor = RenderTargetManager:TryGetActor(self.tbRenderTarget, RenderActor.ActorType.Ship, self.imgModel, self.szModelRes, nil, nil, nil, nil, true)
    self.imgModel:SetVisibility(ESlateVisibility.Collapsed)
    if self.tbRenderActor.pUEActor then
        OnShipLoaded(self)
    else
        self.tbRenderActor:LoadCompleteDelegate(OnShipLoaded, self)
    end
    self.tbRenderTarget.RenderTargetActor.SceneCaptureComponent2D.FOVAngle = 25
end

function ULLobbyShipAvatar:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.editLocationOffset.OnTextCommitted, self, OnLocationOffsetTextCommitted)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.editRotationOffset.OnTextCommitted, self, OnRotationOffsetTextCommitted)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

function ULLobbyShipAvatar:OnExit()
    self:ClearAvatar()
end

function ULLobbyShipAvatar:SetModelWidget(imgModel)
    self.imgModel = imgModel
end

function ULLobbyShipAvatar:SetShipResTemplate(tbShipResTemplate)
    if tbShipResTemplate ~= self.SetShipResTemplate then
        self.tbShipResTemplate = tbShipResTemplate
        self.szModelRes = tbShipResTemplate.szPawnClassName
        self.tbModelLocationOffset = tbShipResTemplate.tbModelLocationOffset
        self.tbModelRotationOffset = tbShipResTemplate.tbModelRotationOffset
        UpdateRenderActor(self)
    end
end

function ULLobbyShipAvatar:ClearAvatar()
    if self.tbRenderActor then
        self.tbRenderActor:Destroy()
        self.tbRenderActor = nil
    end
    if self.tbRenderTarget then
        self.tbRenderTarget:Destroy()
        self.tbRenderTarget = nil
    end
end

function ULLobbyShipAvatar:SetVisible(bVisible)
    self.bVisible = bVisible
    if bVisible then
        self.pWidgetRef.imgModel:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.imgModel:SetVisibility(ESlateVisibility.Collapsed)
    end
end

return ULLobbyShipAvatar