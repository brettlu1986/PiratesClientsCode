-----------------------------------------------------
--File Name    : ULPartnerAvatar.lua
--Author       : Song Fuhao
--Create Time  : 2/28/2019, 2:43:34 PM
--Description  : ULPartnerAvatar
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULPartnerAvatar = luaclass("ULPartnerAvatar", UILogicBase)

local L10N = require("L10N")
local StringUtil = require("StringUtil")
local RenderActor = require("RenderActor")
local RenderTargetType = require("RenderTargetType")
local RenderTargetManager = require("RenderTargetManager")

ULPartnerAvatar.imgModel = nil
ULPartnerAvatar.szModelRes = nil
ULPartnerAvatar.tbModelLocationOffset = nil
ULPartnerAvatar.tbModelRotationOffset = nil
ULPartnerAvatar.tbRenderActor = nil
ULPartnerAvatar.tbRenderTarget = nil
ULPartnerAvatar.pRawTransform = nil
ULPartnerAvatar.bInDragging = false

local function SetRenderActorLocation(self, nX, nY, nZ)
    local pRenderTargetActor = self.tbRenderTarget.RenderTargetActor
    local pLocation = KismetMathLibrary.TransformLocation(self.pRawTransform, Vector{X=nX, Y=nY, Z=nZ})
    pRenderTargetActor:K2_SetActorLocation(pLocation)
    if self.pWidgetRef.editLocationOffset then
        self.pWidgetRef.editLocationOffset:SetText(string.format("%.0f,%.0f,%.0f", nX, nY, nZ))
    end
end

local function SetRenderActorRotation(self, nPitch, nYaw, nRoll)
    local pRenderActor = self.tbRenderActor.pUEActor
    pRenderActor:K2_SetActorRotation(Rotator{Pitch = nPitch, Yaw = nYaw, Roll = nRoll})
    if self.pWidgetRef.editRotationOffset then
        self.pWidgetRef.editRotationOffset:SetText(string.format("%.0f,%.0f,%.0f", nPitch, nYaw, nRoll))
    end
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
        if self.tbRenderActor.pUEActor then
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

local function OnRenderActorLoaded(self)
    if self.tbRenderActor.pAvatarComponent then
        self.tbRenderActor.pAvatarComponent:SetMergeSkeletalMesh(false)
    end
    self.imgModel:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.tbRenderTarget:BindShowActor(self.imgModel, self.tbRenderActor)
    self.pRawTransform = self.tbRenderActor.pUEActor:GetTransform()

    self.tbRenderActor.pUEActor.CharacterMovement.GravityScale = 0
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
    self.tbRenderActor = RenderTargetManager:TryGetActor(self.tbRenderTarget, RenderActor.ActorType.Human, self.imgModel, self.szModelRes, nil, nil, nil, nil, true)
    -- local pLightMap = RenderTargetManager.tbLightMaps[RenderTargetType.Human]
    self.pTransform = KismetMathLibrary.MakeTransform(self.tbRenderTarget.RenderTargetActor:K2_GetActorLocation(), Rotator(), Vector{X=1,Y=1,Z=1})
    self.imgModel:SetVisibility(ESlateVisibility.Collapsed)
    if self.tbRenderActor.pUEActor then
        OnRenderActorLoaded(self)
    else
        self.tbRenderActor:LoadCompleteDelegate(OnRenderActorLoaded, self)
    end
    self.tbRenderTarget.RenderTargetActor.SceneCaptureComponent2D.FOVAngle = 25
end

function ULPartnerAvatar:OnExit()
    self:ClearAvatar()
end

function ULPartnerAvatar:SetModelWidget(imgModel)
    self.imgModel = imgModel
end

function ULPartnerAvatar:SetModel(szModelRes, tbModelLocationOffset, tbModelRotationOffset)
    if szModelRes ~= self.szModelRes then
        self.szModelRes = szModelRes
        self.tbModelLocationOffset = tbModelLocationOffset
        self.tbModelRotationOffset = tbModelRotationOffset or {0,0,0}
        UpdateRenderActor(self)
    end
end

function ULPartnerAvatar:ClearAvatar()
    self.szModelRes = nil
    if self.tbRenderActor then
        self.tbRenderActor:Destroy()
        self.tbRenderActor = nil
    end
    if self.tbRenderTarget then
        self.tbRenderTarget:Destroy()
        self.tbRenderTarget = nil
    end
end

function ULPartnerAvatar:OnBindEvent(EventHelper)
    if self.pWidgetRef.editLocationOffset then
        EventHelper:RegisterCppDelegate(self.pWidgetRef.editLocationOffset.OnTextCommitted, self, OnLocationOffsetTextCommitted)
    end
    if self.pWidgetRef.editRotationOffset then
        EventHelper:RegisterCppDelegate(self.pWidgetRef.editRotationOffset.OnTextCommitted, self, OnRotationOffsetTextCommitted)
    end
    if self.pWidgetRef.bdrActorListener then
        EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseButtonDownEvent, self, OnMouseButtonDown)
        EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseMoveEvent, self, OnMouseMove)
        EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseButtonUpEvent, self, OnMouseButtonUp)
    end
end

return ULPartnerAvatar