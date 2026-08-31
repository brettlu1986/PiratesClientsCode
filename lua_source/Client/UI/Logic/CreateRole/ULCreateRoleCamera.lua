-----------------------------------------------------
--File Name    : ULCreateRoleCamera.lua
--Author       : WuJizhou
--Create Time  : 7/23/2020, 8:39:05 PM
--Description  : ULCreateRoleCamera
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULCreateRoleCamera = luaclass("ULCreateRoleCamera", UILogicBase)

local ClientEventDef                = require("ClientEventDef")
local CreateRoleUIDef               = require("CreateRoleUIDef")
local DefaultAppearanceDataTable    = require("DefaultAppearanceDataTable")

local SlotType = CreateRoleUIDef.SlotType

local tbCameraConfig = {}
tbCameraConfig[SlotType.Hair] = "Cha_Closeup"
tbCameraConfig[SlotType.Face] = "Cha_Closeup"
tbCameraConfig[SlotType.HairColor] = "Cha_Closeup"
tbCameraConfig[SlotType.SkinColor] = "Cha_Overall"
tbCameraConfig[SlotType.Costume] = "Cha_Overall"

ULCreateRoleCamera.tbCamera = nil
ULCreateRoleCamera.pStreamingLevel = nil

local function UseCamera(self, nSlotType, bBlend)
    local pCameraActor = self.tbCamera[nSlotType]
    local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    if bBlend then
        pController:SetViewTargetWithBlend(pCameraActor, 0.5, EViewTargetBlendFunction.VTBlend_Linear, 10, true)
    else
        pController:SetViewTargetWithBlend(pCameraActor, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
    end
end

local function OnAppearanceSelected(self, nAppearanceId)
    local tbData = DefaultAppearanceDataTable:GetData(nAppearanceId)
    local nSlotType = tbData.nType
    UseCamera(self, nSlotType, true)
end

local function LoadCamera(self)
    local tbCamera = self.tbCamera
    if not tbCamera then
        tbCamera = {}
        self.tbCamera = tbCamera
    end
    for _, nSlotType in pairs(SlotType) do
        local szCameraTag = tbCameraConfig[nSlotType]
        local pCameraActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, szCameraTag)
        tbCamera[nSlotType] = pCameraActor
    end
end

function ULCreateRoleCamera:OnGenderChanged()
    UseCamera(self, SlotType.Costume, true)
end

----------life cycle----------
-- function ULCreateRoleCamera:OnCreate()
-- end

-- function ULCreateRoleCamera:OnDestroy()
-- end

function ULCreateRoleCamera:OnLoad()
    self.pStreamingLevel = self.Owner.tbOpenArgs.pStreamingLevel
    LoadCamera(self)
    UseCamera(self, SlotType.Costume, false)
end

function ULCreateRoleCamera:OnUnload()
    self.tbCamera = nil
    self.pStreamingLevel = nil
end

-- function ULCreateRoleCamera:OnEnter()
-- end

-- function ULCreateRoleCamera:OnShow()
-- end

-- function ULCreateRoleCamera:OnHide()
-- end

-- function ULCreateRoleCamera:OnExit()
-- end

function ULCreateRoleCamera:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEFAULT_APPEARANCE_SELECTED, self, OnAppearanceSelected)
end

-- function ULCreateRoleCamera:OnUnbindEvent(EventHelper)
-- end

return ULCreateRoleCamera