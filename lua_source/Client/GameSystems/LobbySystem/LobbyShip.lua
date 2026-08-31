-----------------------------------------------------
--File Name    : LobbyShip.lua
--Author       : chenyixin
--Description  : 大厅舰船界面
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbyShip = luaclass("LobbyShip", LobbySubBase)

local LobbyShipDef = require("LobbyShipDef")
local LobbySubTypeDef = require("LobbySubTypeDef")
local ItemCategoryDef = require("ItemCategoryDef")
local ClientEventDef = require("ClientEventDef")
local DisplayAwardItemIni = require("DisplayAwardItemIni")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local ItemSourceDataTable = require("ItemSourceDataTable")
local ShopDataTable = require("ShopDataTable")

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ResourceManager = require("ResourceManager")
local GameAvatarHelper = require("GameAvatarHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local DisplayItemHelper = require("DisplayItemHelper")
local BlackScreenHelper = require("BlackScreenHelper")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local DelayTimer = require("DelayTimer")
local UIShipDataTable = require("UIShipDataTable")

local ItemSystem = require("ItemSystem")
local ShopSystem = require("ShopSystem")

local LobbyShipWndDef = LobbyShipDef.WndDef
local SOURCE_TYPE_DEFAULT_OWNED = 0
local SHIP_WEAPON_ACTOR_RES = "/Game/Game/ShipEx/BP_ShipWeapon.BP_ShipWeapon_C"

LobbyShip.tbDelayTimer = nil
LobbyShip.tbDelayShowShipTimer = nil
LobbyShip.ShipResHandler = nil

LobbyShip.tbActors = {}
LobbyShip.tbShipActorIds = {}
LobbyShip.tbRotateActors = {}
LobbyShip.tbOriginRotations = {}

-- 记录装配的船Id，-1为未解锁, 0为未装配
LobbyShip.tbEquippedShipIds = {}

LobbyShip.fnOpenShipOverview = nil
LobbyShip.szCurOpenWndKey = nil
LobbyShip.nCallerLobbySub = nil

LobbyShip.tbDisplayItemInfo = {}

LobbyShip.tbShowTipIconChecker = {
    ["Hull"] = function(self)
        local ShipPreparationComponent = self:GetShipPreparationComponent()
        if self:GetEmptyShipSlotCount() > 0 then
            if #ShipPreparationComponent:GetUnequippedShipTemplates() > 0 then
                return true
            end
        end
        return false
    end,

    ["Weapon"] = function(self)
        local ShipPreparationComponent = self:GetShipPreparationComponent()
        if ShipPreparationComponent:CheckCategoryHasNewShipItems(ItemCategoryDef.SHIP_WEAPON) then
            return true
        end
        return false
    end,

    ["Part"] = function(self)
        local ShipPreparationComponent = self:GetShipPreparationComponent()
        if ShipPreparationComponent:CheckCategoryHasNewShipItems(ItemCategoryDef.SHIP_PART) then
            return true
        end
        return false
    end,

    ["Handbook"] = function(self)
        local ShipPreparationComponent = self:GetShipPreparationComponent()
        if ShipPreparationComponent:CheckCategoryHasNewShipItems(ItemCategoryDef.SHIP) then
            return true
        end
        if ShipPreparationComponent:CheckCategoryHasNewShipItems(ItemCategoryDef.SHIP_SKIN) then
            return true
        end
        return false
    end,
}

-- 最大装配个数
local MAX_EQUIPPED_COUNT = 4
local MODEL_BASE_SCALE = 1
local DEFAULT_INDEX = 1

local ZERO_VECTOR = Vector()
local ZERO_ROTATOR = Rotator()
local pScaleVector = Vector()
local pLocationVector = Vector()
local pRotator = Rotator()

local function LOG(...)
    log("[LobbyShip]", ...)
end

local function ClearDelayTimer(self)
    if self.tbDelayTimer then
        self.tbDelayTimer:Clear()
        self.tbDelayTimer = nil
    end
end

local function ClearDelayShowShipTimer(self)
    if self.tbDelayShowShipTimer then
        self.tbDelayShowShipTimer:Clear()
        self.tbDelayShowShipTimer = nil
    end
end

local function ClearShipResHandler(self)
    if self.ShipResHandler then
        ResourceManager:CancelLoadAsync(self.ShipResHandler)
        self.ShipResHandler = nil
    end
end

local function SetActorLocationAndRotation(pActor, pLocation, pRotation, tbModify)
    if not isvalidhandle(pActor) then
        return
    end

    local nScale = MODEL_BASE_SCALE

    tbModify = tbModify and tbModify or {}

    if pLocation then
        if tbModify.tbLocation then
            pLocationVector.X = pLocation.X + tbModify.tbLocation.nX
            pLocationVector.Y = pLocation.Y + tbModify.tbLocation.nY
            pLocationVector.Z = pLocation.Z + tbModify.tbLocation.nZ
        else
            pLocationVector = pLocation
        end
        pActor:K2_SetActorRelativeLocation(pLocationVector, false, true)
    end

    if pRotation then
        if tbModify.tbRotation then
            pRotator.Pitch = pRotation.Pitch + tbModify.tbRotation.nPitch
            pRotator.Yaw = pRotation.Yaw + tbModify.tbRotation.nYaw
            pRotator.Roll = pRotation.Roll + tbModify.tbRotation.nRoll
        else
            pRotator = pRotation
        end
        pActor:K2_SetActorRelativeRotation(pRotator, false, true)
    end

    if tbModify.nScale then
        nScale = nScale * tbModify.nScale
    end
    pScaleVector.X = nScale
    pScaleVector.Y = nScale
    pScaleVector.Z = nScale
    pActor:SetActorScale3D(pScaleVector)
end

local function GetActorTagByActorIndex(self, nActorIndex)
    local szWndName = LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey]
    return self:GetActorTagByIndex(szWndName, nActorIndex)
end

local function GetActorTag(szWndName, nSubType, nActorIndex)
    nActorIndex = nActorIndex and nActorIndex or 1
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(nSubType, szWndName)
    if not tbSubLevelTemplate then
        logerror("[LobbyShip] SettleShipTransform cannot find tbsubleveltemplate", nSubType, szWndName)
        return 
    end
    local szActorTag = tbSubLevelTemplate.tbActorTag[nActorIndex]
    return szActorTag
end

local function OnPlayerSelfReady(self)
    self:LoadShipEquipmentInfo()
end

local function GetShipWndKey(szInWndName)
    for szKey, szWndName in pairs(LobbyShipWndDef.tbKeyToWndName) do
        if szWndName == szInWndName then
            return szKey
        end
    end
    return nil
end

local function SpawnShipActor(self, pModel, nIndex, szWndName, nSubType, pSubLevel, nShipId, tbShipResTemplate, tbModify)
    local pShipActor = self:CreateActor(pModel, nIndex)
    self.tbShipActorIds[nIndex] = nShipId

    local pRotateActor = self.tbRotateActors[nIndex]
    if not pRotateActor then
        local szActorTag = GetActorTag(szWndName, nSubType, nIndex)
        pRotateActor = ExtendBlueprintFunctions.GetLevelActorByTag(pSubLevel, szActorTag)
        self.tbRotateActors[nIndex] = pRotateActor
        self.tbOriginRotations[nIndex] = pRotateActor:K2_GetActorRotation()
    end
    pShipActor:K2_AttachToActor(pRotateActor, "", EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, false)
    
    if pShipActor and pShipActor.SKM_ShipMaster then
        pShipActor.SKM_ShipMaster:SetForcedLOD(1)
    end

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
    local tbActiveSub = self.Owner:GetActiveSub()
    if tbActiveSub.nSubType == LobbySubTypeDef.SHOW then
        pShipActor:SetActorHiddenInGame(true)
        ClearDelayShowShipTimer(self)
        self.tbDelayShowShipTimer = DelayTimer:DelayRun(function()
            EngineExtActorShell.SetActorSkeletalMeshMipMap(pShipActor, true)
            pShipActor:SetActorHiddenInGame(false)
        end, 0.35)
    else
        EngineExtActorShell.SetActorSkeletalMeshMipMap(pShipActor, true)
    end
    ExtendBlueprintFunctions.UpdateSkeletalComponentAnim(pShipActor.SKM_ShipMaster)
    
    -- 设置舰船皮肤
    local szShipAvatarComponent = DisplayAwardItemIni.tbShipDisplay.szShipAvatarComponent
    local pShipAvatarComponent = EngineExtActorShell.CreateActorComponent(pShipActor, szShipAvatarComponent:load())
    pShipAvatarComponent:Init(nil, pShipActor, 0)
    GameAvatarHelper:UpdateShipAvatar(pShipAvatarComponent, nil, -1, tbShipResTemplate)

    SetActorLocationAndRotation(pShipActor, ZERO_VECTOR, ZERO_ROTATOR, tbModify)
end

---------------------------------------------------------------

function LobbyShip:Init(Owner, nSubType)
    LobbyShip.super.Init(self, Owner, nSubType)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    return true
end

function LobbyShip:Uninit()
    LobbyShip.super.Uninit(self)
    ClearDelayTimer(self)
    ClearShipResHandler(self)
    self:DestroyAllShipActors()
end

function LobbyShip:Activate(tbParam)
    LobbyShip.super.Activate(self, tbParam)

    if UIManager:IsWndVisible(UIDef.UI_LOBBY_SHOP) then
        UIUtils.BottomMenuUnselectAll()
    end

    self:LoadShipEquipmentInfo()

    self.nCallerLobbySub = tbParam and tbParam.nCallerLobbySub
    local tbRestoreContext = self.tbRestoreContext
    self.tbDisplayItemInfo = tbRestoreContext and tbRestoreContext.tbDisplayItemInfo

    if tbParam and tbParam.szSourceWndName then
        self:OpenShipWnd(GetShipWndKey(tbParam.szSourceWndName), nil, tbParam.tbParams)
    elseif tbParam and tbParam.szKey then
        self:OpenShipWnd(tbParam.szKey, nil, tbParam.tbParams)
    elseif tbRestoreContext and tbRestoreContext.szCurOpenWndKey then
        self:UpdateDisplayItemInfo(tbRestoreContext.tbDisplayItemInfo)
        self:OpenShipWnd(tbRestoreContext.szCurOpenWndKey)
    else
        self:OpenShipWnd("Overview")
    end
end

function LobbyShip:Deactivate()
    LobbyShip.super.Deactivate(self)
    if self.szCurOpenWndKey then
        UIManager:CloseWnd(LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey])
    end
    ClearShipResHandler(self)
    ClearDelayShowShipTimer(self)
    self:DestroyAllShipActors()

    self.EventHelper:UnregisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY)
end

function LobbyShip:SetCameraWithBlend(szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
    self.SubLevelLoadHelper:SetCameraWithBlend(self.nSubType, szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
end

function LobbyShip:GetRestoreContext()
    local tbRestoreContext = {}
    tbRestoreContext.szCurOpenWndKey = self.szCurOpenWndKey
    tbRestoreContext.tbDisplayItemInfo = self.tbDisplayItemInfo
    return tbRestoreContext
end

function LobbyShip:UpdateDisplayItemInfo(tbDisplayItemInfo)
    self.tbDisplayItemInfo = tbDisplayItemInfo
end

function LobbyShip:ClearResumeData()
    self.tbRestoreContext = nil
end

-------------------------------------------------------------------------------

function LobbyShip:SetActorLocationAndRotationByIndex(pActor, nActorIndex, tbModify)
    local szWndName = LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey]
    local szActorTag = GetActorTagByActorIndex(self, nActorIndex)

    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, szWndName, szActorTag)

    if pLocation.X == 0 and pLocation.Y == 0 and pLocation.Z == 0 then
        self.tbDelayTimer = DelayTimer:DelayRun(function()
            -- 第一次进入SubLevel时船的位置Actor还没有UpdateComponent，返回位置是(0,0,0)，等一下再设置位置
            ClearDelayTimer(self)
            pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, szWndName, szActorTag)
            SetActorLocationAndRotation(pActor, pLocation, pRotation, tbModify)
        end, 0.2)
    else
        SetActorLocationAndRotation(pActor, pLocation, pRotation, tbModify)
    end
end

-- 生成Actor
function LobbyShip:CreateActor(pModelClass, nIndex)

    nIndex = nIndex and nIndex or DEFAULT_INDEX

    if self.tbActors[nIndex] then
        self:DestroyShipActorByIndex(nIndex)
    end

    local pActor = EngineExtActorShell.SpawnActorForScript(GWorld, pModelClass, Transform(), nil)
    self.tbActors[nIndex] = pActor

    local szWndName = LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey]
    self:SetActorSkeletalMeshLightChannel(szWndName, pActor)

    return pActor
end

-- 生成ShipActor
function LobbyShip:CreateShipActorById(nShipId, nIndex, tbModify, szWndName)
    if not nShipId or nShipId <= 0 then
        LOG("CreateShipActorById", nShipId)
        return
    end

    local tbShipResTemplate = DisplayItemHelper.GetShipResTemplate(nShipId)
    if not tbShipResTemplate then
        LOG("CreateShipActorById tbShipResTemplate is nil")
        return
    end

    if not szWndName then
        szWndName = LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey]
    end
    local nSubType = self.Owner:GetActiveSub().nSubType
    
    local pSubLevel = self.SubLevelLoadHelper:GetSubLevel(nSubType, szWndName)
    if not pSubLevel or not pSubLevel:IsLevelLoaded() then
        LOG("CreateShipActorById pSubLevel is not loaded")
        return
    end

    nIndex = nIndex and nIndex or 1

    if self.tbShipActorIds[nIndex] and self.tbShipActorIds[nIndex] == nShipId then
        LOG("CreateShipActorById current id, in id is", self.tbShipActorIds[nIndex], nShipId)
        return
    end
    
    -- 创建船
    local szModel = tbShipResTemplate.szModelClassName
    local fnLoadShipEnd = function(szAssetName, pModel, nHaldler)
        if not pModel then
            logerror("[LobbyShip] Cannot load model:", szModel)
            return 
        end
        if self.ShipResHandler then
            self.ShipResHandler = nil
        end
        SpawnShipActor(self, pModel, nIndex, szWndName, nSubType, pSubLevel, nShipId, tbShipResTemplate, tbModify)
    end
    
    ClearShipResHandler(self)
    self.ShipResHandler = ResourceManager:LoadAsync(szModel, fnLoadShipEnd)
end

-- 生成武器Actor
function LobbyShip:CreateWeaponActorById(nWeaponId, nIndex)
    if not nWeaponId or nWeaponId <= 0 then
        return
    end

    local szWndName = LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey]
    local tbItemTemplate = ItemSystem:GetItemTemplate(nWeaponId)
    local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(tbItemTemplate.nBattleItemId)

    local szModel = tbBattleItemTemplate.szModelRes
    local pWeaponActor = self:CreateActor(SHIP_WEAPON_ACTOR_RES:load(), nIndex)
    if pWeaponActor and pWeaponActor.StaticMeshComponent then
        pWeaponActor.StaticMeshComponent:SetStaticMesh(szModel:load())
        pWeaponActor.StaticMeshComponent:SetForcedLodModel(1)
    end

    local szTag = GetActorTagByActorIndex(self, nIndex)
    local pDesk = self:GetSubLevelActorByTag(szWndName, szTag)
    pWeaponActor:K2_AttachToActor(pDesk, "", EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, false)

    local tbUIShipTemp = UIShipDataTable:GetTemplate(nWeaponId, "lobbyshipweapon")
    local tbModify = self:MakeModify(tbUIShipTemp.tbLocation[1], tbUIShipTemp.tbLocation[2], tbUIShipTemp.tbLocation[3],
                                    0, 0, tbUIShipTemp.nYaw,
                                    tbUIShipTemp.nScale)
    SetActorLocationAndRotation(pWeaponActor, ZERO_VECTOR, nil, tbModify)

    return pWeaponActor
end

function LobbyShip:CreateSkeletalMeshActor(nIndex, szModel)
    local pActor = self:CreateActor(StaticMeshActor, nIndex)
    if pActor then
        pActor:SetMobility(EComponentMobility.Movable)
    end
    if pActor and pActor.StaticMeshComponent then
        pActor.StaticMeshComponent:SetStaticMesh(szModel:load())
        pActor.StaticMeshComponent:SetForcedLodModel(1)
    end
    return pActor
end

-- 销毁Actpr
function LobbyShip:DestroyShipActorByIndex(nIndex)
    if not nIndex then
        logerror("[LobbyShip] DestroyShipActorByIndex no index specified.")
        return
    end
    local pShipActor = self.tbActors[nIndex]
    if pShipActor then
        pShipActor:K2_DestroyActor()
    end
    self.tbActors[nIndex] = nil
    self.tbShipActorIds[nIndex] = nil
end

function LobbyShip:DestroyAllShipActors()
    ClearDelayShowShipTimer(self)
    for i = 1, MAX_EQUIPPED_COUNT do
        local pShipActor = self.tbActors[i]
        if pShipActor then
            pShipActor:K2_DestroyActor()
        end
        self.tbActors[i] = nil
        self.tbShipActorIds[i] = nil
        
        local pRotateActor = self.tbRotateActors[i]
        local pOriginRotation = self.tbOriginRotations[i]
        if isvalidhandle(pRotateActor) and pOriginRotation then
            pRotateActor:K2_SetActorRotation(pOriginRotation)
        end
        self.tbRotateActors[i] = nil
        self.tbOriginRotations[i] = nil
    end
end

function LobbyShip:GetSubLevelActorByTag(szWndName, szTag)
    local pSubLevel = self:GetLevelStream(szWndName)
    return ExtendBlueprintFunctions.GetLevelActorByTag(pSubLevel, szTag)
end

function LobbyShip:GetActorByIndex(nIndex)
    return self.tbActors[nIndex]
end

function LobbyShip:GetRotateActorByIndex(nIndex)
    return self.tbRotateActors[nIndex]
end

function LobbyShip:GetActorTagByIndex(szWndName, nActorIndex)
    nActorIndex = nActorIndex and nActorIndex or 1
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, szWndName)
    if not tbSubLevelTemplate then
        logerror("[LobbyShip] SettleShipTransform cannot find tbsubleveltemplate", self.nSubType, szWndName)
        return 
    end
    local szActorTag = tbSubLevelTemplate.tbActorTag[nActorIndex]
    return szActorTag
end

function LobbyShip:RotateActor(pActor, nMoveDeltaX)
    if not isvalidhandle(pActor) then
        return
    end
    local pRotation = pActor:K2_GetActorRotation()
    local pNewRotation = Rotator {
        Yaw = pRotation.Yaw - nMoveDeltaX
    }
    pActor:K2_SetActorRotation(pNewRotation)
end

function LobbyShip:RotateActorByIndex(nIndex, nMoveDeltaX)
    self:RotateActor(self:GetRotateActorByIndex(nIndex), nMoveDeltaX)
end

-- 切换到船镜头
function LobbyShip:ShowShipDisplayScene(bShow, nCameraIndex, nBlendTime)
    nCameraIndex = nCameraIndex and nCameraIndex or 1
    if bShow then
        local szWndName = LobbyShipWndDef.tbKeyToWndName[self.szCurOpenWndKey]
        self:SetCameraWithBlend(szWndName, nCameraIndex, nBlendTime, EViewTargetBlendFunction.VTBlend_EaseInOut, 10)
    end
end

-- 窗口间跳转
function LobbyShip:OpenShipWnd(szKey, szWndToClose, tbParams)
    
    local FullDisplayCallback = function()
        self.szCurOpenWndKey = szKey
        local szWndToOpen = LobbyShipWndDef.tbKeyToWndName[szKey]

        if szWndToClose then
            UIManager:CloseWnd(szWndToClose)

            local tbCloseSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, szWndToClose)
            local tbOpenSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, szWndToOpen)
            if tbCloseSubLevelTemplate.szResPath ~= tbOpenSubLevelTemplate.szResPath then
                self:SetShouldBeVisible(szWndToClose, false)
            end
            self:DestroyAllShipActors()
        end
        self:SetShouldBeVisible(szWndToOpen, true)
        self:PlayBGMusic(szWndToOpen)
        BlackScreenHelper:CloseBlackScreen()
        if not tbParams then
            tbParams = {}
        end
        tbParams.OwnerSub = self
        UIManager:OpenWnd(szWndToOpen, tbParams)
    end
    if not szWndToClose then
        FullDisplayCallback()
    else
        BlackScreenHelper:ShowBlackScreen(false, FullDisplayCallback, nil)
    end
end

function LobbyShip:GetEquippedShipIds()
    return self.tbEquippedShipIds
end

function LobbyShip:GetEmptyShipSlotCount()
    local nCount = 0
    for _, v in pairs(self.tbEquippedShipIds) do
        if v == 0 then
            nCount = nCount + 1
        end
    end
    return nCount
end

function LobbyShip:LoadShipEquipmentInfo()
    local tbUnlockedShipSlots = self:GetShipPreparationComponent():GetUnlockedShipSlots()
    local tbEquippedShipIds = self:GetShipPreparationComponent():GetEquippedShipIds()
    for i = 1, MAX_EQUIPPED_COUNT do
        -- 记录装配的船Id，-1为未解锁, 0为未装配
        if tbUnlockedShipSlots[i] then
            self.tbEquippedShipIds[i] = tbEquippedShipIds[i] and tbEquippedShipIds[i] or 0
        else
            self.tbEquippedShipIds[i] = -1
        end
    end
end

function LobbyShip:Return(szFromWndName)
    -- if self.nCallerLobbySub then
    --     self.Owner:Activate(self.nCallerLobbySub)
    --     self.nCallerLobbySub = nil
    -- else
        self:OpenShipWnd("Overview", szFromWndName)
    -- end
end

function LobbyShip:CheckLobbyShipShowTipIcon()
    for _, szKey in pairs(LobbyShipWndDef.tbKeys) do
        if self:CheckLobbyShipTabShowTipIcon(szKey) then
            return true
        end
    end
    return false
end

function LobbyShip:CheckLobbyShipTabShowTipIcon(szKey)
    return self.tbShowTipIconChecker[szKey](self)
end

------------------- Utils ---------------------------------
function LobbyShip:GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

function LobbyShip:RequestEquipShipSkin(tbSkinItem)
    local ShipPreparationComponent = self:GetShipPreparationComponent()
    if (not ShipPreparationComponent:IsItemUnlocked(tbSkinItem.nId)) then
        if tbSkinItem.nSourceType ~= SOURCE_TYPE_DEFAULT_OWNED then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_LOCKED"))
        end
        return
    end
    
    if ShipPreparationComponent:IsEquippedShipSkin(tbSkinItem.nShipItemId, tbSkinItem.nId) then
        return
    end
    
    ShipPreparationComponent:RequestEquipShipSkin(tbSkinItem.nId)
end

function LobbyShip:RequestGetItem(tbItem, bStartAwardSession)
    local ShipPreparationComponent = self:GetShipPreparationComponent()
    if tbItem.nCategory == ItemCategoryDef.SHIP_SKIN and tbItem.nShipItemId
    and (not self:IsSourceTypeDefaultOwned(tbItem.nSourceType))
    and (not ShipPreparationComponent:IsShipItemPurchased(tbItem.nShipItemId)) then
        -- if ShipPreparationComponent:IsItemUnlocked(tbItem.nShipItemId) then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_SHIP_NOT_PURCHASED"))
        -- else
        --     UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_SHIP_LOCKED"))
        -- end
        return
    end
    if ItemSourceDataTable:IfShowBuyButton(tbItem.nSourceType) then
        local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(tbItem.nId)
        if tbGoodsTemplate then
            ShopSystem:OnBuyButtonClick(tbGoodsTemplate, bStartAwardSession)
        end
    end
end

function LobbyShip:MakeModify(nX, nY, nZ, nPitch, nRoll, nYaw, nScale)
    return {
        tbLocation={
            nX = nX and nX or 0,    -- X轴偏移
            nY = nY and nY or 0,    -- Y轴偏移
            nZ = nZ and nZ or 0,    -- Z轴偏移
        },
        tbRotation = {
            nPitch = nPitch and nPitch or 0,    -- Pitch偏移
            nRoll = nRoll and nRoll or 0,       -- Roll偏移
            nYaw = nYaw and nYaw or 0,          -- Yaw偏移
        },
        nScale = nScale and nScale or 1,    -- 缩放大小
    }
end

function LobbyShip:GetShipModelModifyByKey(szKey, nShipItemId)
    if not nShipItemId or nShipItemId <= 0 then
        return nil
    end
    local tbModify = nil
    local tbShipResTemplate = DisplayItemHelper.GetShipResTemplate(nShipItemId)
    szKey = LobbyShipWndDef.tbKeyToModifyKey[szKey]
    local tbUIShipTemp = UIShipDataTable:GetTemplate(tbShipResTemplate.nResId, "lobbyship" .. szKey)

    if tbUIShipTemp then
        tbModify = self:MakeModify(tbUIShipTemp.tbLocation[1], tbUIShipTemp.tbLocation[2], tbUIShipTemp.tbLocation[3],
                                    0, 0, tbUIShipTemp.nYaw,
                                    tbUIShipTemp.nScale)
    end
    return tbModify
end

function LobbyShip:IsSourceTypeDefaultOwned(nSourceType)
    return nSourceType == SOURCE_TYPE_DEFAULT_OWNED
end

return LobbyShip