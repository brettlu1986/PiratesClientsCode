local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbySeason = luaclass("LobbySeason", LobbySubBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local DisplayAwardItemIni = require("DisplayAwardItemIni")
local ItemCategoryDef = require("ItemCategoryDef")
local ShipResDataTable = require("ShipResDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipDataTable = require("ShipDataTable")
local GameAvatarHelper = require("GameAvatarHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ResourceManager = require("ResourceManager")
local UIUtils = require("UIUtils")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local UIShipDataTable = require("UIShipDataTable")
local LobbyHumanFashion3DOperator = require("LobbyHumanFashion3DOperator")
local LobbyHumanWeapon3DOperator = require("LobbyHumanWeapon3DOperator")
local LobbyWeaponMiscDataTable = require("LobbyWeaponMiscDataTable")
local LobbyDecorationResDataTable = require("LobbyDecorationResDataTable")
-- local AwardDataTable = require("AwardDataTable")
-- local AwardGiftBoxDataTable = require("AwardGiftBoxDataTable")
-- local ItemSystem = require("ItemSystem")

local ATTACHED_PARENT = "'/Game/Game/OtherObject/AttachedBP/BP_SeasonAttachedParent.BP_SeasonAttachedParent_C'"
LobbySeason.pShipActor  = nil
LobbySeason.pShipWeaponActor = nil
LobbySeason.Human3DOperator = nil
LobbySeason.HumanWeapon3DOperator = nil

local SHIP_MODEL_BASE_SCALE = 1
local HUMAN_MODEL_BASE_SCALE = 0.8

local DEFAULT_TAG_INDEX = 1
local DEFAULT_UI_NAME = UIDef.UI_SEASON_BATTLEPASS

local function GetHumanActor(self)
    if self.Human3DOperator then
        return self.Human3DOperator:GetHumanActor()
    end
end

local function GetHumanWeaponActor(self)
    if self.HumanWeapon3DOperator then
        return self.HumanWeapon3DOperator:GetWeaponActor()
    end
end

local function IsHumanFashion(tbItemTemplate)
    return tbItemTemplate.nCategory == ItemCategoryDef.FASHION
        or tbItemTemplate.nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION
        or tbItemTemplate.nCategory == ItemCategoryDef.SUIT
end

local function IsShipSkin(tbItemTemplate)
    local nCategory = tbItemTemplate.nCategory 
    return nCategory == ItemCategoryDef.SHIP_SKIN 
        or nCategory == ItemCategoryDef.SHIP 
        or nCategory == ItemCategoryDef.SHIP_WEAPON
        or nCategory == ItemCategoryDef.SHIP_PART
end

local function IsDecoration(tbItemTemplate)
    return tbItemTemplate.nCategory == ItemCategoryDef.DECORATION
end

local function IsHumanSuit(tbItemTemplate)
    return false
    -- local nAwardId = tbItemTemplate.nGiftBoxRewardId
    -- if nAwardId == nil then
    --     return false
    -- end
    -- local tbAwardItems = AwardDataTable:GetAwardItem(nAwardId)
    -- if tbAwardItems == nil then
    --     tbAwardItems = AwardGiftBoxDataTable:GetAwardItem(nAwardId)
    -- end

    -- local tbSuit = {}

    -- for _, v in pairs(tbAwardItems) do
    --     local tbTemp = ItemSystem:GetItemTemplate(v.nItemId)
    --     if tbTemp and IsHumanFashion(tbTemp) then
    --         table.insert(tbSuit, v.nItemId)
    --     end
    -- end

    -- return #tbSuit > 0, tbSuit
end

local function UninitShipActor(self)
    if self.pShipHandle ~= nil then
        ResourceManager:CancelLoadAsync(self.pShipHandle)
    end    
    if self.pShipActor ~= nil then
        self.pShipActor:K2_DestroyActor()
        self.pShipActor = nil
    end
    if self.pShipWeaponActor ~= nil then
        self.pShipWeaponActor:K2_DestroyActor()
        self.pShipWeaponActor = nil
    end
end

-- 通过Tag从Level中获取对应Actor的Location和Rotation
local function GetActorLocationAndRotationByTag(self, bHuman, bItem)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, self.szUIName)
    if not tbSubLevelTemplate then
        return 
    end
    local nIndex = (bItem and 3) or (bHuman and 1 or 2)
    local szActorTag = tbSubLevelTemplate.tbActorTag[nIndex]
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, self.szUIName, szActorTag)

    return pLocation, pRotation
end

local function GetShipResTemplate(tbItemTemplate)
    if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_SKIN then
        return ShipResDataTable:GetTemplate(tbItemTemplate.nShipResId)
    elseif tbItemTemplate.nCategory == ItemCategoryDef.SHIP then
        local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(tbItemTemplate.nBattleItemId)
        if tbBattleItemTemplate == nil then
            error("tbBattleItemTemplate is nil, nBattleItemId is " .. tostring(tbItemTemplate.nBattleItemId))
        end
        return ShipDataTable:GetResTemplate(tbBattleItemTemplate.nShipId)
    end
end

local function SetShipTransform(self, pShipActor, pStaticMesh, nResId, bItem)
    local tbTemp = UIShipDataTable:GetTemplate(nResId, "lobbyseason")

    local pLocation, pRotation = GetActorLocationAndRotationByTag(self, false, bItem)
    local nScale = SHIP_MODEL_BASE_SCALE
    if tbTemp ~= nil then
        if pStaticMesh == nil then
            pLocation.X = pLocation.X + tbTemp.tbLocation[1]
            pLocation.Y = pLocation.Y + tbTemp.tbLocation[2]
            pLocation.Z = pLocation.Z + tbTemp.tbLocation[3]
        else
            pShipActor:SetOffset(tbTemp.tbLocation[1], tbTemp.tbLocation[2], tbTemp.tbLocation[3])
        end
        pRotation.Yaw = pRotation.Yaw + tbTemp.nYaw
        nScale = nScale * tbTemp.nScale
    end
    -- ActorLocationHelper:SetHumanLocationBasedOnFoot(pShipActor, pLocation)
    EngineExtActorShell.SetActorLocation(pShipActor, pLocation)
    EngineExtActorShell.SetActorRotation(pShipActor, pRotation)
    EngineExtActorShell.SetActorScale(pShipActor, nScale)
end

-- 生成ShipActor
local function CreateShipActor(self, tbItemTemplate)
    local pSubLevel = self:GetLevelStream(self.szUIName)
    if not pSubLevel or not pSubLevel:IsLevelLoaded() then
        return
    end
    
    local nCategory = tbItemTemplate.nCategory

    -- 创建船
    if nCategory == ItemCategoryDef.SHIP_SKIN or nCategory == ItemCategoryDef.SHIP then
        local tbShipResTemplate = GetShipResTemplate(tbItemTemplate)
        if not tbShipResTemplate then
            return
        end
        self.pShipHandle = ResourceManager:LoadAsync(tbShipResTemplate.szModelClassName, function(_szTempAssetName, pObject)
            local fnSetShipSkin = function()
                -- SkeletalMesh相关设置
                EngineExtActorShell.SetActorSkeletalMeshMipMap(self.pShipActor, true)
                self:SetActorSkeletalMeshLightChannel(self.szUIName, self.pShipActor)
        
                -- 设置舰船皮肤
                local szShipAvatarComponent = DisplayAwardItemIni.tbShipDisplay.szShipAvatarComponent
                local pShipAvatarComponent = EngineExtActorShell.CreateActorComponent(self.pShipActor, szShipAvatarComponent:load())
                pShipAvatarComponent:Init(nil, self.pShipActor, 0)
                GameAvatarHelper:UpdateShipAvatar(pShipAvatarComponent, nil, -1, tbShipResTemplate)
        
                SetShipTransform(self, self.pShipActor, nil, tbShipResTemplate.nResId)
            end
            local pShipActor = EngineExtActorShell.SpawnActorForScript(GWorld, pObject, Transform(), nil)
            pShipActor.SKM_ShipMaster:SetForcedLOD(1)
            self.pShipActor = pShipActor
            fnSetShipSkin()
        end, false)
    elseif nCategory == ItemCategoryDef.SHIP_PART then
        local szModel = tbItemTemplate.szModelRes
        if szModel == nil then
            return
        end
        local pWeaponActor = EngineExtActorShell.SpawnActorForScript(GWorld, ATTACHED_PARENT:load(), Transform(), nil)
        self.pShipWeaponActor = pWeaponActor
        local StaticMeshComponent = pWeaponActor.StaticMesh
        StaticMeshComponent:SetStaticMesh(szModel:load())
        StaticMeshComponent:SetForcedLodModel(1)
        StaticMeshComponent:SetLightingChannels(false, true, false)
        self:SetActorSkeletalMeshLightChannel(self.szUIName, self.pShipWeaponActor)
        SetShipTransform(self, self.pShipWeaponActor, nil, tbItemTemplate.nId, true)
    elseif nCategory == ItemCategoryDef.SHIP_WEAPON then
        local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(tbItemTemplate.nBattleItemId)
        local szModel = tbBattleItemTemplate.szModelRes
        if szModel == nil then
            return
        end
        local pWeaponActor = EngineExtActorShell.SpawnActorForScript(GWorld, ATTACHED_PARENT:load(), Transform(), nil)
        self.pShipWeaponActor = pWeaponActor
        self:SetActorSkeletalMeshLightChannel(self.szUIName, self.pShipWeaponActor)
        local StaticMeshComponent = pWeaponActor.StaticMesh
        StaticMeshComponent:SetStaticMesh(szModel:load())
        StaticMeshComponent:SetForcedLodModel(1)
        StaticMeshComponent:SetLightingChannels(false, true, false)
        SetShipTransform(self, pWeaponActor, StaticMeshComponent, tbItemTemplate.nId, true)
    end
end

local function UninitDecorationActor(self)
    if self.pDecorationActor then
        self.pDecorationActor:K2_DestroyActor()
        self.pDecorationActor = nil
    end
end

local function CreateDecorationActor(self, tbItemTemplate)
    local tbDecorationResTemplate = LobbyDecorationResDataTable:GetTemplate(tbItemTemplate.nResId)
    local szModelResPath = tbDecorationResTemplate and tbDecorationResTemplate.szModelResPath
    if szModelResPath == nil then
        logwarning("lobbyseason decoration mode res is invalid ", tbItemTemplate.nId)
        return
    end
    self.pDecorationActor = EngineExtActorShell.SpawnActorForScript(GWorld, StaticMeshActor, Transform(), nil)
    self:SetActorSkeletalMeshLightChannel(self.szUIName, self.pDecorationActor)
    self.pDecorationActor:SetMobility(EComponentMobility.Movable)
    self.pDecorationActor.StaticMeshComponent:SetStaticMesh(szModelResPath:load())
    self.pDecorationActor.StaticMeshComponent:SetForcedLodModel(1)
    self.pDecorationActor.StaticMeshComponent:SetLightingChannels(false, true, false)
    local pLocation, pRotation = GetActorLocationAndRotationByTag(self, true, true)
    local nScale = 1
    if tbDecorationResTemplate and pLocation and pRotation then
        pLocation.X = pLocation.X + tbDecorationResTemplate.tbSeasonLocationOffset[1]
        pLocation.Y = pLocation.Y + tbDecorationResTemplate.tbSeasonLocationOffset[2]
        pLocation.Z = pLocation.Z + tbDecorationResTemplate.tbSeasonLocationOffset[3]
        pRotation.Pitch = pRotation.Pitch + tbDecorationResTemplate.tbSeasonRotationOffset[1]
        pRotation.Yaw = pRotation.Yaw + tbDecorationResTemplate.tbSeasonRotationOffset[2]
        pRotation.Roll = pRotation.Roll + tbDecorationResTemplate.tbSeasonRotationOffset[3]
        nScale = nScale * tbDecorationResTemplate.nSeasonScale
        
        EngineExtActorShell.SetActorLocation(self.pDecorationActor, pLocation)
        EngineExtActorShell.SetActorRotation(self.pDecorationActor, pRotation)
        EngineExtActorShell.SetActorScale(self.pDecorationActor, nScale)
    end
end

local function CreateHumanSuitActor(self, tbSuit)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nAvatarId = tbPlayer.LobbyPropertyComponent:GetAvatarId()
    local tbAppearance = tbPlayer.AppearanceComponent:GetAppearanceIds()
    local pLocation, pRotation = GetActorLocationAndRotationByTag(self, true)

    local Human3DOperator = LobbyHumanFashion3DOperator()
    self.Human3DOperator = Human3DOperator
    Human3DOperator:Init()
    self:SetActorSkeletalMeshLightChannel(self.szUIName, self.Human3DOperator:GetHumanActor())

    Human3DOperator:SetActorLocation(pLocation)
    Human3DOperator:SetActorRotator(pRotation)
    Human3DOperator:SetActorNumberScale(HUMAN_MODEL_BASE_SCALE)
    Human3DOperator:DisplaySuit(nAvatarId, tbSuit, tbAppearance)
end

local function UninitHuman3DOperator(self)
    if self.Human3DOperator then
        self.Human3DOperator:Uninit()
        self.Human3DOperator = nil
    end
    if self.HumanWeapon3DOperator then
        self.HumanWeapon3DOperator:Uninit()
        self.HumanWeapon3DOperator = nil
    end
end

local function CreateHumanActor(self, tbItemTemplate)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.FASHION then
        local tbPlayer = GamePlayerSelfHelper:Get()
        local nAvatarId = tbPlayer.LobbyPropertyComponent:GetAvatarId()
        local tbAppearance = tbPlayer.AppearanceComponent:GetAppearanceIds()
        local pLocation, pRotation = GetActorLocationAndRotationByTag(self, true)

        local Human3DOperator = LobbyHumanFashion3DOperator()
        self.Human3DOperator = Human3DOperator
        Human3DOperator:Init()
        self:SetActorSkeletalMeshLightChannel(self.szUIName, self.Human3DOperator:GetHumanActor())
        Human3DOperator:SetActorLocation(pLocation)
        Human3DOperator:SetActorRotator(pRotation)
        Human3DOperator:SetActorNumberScale(HUMAN_MODEL_BASE_SCALE)
        Human3DOperator:DisplayOne(nAvatarId, tbItemTemplate.nId, tbAppearance)
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        local pLocation, pRotation = GetActorLocationAndRotationByTag(self, true, true)
        local tbDisplayMiscData = LobbyWeaponMiscDataTable:GetDisplayMiscData(tbItemTemplate.nSubCategory, LobbyWeaponMiscDataTable.DisplayKey.UISeason)
        local HumanWeapon3DOperator = LobbyHumanWeapon3DOperator()
        self.HumanWeapon3DOperator = HumanWeapon3DOperator
        HumanWeapon3DOperator:Init()
        self:SetActorSkeletalMeshLightChannel(self.szUIName, self.HumanWeapon3DOperator:GetWeaponActor())
        
        HumanWeapon3DOperator:SetActorLocation(pLocation)
        HumanWeapon3DOperator:SetActorRotator(pRotation)
        HumanWeapon3DOperator:Display(tbItemTemplate.nSubCategory, tbItemTemplate.nId, tbDisplayMiscData)
    elseif nCategory == ItemCategoryDef.SUIT then

        local tbPlayer = GamePlayerSelfHelper:Get()
        local nAvatarId = tbPlayer.LobbyPropertyComponent:GetAvatarId()
        local tbAppearance = tbPlayer.AppearanceComponent:GetAppearanceIds()
        local pLocation, pRotation = GetActorLocationAndRotationByTag(self, true)

        local Human3DOperator = LobbyHumanFashion3DOperator()
        self.Human3DOperator = Human3DOperator
        Human3DOperator:Init()
        self:SetActorSkeletalMeshLightChannel(self.szUIName, self.Human3DOperator:GetHumanActor())
        Human3DOperator:SetActorLocation(pLocation)
        Human3DOperator:SetActorRotator(pRotation)
        Human3DOperator:SetActorNumberScale(HUMAN_MODEL_BASE_SCALE)
        local tbSubTemplateIds = tbItemTemplate.tbSubItemTemplateIds
        Human3DOperator:DisplaySuit(nAvatarId, tbSubTemplateIds, tbAppearance)

    end
end

--------------override-----------------------
function LobbySeason:Init(Owner, nSubType)
    LobbySeason.super.Init(self, Owner, nSubType)
    
    return true
end

function LobbySeason:Uninit()
    UninitHuman3DOperator(self)
    UninitShipActor(self)    
    UninitDecorationActor(self)
    LobbySeason.super.Uninit(self)
end

function LobbySeason:Activate(tbParam)
    LobbySeason.super.Activate(self, tbParam)
    self:SetShouldBeVisible(DEFAULT_UI_NAME, true)
    self:SetCamera(DEFAULT_UI_NAME, DEFAULT_TAG_INDEX)
    self:PlayBGMusic(DEFAULT_UI_NAME)

    tbParam = tbParam or self:GetRestoreContext()
    if tbParam and tbParam.szUIName then
        UIManager:OpenWnd(tbParam.szUIName, tbParam.tbOpenArgs)
    else
        UIManager:OpenWnd(DEFAULT_UI_NAME)
    end

    UIUtils.BottomMenuUnselectAll()
end

function LobbySeason:Deactivate()
    UIManager:CloseWnd(UIDef.UI_SEASON_BATTLEPASS)
    UIManager:CloseWnd(UIDef.UI_SEASON_BATTLE_TIER_BUY)
    UninitShipActor(self)
    UninitHuman3DOperator(self)
    UninitDecorationActor(self)
    LobbySeason.super.Deactivate(self)
end

function LobbySeason:GetRestoreContext()
    return self.tbRestoreContext
end
-------------------------------外部接口--------------------------------------
function LobbySeason:SetViewTarget(tbItemTemplate, szUIName)
    self.szUIName = szUIName  == nil and DEFAULT_UI_NAME or szUIName
    UninitShipActor(self)
    UninitHuman3DOperator(self)
    UninitDecorationActor(self)
    
    if not tbItemTemplate then
        return false
    elseif IsHumanFashion(tbItemTemplate) then
        CreateHumanActor(self, tbItemTemplate)
        return true
    elseif IsShipSkin(tbItemTemplate) then
        CreateShipActor(self, tbItemTemplate)
        return true
    elseif IsDecoration(tbItemTemplate) then
        CreateDecorationActor(self, tbItemTemplate)
        return true
    else
        local bSuit, tbSuit = IsHumanSuit(tbItemTemplate)
        if bSuit then
            CreateHumanSuitActor(self, tbSuit)
            return true
        else
            return false
        end
    end
end

function LobbySeason:RotateActor(nDelta)
    local fnRotate = function(pActor)
        local pRotation = pActor:K2_GetActorRotation()
        local pNewRotation = Rotator {
            Yaw = pRotation.Yaw - nDelta
        }
        pActor:K2_SetActorRotation(pNewRotation)
    end
    local pHumanActor = GetHumanActor(self)
    if isvalidhandle(pHumanActor) then
        fnRotate(pHumanActor)
    end 
    local pHumanWeaponActor = GetHumanWeaponActor(self)
    if isvalidhandle(pHumanWeaponActor) then
        local pRotation = pHumanWeaponActor:K2_GetActorRotation()
        local pNewRotation = Rotator {
            Roll = pRotation.Roll,
            Pitch = pRotation.Pitch,
            Yaw = pRotation.Yaw - nDelta
        }
        pHumanWeaponActor:K2_SetActorRotation(pNewRotation)
    end 
    if isvalidhandle(self.pDecorationActor) then
        fnRotate(self.pDecorationActor)
    end  
    if isvalidhandle(self.pShipActor) then
        fnRotate(self.pShipActor)
    end    
    if isvalidhandle(self.pShipWeaponActor) then
        fnRotate(self.pShipWeaponActor)
    end
end

return LobbySeason