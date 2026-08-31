-----------------------------------------------------
--File Name    : ULLobbyShipDisplay.lua
--Author       : Song Fuhao
--Create Time  : 2019-12-02
--Description  : ULLobbyShipDisplay
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipDisplay = luaclass("ULLobbyShipDisplay", UILogicBase)

local UIDef                             = require("UIDef")
local ClientEventDef                    = require("ClientEventDef")
local UIManager                         = require("UIManager")
local ResourceManager                   = require("ResourceManager")
local UEMapLoader                       = require("UEMapLoader")
local GameAvatarHelper                  = require("GameAvatarHelper")
local DisplayAwardItemIni               = require("DisplayAwardItemIni")

local FORM_RES_TAG_LIST                 = DisplayAwardItemIni.tbShipDisplay.tbShipFoamsTags
local FOAM_RES_LIST                     = DisplayAwardItemIni.tbShipDisplay.tbShipFoamsRes
local PERSISTENT_FOAM_RES               = DisplayAwardItemIni.tbShipDisplay.szSeaFoamRes
local SHIP_AVATAR_COMPONENT_RES         = DisplayAwardItemIni.tbShipDisplay.szShipAvatarComponent
local DISPLAY_LEVEL_RES                 = DisplayAwardItemIni.tbShipDisplay.szLevelRes
local CAMERA_ACTOR_TAG                  = DisplayAwardItemIni.tbShipDisplay.szCameraTag
local SHIP_ACTOR_TAG                    = DisplayAwardItemIni.tbShipDisplay.szActorTag
local SHIP_ENTER_ANIM_RES               = DisplayAwardItemIni.tbShipDisplay.szShipAnim
local ENV_CTRL_TAG                      = "EnvControl04"
local SHIP_PARAM_TAG                    = "ShipParam"
local ZERO_VECTOR                       = Vector()
local ZERO_ROTATOR                      = Rotator()
local FOAM_FX_BASE_SCALE                = 1.22 -- 因为这个特效是按雪虎号做的，所以按雪虎号ShipBaseScale进行缩放
local SPAWN_PERSISTENT_FOAM_START_TIME  = 1.5
local SET_ACTOR_LOCATION_TIME           = 0.1
local SWITCH_SAIL_START_TIME            = 1
local ENTER_ANIM_TIME                   = 3
local MODEL_BASE_SCALE                  = 1

ULLobbyShipDisplay.tbShipResTemplate    = nil
ULLobbyShipDisplay.pLevelActor          = nil
ULLobbyShipDisplay.pShipActor           = nil
ULLobbyShipDisplay.tbFoamFxs            = nil
ULLobbyShipDisplay.bEnterAnimFinished   = false
ULLobbyShipDisplay.bHideShip            = false

--[[
    Debug逻辑
]]
local L10N = require("L10N")
ULLobbyShipDisplay.nCurrentModelScale = 1
ULLobbyShipDisplay.bDebugEventBinded = false

local function OnClickedDebugClose(self)
    self.pWidgetRef.bdrDebug:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnClickedDebugPlayEnterAnim(self)
    self.pWidgetRef.chkDebugCloseAnim:SetIsChecked(false)
    self:SetShipResTemplate(self.tbShipResTemplate)
end

local function OnDebugXTextCommitted(self, l10nText)
    local nXDelta = tonumber(L10N:ToString(l10nText))
    local pPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, SHIP_ACTOR_TAG)
    local pLocation = EngineExtActorShell.GetActorLocation(pPosActor)
    local pShipLocation = EngineExtActorShell.GetActorLocation(self.pShipActor)
    pShipLocation.X = pLocation.X + nXDelta
    EngineExtActorShell.SetActorLocation(self.pShipActor, pShipLocation)
end

local function OnDebugYTextCommitted(self, l10nText)
    local nYDelta = tonumber(L10N:ToString(l10nText))
    local pPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, SHIP_ACTOR_TAG)
    local pLocation = EngineExtActorShell.GetActorLocation(pPosActor)
    local pShipLocation = EngineExtActorShell.GetActorLocation(self.pShipActor)
    pShipLocation.Y = pLocation.Y + nYDelta
    EngineExtActorShell.SetActorLocation(self.pShipActor, pShipLocation)
end

local function OnDebugYawTextCommitted(self, l10nText)
    local nYawDelta = tonumber(L10N:ToString(l10nText))
    local pPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, SHIP_ACTOR_TAG)
    local pRotation = EngineExtActorShell.GetActorRotation(pPosActor)
    pRotation.Yaw = pRotation.Yaw + nYawDelta
    EngineExtActorShell.SetActorRotation(self.pShipActor, pRotation)
end

local function OnDebugModelScaleTextCommitted(self, l10nText)
    self.nCurrentModelScale = tonumber(L10N:ToString(l10nText))
    local nFinalScale = MODEL_BASE_SCALE * self.nCurrentModelScale
    EngineExtActorShell.SetActorScale(self.pShipActor, nFinalScale)
end

local function OnDebugUIScaleTextCommitted(self, l10nText)
    MODEL_BASE_SCALE = tonumber(L10N:ToString(l10nText))
    local nFinalScale = MODEL_BASE_SCALE * self.nCurrentModelScale
    EngineExtActorShell.SetActorScale(self.pShipActor, nFinalScale)
end

local function UpdateDebugPanelInfo(self)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef.bdrDebug:IsVisible() then
        return
    end

    local tbShipResTemplate = self.tbShipResTemplate
    self.nCurrentModelScale =  tbShipResTemplate.nModelScale
    pWidgetRef.editDebugX:SetText(tbShipResTemplate.tbModelLocationOffset[1])
    pWidgetRef.editDebugY:SetText(tbShipResTemplate.tbModelLocationOffset[2])
    pWidgetRef.editDebugYaw:SetText(tbShipResTemplate.tbModelRotationOffset[2])
    pWidgetRef.editDebugModelScale:SetText(self.nCurrentModelScale)
    pWidgetRef.editDebugUIScale:SetText(MODEL_BASE_SCALE)
end

local function UpdateDebugYaw(self, nYaw)
    local pPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, SHIP_ACTOR_TAG)
    local pRotation = EngineExtActorShell.GetActorRotation(pPosActor)
    local nYawDelta = KismetMathLibrary.NormalizeAxis(nYaw - pRotation.Yaw)
    self.pWidgetRef.editDebugYaw:SetText(math.ceil(nYawDelta))
end

local function BindDebugEvent(self)
    if self.bDebugEventBinded then
        return
    end
    self.bDebugEventBinded = true
    local EventHelper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDebugClose.OnClicked, self, OnClickedDebugClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDebugPlayEnterAnim.OnClicked, self, OnClickedDebugPlayEnterAnim)
    EventHelper:RegisterCppDelegate(pWidgetRef.editDebugX.OnTextCommitted, self, OnDebugXTextCommitted)
    EventHelper:RegisterCppDelegate(pWidgetRef.editDebugY.OnTextCommitted, self, OnDebugYTextCommitted)
    EventHelper:RegisterCppDelegate(pWidgetRef.editDebugYaw.OnTextCommitted, self, OnDebugYawTextCommitted)
    EventHelper:RegisterCppDelegate(pWidgetRef.editDebugModelScale.OnTextCommitted, self, OnDebugModelScaleTextCommitted)
    EventHelper:RegisterCppDelegate(pWidgetRef.editDebugUIScale.OnTextCommitted, self, OnDebugUIScaleTextCommitted)
end

function ULLobbyShipDisplay:EnableDebug()
    self.pWidgetRef.bdrDebug:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    BindDebugEvent(self)
    UpdateDebugPanelInfo(self)
end
--------------------------------------------------------------------------------------------------------

-- 设置场景参数
local function SetEnvironmentControl(self, bEnabled)
    local pEnvControl = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, ENV_CTRL_TAG)
    if pEnvControl then
        if bEnabled then
            pEnvControl:SetEnvironment()
        else
            pEnvControl:RevertEnvironment()
        end
    end
    local pShipParam = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, SHIP_PARAM_TAG)
    if pShipParam then
        pShipParam:SetEnable(bEnabled)
    end
end

-- 通过Tag从Level中获取对应Actor的Location和Rotation
local function GetActorLocationAndRotationByTag(self, szTag)
    local pPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, szTag)
    if not pPosActor then
        logerror("Cannot find actor! actor tag is " .. szTag)
        return nil, nil
    end
    return pPosActor:K2_GetActorLocation(), pPosActor:K2_GetActorRotation()
end

-- 生成舰船出水泡沫粒子
local function SpawnFoamEffect(self)
    self.tbFoamFxs = {}
    local nFxScale = self.pShipActor.ShipBaseScale / FOAM_FX_BASE_SCALE
    for i, szFxRes in ipairs(FOAM_RES_LIST) do
        local pLocation, pRotation = GetActorLocationAndRotationByTag(self, FORM_RES_TAG_LIST[i])
        pLocation.X = pLocation.X + self.tbShipResTemplate.tbModelLocationOffset[1]
        pLocation.Y = pLocation.Y + self.tbShipResTemplate.tbModelLocationOffset[2]
        local pFoamFx = ExtendBlueprintFunctions.SpawnEmitterAtLocationEx(GWorld,       -- const UObject* WorldContextObject
                                                          szFxRes:load(),               -- UParticleSystem* EmitterTemplate
                                                          pLocation,                    -- FVector Location
                                                          pRotation,                    -- FRotator Rotation = FRotator::ZeroRotator
                                                          ZERO_VECTOR,                  -- FVector Scale = FVector(1.f)
                                                          true,                         -- bool bAutoDestroy = true
                                                          nFxScale,                     -- float CustomScale = 1.f
                                                          EPSCPoolMethod.None,          -- EPSCPoolMethod PoolingMethod = EPSCPoolMethod::None
                                                          false)                        -- bool bManageSignificance = false
        table.insert(self.tbFoamFxs, pFoamFx)
    end
end

-- 生成舰船水面持续泡沫粒子
local function SpawnPersistentFoamEffect(self)
    local pShipActor = self.pShipActor
    local pSprayLoc = Vector{Z=pShipActor.Flotage.RelativeLocation.Z + pShipActor.WaterLine.RelativeLocation.Z}   
    local pFxRes = PERSISTENT_FOAM_RES:load()
    ExtendBlueprintFunctions.SpawnEmitterAttachedEx(pFxRes,                             -- UParticleSystem* EmitterTemplate
                                                    pShipActor.RootComponent,           -- USceneComponent* AttachToComponent
                                                    "",                                 -- FName AttachPointName = NAME_None
                                                    pSprayLoc,                          -- FVector Location = FVector(ForceInit)
                                                    ZERO_ROTATOR,                       -- FRotator Rotation = FRotator::ZeroRotator
                                                    ZERO_VECTOR,                        -- FVector Scale = FVector(1.f)
                                                    EAttachLocation.KeepRelativeOffset, -- EAttachLocation::Type LocationType = EAttachLocation::KeepRelativeOffset
                                                    true,                               -- bool bAutoDestroy = true
                                                    pShipActor.ShipBaseScale,           -- float CustomScale = 1.f
                                                    EPSCPoolMethod.None,                -- EPSCPoolMethod PoolingMethod = EPSCPoolMethod::None
                                                    false)                              -- bool bManageSignificance = false
end

local function SettleShipTransform(self)
    local pShipActor = self.pShipActor
    local tbShipResTemplate = self.tbShipResTemplate
    local pLocation, pRotation = GetActorLocationAndRotationByTag(self, SHIP_ACTOR_TAG)
    pLocation.X = pLocation.X + tbShipResTemplate.tbModelLocationOffset[1]
    pLocation.Y = pLocation.Y + tbShipResTemplate.tbModelLocationOffset[2]
    pRotation.Yaw = pRotation.Yaw + tbShipResTemplate.tbModelRotationOffset[2]
    local nScale = MODEL_BASE_SCALE * tbShipResTemplate.nModelScale
    EngineExtActorShell.SetActorLocation(pShipActor, pLocation)
    EngineExtActorShell.SetActorRotation(pShipActor, pRotation)
    EngineExtActorShell.SetActorScale(pShipActor, nScale)
end

-- 播放舰船入场动画
local function PlayEnterAnim(self)
    if self.pWidgetRef.chkDebugCloseAnim:IsChecked() then
        self.bEnterAnimFinished = true
        return
    end

    local pShipActor = self.pShipActor

    -- 初始化船动画相关状态
    pShipActor:SetActiveBlend(true)
    pShipActor:SetPosture(EShipPosture.Reef)

    -- 播放船出水Montage
    local pShipAnim = SHIP_ENTER_ANIM_RES:load()
    pShipActor.SKM_ShipMaster:GetAnimInstance():Montage_Play(pShipAnim, 1.0, EMontagePlayReturnType.MontageLength, 0.0, false)

    -- 生成舰船出水泡沫粒子
    SpawnFoamEffect(self)

    -- 生成舰船水面持续泡沫粒子
    self.TimerHelper:NewDelayRunTimer(function()
        SpawnPersistentFoamEffect(self)
    end, SPAWN_PERSISTENT_FOAM_START_TIME)

    -- 切船帆状态
    self.TimerHelper:NewDelayRunTimer(function() 
        pShipActor:SetPosture(EShipPosture.FullSail)
    end, SWITCH_SAIL_START_TIME)
    
    -- 设置船在地图中位置及朝向
    self.TimerHelper:NewDelayRunTimer(function()
        SettleShipTransform(self)
    end, SET_ACTOR_LOCATION_TIME)

    -- 更新入场动画是否播放完成状态
    self.bEnterAnimFinished = false
    self.TimerHelper:NewDelayRunTimer(function() 
        self.bEnterAnimFinished = true
    end, ENTER_ANIM_TIME)
end

local function DestroyShipActor(self)
    if self.pShipActor then
        self.pShipActor:K2_DestroyActor()
        self.pShipActor = nil
    end
    if self.tbFoamFxs then
        for _, pFoamFx in ipairs(self.tbFoamFxs) do
            if isvalidhandle(pFoamFx) then
                ExtendBlueprintFunctions.DestroyEmitter(pFoamFx)
            end
        end
        self.tbFoamFxs = nil
    end
    self.TimerHelper:ClearAllTimer()
end

local function CreateShipActor(self)
    -- 必须要设置了船ResTemplate，且地图加载完，才执行创建逻辑
    if not (self.tbShipResTemplate and self.pLevelActor) then
        return
    end

    -- 创建船
    local tbShipResTemplate = self.tbShipResTemplate
    local pModelClass = tbShipResTemplate.szModelClassName:load()
    local pShipActor = EngineExtActorShell.SpawnActorForScript(GWorld, pModelClass, Transform(), nil)
    self.pShipActor = pShipActor
    
    -- 打开船的浮力系统
    local pFlotage = pShipActor.Flotage
    if pFlotage then
		pFlotage.bAlwaysUpdate = true
        pFlotage.ApplyTransform = true
    end
    
    -- 将船设置到OceanSystem中
    local tbOceanSystems = GameplayStatics.GetAllActorsOfClass(GWorld, OceanSystem)
    local pOceanSystem = tbOceanSystems[1]
    if pOceanSystem then
        pOceanSystem:SetPlayerMyself(pShipActor)
    end
    
    -- SkeletalMesh相关设置
	EngineExtActorShell.SetActorSkeletalMeshMipMap(pShipActor, true)
    EngineExtActorShell.SetActorSkeletalMeshLightChannel(pShipActor, false, true, false)
    
    -- 设置舰船皮肤
    local pShipAvatarComponent = EngineExtActorShell.CreateActorComponent(pShipActor, SHIP_AVATAR_COMPONENT_RES:load())
    pShipAvatarComponent:Init(nil, pShipActor, 0)
    GameAvatarHelper:UpdateShipAvatar(pShipAvatarComponent, nil, -1, tbShipResTemplate)

    -- 道具获得展示界面下，不显示
    if self.bHideShip then
        SettleShipTransform(self)
        pShipActor:SetActorHiddenInGame(true)
    else
        PlayEnterAnim(self)
    end

    UpdateDebugPanelInfo(self)
end

-- 通过切换当前相机控制Level显隐
local function SetLevelVisible(self, bVisible)
    local PlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    if PlayerController then
        if bVisible then
            self.pLastViewTarget = PlayerController:GetViewTarget()
            local pViewTarget = ExtendBlueprintFunctions.GetLevelActorByTag(self.pLevelActor, CAMERA_ACTOR_TAG)
            PlayerController:SetViewTargetWithBlend(pViewTarget, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
        elseif self.pLastViewTarget then
            PlayerController:SetViewTargetWithBlend(self.pLastViewTarget, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
            self.pLastViewTarget = nil
        end
    end
end

local function OnPostLoadMap(self)
    self.EventHelper:UnregisterCppDelegate(self.pLevelLoadedDelegate)
    self.pLevelLoadedDelegate = nil

    SetEnvironmentControl(self, true)
    SetLevelVisible(self, true)
    CreateShipActor(self)
end

-- 隐藏其他UI
local function HideOtherUI(self)
    self.tbCurrentOpenWndList = {}
    local tbOpenWndList = UIManager:GetOpenWndList()
    for szWndName, _ in pairs(tbOpenWndList) do
        local Wnd = UIManager:GetWnd(szWndName)
        if Wnd and Wnd:IsVisible() then
            Wnd:SetVisible(false)
            table.insert(self.tbCurrentOpenWndList, szWndName)
        end
    end
end

-- 显示隐藏的UI
local function ShowHiddenUI(self)
    if self.tbCurrentOpenWndList then
        for _, szWndName in pairs(self.tbCurrentOpenWndList) do
            local Wnd = UIManager:GetWnd(szWndName)
            if Wnd then
                Wnd:SetVisible(true)
            end
        end
        self.tbCurrentOpenWndList = nil
    end
end

local function OnMouseButtonDown(self)
    self.bInDragging = true
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, _, pMouseEvent)
    if self.bInDragging and self.pShipActor and self.bEnterAnimFinished then
        local pMoveDelta = KismetInputLibrary.PointerEvent_GetCursorDelta(pMouseEvent)
        local pRotation = EngineExtActorShell.GetActorRotation(self.pShipActor)
        pRotation.Yaw = pRotation.Yaw - pMoveDelta.X
        EngineExtActorShell.SetActorRotation(self.pShipActor, pRotation)
        UpdateDebugYaw(self, pRotation.Yaw)
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self)
    self.bInDragging = false
    return WidgetBlueprintLibrary.Handled()
end

function ULLobbyShipDisplay:OnLoad()
    self.nLoadResourceAsyncHandler = ResourceManager:LoadAsync(DISPLAY_LEVEL_RES, function()
        self.nLoadResourceAsyncHandler = nil
        self.pLevelActor = UEMapLoader:LoadSubLevelSync(DISPLAY_LEVEL_RES)
        if self.pLevelActor:IsLevelLoaded() then
            OnPostLoadMap(self)
        else
            self.pLevelLoadedDelegate = self.EventHelper:RegisterCppDelegate(self.pLevelActor.OnLevelShown, self, OnPostLoadMap)
        end
    end)
end

function ULLobbyShipDisplay:OnUnload()
    UEMapLoader:UnLoadSubLevel(DISPLAY_LEVEL_RES)
end

function ULLobbyShipDisplay:OnEnter()
    HideOtherUI(self)
    -- 打开场景渲染
    --ClientShell.GetClient(GWorld):ToggleSceneRendering(true)
    LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
    self.pWidgetRef:PlayAnimation(self.pWidgetRef.animEnter, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function ULLobbyShipDisplay:OnExit()
    ShowHiddenUI(self)
    SetLevelVisible(self, false)
    SetEnvironmentControl(self, false)
    DestroyShipActor(self)
    -- 关闭场景渲染
    --ClientShell.GetClient(GWorld):ToggleSceneRendering(false)
    LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(false)
end

local function OnOpenUI(self, szWndName)
    if szWndName == UIDef.UI_LOBBY_DISPLAY_AWARD_ITEM then
        if self.pShipActor then
            self.bHideShip = true
            self.pShipActor:SetActorHiddenInGame(true)
            SetEnvironmentControl(self, false)
        end
    end
end

local function OnPreCloseUI(self, szWndName)
    if szWndName == UIDef.UI_LOBBY_DISPLAY_AWARD_ITEM then
        if self.pShipActor then
            self.bHideShip = false
            self.pShipActor:SetActorHiddenInGame(false)
            SetEnvironmentControl(self, true)
        end
    end
end

function ULLobbyShipDisplay:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrActorListener.OnMouseButtonUpEvent, self, OnMouseButtonUp)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_OPEN_UI, self, OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnPreCloseUI)
end

function ULLobbyShipDisplay:SetShipResTemplate(tbShipResTemplate)
    self.tbShipResTemplate = tbShipResTemplate
    DestroyShipActor(self)
    CreateShipActor(self)
end

return ULLobbyShipDisplay
