local ResourceCacheSystem = {}

local ResourceManager = require("ResourceManager")
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local ShipDataTable = require("ShipDataTable")
local SelfEventHelper = require("SelfEventHelper")()
local WidgetDataTable = require("WidgetDataTable")
local PrefabDataTable = require("PrefabDataTable")
local WndDataTable = require("WndDataTable")
local BattleItemResDataTable = require("BattleItemResDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
-- local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")

local UIManager = nil

local szBPBlurBGActorPath = '/Game/UI/RenderTarget/BP_BlurBGActor.BP_BlurBGActor_C'
local szGlobalSettingsPath = "Blueprint'/Game/Framework/Base/BP_GlobalSettings.BP_GlobalSettings_C'"
local bTempEnableUMGPool = true

local BP_CHANGESTATE_PATH = "Blueprint'/Game/Game/Misc/BP_PlayerStateChangeNotifier.BP_PlayerStateChangeNotifier_C'"

local DUNGEON_CACHE_OBJECTS = {
    "Blueprint'/Game/Game/CharacterEx/Vehicle/BP_HumanVehicleHorse.BP_HumanVehicleHorse_C'",
    "Blueprint'/Game/Game/CharacterEx/BP_PlayerFemale.BP_PlayerFemale_C'",
    "Blueprint'/Game/Game/CharacterEx/BP_PlayerMale.BP_PlayerMale_C'",
    "Blueprint'/Game/Game/OtherObject/AttachedBP/AttachedHumanSetSail.AttachedHumanSetSail_C'",
    -- "Blueprint'/Game/Game/OtherObject/AttachedBP/BP_AttachedsShipToHuman.BP_AttachedsShipToHuman_C'",
    -- "Blueprint'/Game/Game/ShipEx/ShipChild/BP_Ship_MayFlower.BP_Ship_MayFlower_C'",
    "Blueprint'/Game/Game/OtherObject/Optimization/BP_OnLanding.BP_OnLanding_C'",
    "Blueprint'/Game/Game/Triggers/BP_SceneItem_Trigger.BP_SceneItem_Trigger_C'",
    "Blueprint'/Game/Game/Ships/Avatar/BP_AvatarBPNode.BP_AvatarBPNode_C'",
    "Blueprint'/Game/Game/Ships/Avatar/BP_AvatarChangeMaterial.BP_AvatarChangeMaterial_C'",
    "Blueprint'/Game/Game/Ships/Avatar/BP_AvatarInstanceMeshBPNode.BP_AvatarInstanceMeshBPNode_C'",
    "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_WindowBase.BP_WindowBase_C'",
    "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_DoorBase.BP_DoorBase_C'",

    --人物基础动画
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Assistance/AM_F_HumanToShipStand.AM_F_HumanToShipStand'",
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Common/AM_F_0_UnarmedPick.AM_F_0_UnarmedPick'",
    
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Climb/AM_F_JumpParapetWall_New.AM_F_JumpParapetWall_New'",
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Climb/AM_F_Unarmed_JumpSpeelHighWall_Jump_New.AM_F_Unarmed_JumpSpeelHighWall_Jump_New'",
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Climb/AM_F_Unarmed_JumpSpeelHighWall_Stand_New.AM_F_Unarmed_JumpSpeelHighWall_Stand_New'",
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Climb/AM_F_Unarmed_JumpSpeelMidWall_Jump_New.AM_F_Unarmed_JumpSpeelMidWall_Jump_New'",
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Climb/AM_F_Unarmed_JumpSpeelMidWall_Stand_New.AM_F_Unarmed_JumpSpeelMidWall_Stand_New'",
    "AnimMontage'/Game/Game/CharacterEx/Roles/F_0/Montage/Help/AM_F_0_InjuredToLeave.AM_F_0_InjuredToLeave",
}

ResourceCacheSystem.tbHandlers = nil
ResourceCacheSystem.FlagShipClassHolder = nil
ResourceCacheSystem.tbDungeonHandles = nil
ResourceCacheSystem.tbDungeonRes = nil
ResourceCacheSystem.tbUMGPool = nil
ResourceCacheSystem.tbDungeonCacheObjects = nil
ResourceCacheSystem.bFirstPlayerSelfReadyInDungeon = false
ResourceCacheSystem.tbShipPartAvatarHandles = nil
ResourceCacheSystem.tbShipWeaponAvatarHandles = nil
ResourceCacheSystem.tbShipAvatarHandle = nil
ResourceCacheSystem.tbWndUMGObjects = nil

local bCachedSceneItemMesh = false
local OnPlayerSelfReady
local OnPlayerSelfUnReady
local OnEnterDungeon
local OnLeaveDungeon
local OnEnterLobby
local OnLeaveLobby
local OnBattleItemAdded
local OnBattleItemRemoved
local CacheDungeonDefaultResource
local OnFFAInfoChanged
local OnFFAPawnDead

local function LoadAsync(self, szAssetName, fnCallback, bHold)
    if(szAssetName == nil or string.len(szAssetName) == 0) then
        return nil
    end

    log("ResourceCacheSystem LoadAsync file:", szAssetName, ", hold:", bHold)
    local fnFunc = function (szTempAssetName, pObject, nHandle)
        self.tbHandlers[nHandle] = nil
        if(fnCallback) then
            fnCallback(szTempAssetName, pObject, nHandle)
        end
    end

    local nHandle = ResourceManager:LoadAsync(szAssetName, fnFunc, bHold)
    if(nHandle >= 0) then
        self.tbHandlers[nHandle] = szAssetName
    end
    return nHandle
end

local function CancelLoad(self, nHandle)
    if(self.tbHandlers[nHandle]) then
        self.tbHandlers[nHandle] = nil
        ResourceManager:CancelLoadAsync(nHandle)
    end
end

-- local function OnHandleManagerLoaded(_, pObject)
--     HandlerManagerHelper:Init(pObject)
-- end

local function OnGlobalSettingsLoaded(_, pObject)
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if not pGameInstance.GlobalSettings then
        local pGlobalSettings = ExtendBlueprintFunctions.CreateObject(pObject, nil)
        pGameInstance:InitGlobalSettings(pGlobalSettings)
        log("[GlobalSettings] GlobalSettings initialize in ResourceCacheSystem.")
    else
        log("[GlobalSettings] GlobalSettings had initialized. Ignore it.")
    end
end

local function CacheBPPlayerStateChange(self)
    local fnCallback = function(szAssetName, pObject, nHandle)
        self.pBPChangeState = pObject
    end
    LoadAsync(self, BP_CHANGESTATE_PATH, fnCallback, true)
end

local function CacheSceneItem()
    if bCachedSceneItemMesh then
        return
    end
    local tbMeshs = {}
    for k, v in pairs(BattleItemResDataTable.tbContainer) do
        for key, value in pairs(v) do
            if string.len(value.szDisplayMeshName) > 0 then
                table.insert(tbMeshs, v.szDisplayMeshName)
            end
        end
    end
    KMInstancedSceneItemActor.InitStaticMeshSources(tbMeshs)
    bCachedSceneItemMesh = true
end
---------------------------------------------------------------------------------
-- UI
local function CacheUIResource(self, tbDataTable, Id, szKey)
    local tbTemplate = tbDataTable:GetTemplate(Id)
    if(tbTemplate) then
        LoadAsync(self, tbTemplate[szKey], nil, true)
    end
end

local function CacheUMGObjectToPool(self, tbDataTable, Id, szKey, nInitCount, nIncreaseStep)
    local tbTemplate = tbDataTable:GetTemplate(Id)
    if(tbTemplate == nil) then
        error("CacheUMGObjectToPool failed, cannot find table "..Id)
        return
    end

    local szUIPath = tbTemplate[szKey]
    bTempEnableUMGPool = false
    assert(self.tbUMGPool[szUIPath] == nil)
    local pWidget
    local tbPool = {}
    tbPool.nIncreaseStep = nIncreaseStep
    tbPool.szUIPath = szUIPath

    for i=1, nInitCount do
        pWidget = UIManager:CreateUMG(szUIPath)
        table.insert(tbPool, pWidget)
    end
    self.tbUMGPool[szUIPath] = tbPool
    bTempEnableUMGPool = true
    log("CacheUMGObjectToPool", szUIPath)
end

local function ClearUMGObjectPools(self)
    local tbUMGPool = self.tbUMGPool
    if(tbUMGPool) then
        bTempEnableUMGPool = false
        self.tbUMGPool = nil
        for k, tbObjects in pairs(tbUMGPool) do
            for _, v in ipairs(tbObjects) do
                UIManager:DestroyWidget(v)
            end
        end
        bTempEnableUMGPool = true
    end
end

function ResourceCacheSystem:CreateUMGObject(szUIPath)
    if(not bTempEnableUMGPool or self.tbUMGPool == nil) then
        return nil
    end

    local tbPool = self.tbUMGPool[szUIPath]
    local pRet = nil
    if(tbPool) then
        if(#tbPool == 0) then
            bTempEnableUMGPool = false
            local pWidget
            local nIncreaseStep = tbPool.nIncreaseStep
            for i=1, nIncreaseStep do
                pWidget = UIManager:CreateUMG(szUIPath)
                assert(pWidget)
                table.insert(tbPool, pWidget)
            end
            bTempEnableUMGPool = true
            log("ResourceCacheSystem increase pool", szUIPath, nIncreaseStep)
        end

        local nObjectCount = #tbPool
        pRet = tbPool[nObjectCount]
        table.remove(tbPool, nObjectCount)

        -- 记录一下索引
        local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pRet)
        assert(self.tbUMGPool[nUniqueId] == nil)
        self.tbUMGPool[nUniqueId] = tbPool

        --log("ResourceCacheSystem:CreateUMGObject", szUIPath, nUniqueId, #tbPool)
    end
    return pRet
end

function ResourceCacheSystem:DestroyUMGObject(pWidgetRef)
    if(not bTempEnableUMGPool or self.tbUMGPool == nil) then
        return false
    end

    local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local tbPool = self.tbUMGPool[nUniqueId]

    if(tbPool) then
        table.insert(tbPool, pWidgetRef)
        self.tbUMGPool[nUniqueId] = nil
        --log("ResourceCacheSystem:DestroyUMGObject", tbPool.szUIPath, #tbPool)
        return true
    end

    return false
end

local function CacheUEEnum()

    local tbCacheUEEnumPath = {
        "UserDefinedEnum'/Game/Game/ShipEx/Misc/Enum_SoundType.Enum_SoundType'",
    }
    for _, v in ipairs(tbCacheUEEnumPath) do
        ResourceManager:LoadSync(v, true)
    end

    log("Load Cache UE Enum Finished...")
end

local function CacheDungeonBPObject(self)
    local fnLoadedBP = function(szRes, pObject, nHandle)
        self.tbDungeonCacheObjects[szRes].pObject = pObject
    end
    for i, v in ipairs(DUNGEON_CACHE_OBJECTS) do
        local tbData = {}
        tbData.nHandle = LoadAsync(self, v, fnLoadedBP, true)
        self.tbDungeonCacheObjects[v] = tbData
    end
end

local function UnCacheDungeonBPObject(self)
    if self.tbDungeonCacheObjects == nil then
        return
    end
    for k, v in pairs(self.tbDungeonCacheObjects) do
        CancelLoad(self, v.nHandle)
        if v.pObject ~= nil then
            ResourceManager:Unhold(v.pObject)
        end
    end
    self.tbDungeonCacheObjects = nil
end

OnPlayerSelfReady = function(self)
    if(GlobalVariableSystem:IsInDungeon() and self.bFirstPlayerSelfReadyInDungeon) then
        self.bFirstPlayerSelfReadyInDungeon = false
        CacheDungeonDefaultResource(self)
    end
end

OnPlayerSelfUnReady = function(self)
end

local function CacheItemAvatar(self, nItemTemplateId, tbHandle, szRes, szObjectName, szHandleName)
    log("ResourceCacheSystem CacheItemAvatar Begin", nItemTemplateId, szRes)
    if szRes then
        local fnCallback = function(szAsset, pObject, nHandle)
            log("ResourceCacheSystem CacheItemAvatar", nItemTemplateId, szRes)
            tbHandle[szObjectName] = pObject
        end
        local nModelHandle = LoadAsync(self, szRes, fnCallback, true)
        if(nModelHandle ~= nil) then
            tbHandle[szHandleName] = nModelHandle
        else
            logerror("Load item resource async failed! nHandle is nil!", nItemTemplateId, szRes)
        end
    else
        logerror("CacheItemAvatar failed! szRes is nil", nItemTemplateId, szRes)
    end
end

local function UncacheItemAvatar(self, tbHandle, szObjectName, szHandleName)
    log("ResourceCacheSystem UncacheItemAvatar CancelLoad", tbHandle.nItemTemplateId)
    CancelLoad(self, tbHandle[szHandleName])
    if tbHandle[szObjectName] ~= nil then
        log("ResourceCacheSystem UncacheItemAvatar Unhold", tbHandle.nItemTemplateId)
        ResourceManager:Unhold(tbHandle[szObjectName])
    end
    tbHandle = nil
end

local function CacheShipWeaponResource(self, Item)
    local tbTemplate = Item:GetTemplate()
    local nItemTemplateId = tbTemplate.nId
    if self.tbShipWeaponAvatarHandles[nItemTemplateId] then
        return
    end

    local tbHandleData = {}
    tbHandleData.nItemTemplateId = nItemTemplateId
    self.tbShipWeaponAvatarHandles[nItemTemplateId] = tbHandleData

    local szBulletRes = tbTemplate.szBulletRes
    if szBulletRes then
        CacheItemAvatar(self, nItemTemplateId, tbHandleData, szBulletRes, "pBulletClass", "nBulletHandle")
    end

    -- local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(tbTemplate.nSubCategory)
    -- if nWeaponSlot == ShipWeaponSlotDef.UNKNOWN then
    --     return
    -- end

    -- local szModelRes = tbTemplate.szModelRes
    -- if szModelRes then
    --     CacheItemAvatar(self, nItemTemplateId, tbHandleData, szModelRes, "pModelObject", "nModelHandle")
    -- else
    --     logerror("CacheShipWeaponResource failed! szModelRes is nil", nItemTemplateId, szModelRes)
    -- end

    -- local szSimplifiedModelRes = tbTemplate.szSimplifiedModelRes
    -- if szSimplifiedModelRes then
    --     CacheItemAvatar(self, nItemTemplateId, tbHandleData, szSimplifiedModelRes, "pSimplifiedModelObject", "nSimplifiedModelHandle")
    -- end
end

local function UnCacheShipWeaponAvatar(self, tbHandleData)
    UncacheItemAvatar(self, tbHandleData, "pBulletClass", "nBulletHandle")
    UncacheItemAvatar(self, tbHandleData, "pModelObject", "nModelHandle")
    UncacheItemAvatar(self, tbHandleData, "pSimplifiedModelObject", "nSimplifiedModelHandle")
end

local function UnCacheShipWeaponAvatars(self)
    if self.tbShipWeaponAvatarHandles == nil then
        return
    end
    for _, v in pairs(self.tbShipWeaponAvatarHandles) do
        UnCacheShipWeaponAvatar(self, v)
    end
    self.tbShipWeaponAvatarHandles = nil
end

local function CacheShipPartResource(self, Item)
    local tbTemplate = Item:GetTemplate()
    local nItemTemplateId = tbTemplate.nId
    if self.tbShipPartAvatarHandles[nItemTemplateId] then
        return
    end
    if tbTemplate.nAppearanceResId > 0 then
        local szAssetName = ExtendBlueprintFunctions.GetAvatarPartResourceData(tbTemplate.nAppearanceResId, "")
        local tbHandleData = {}
        tbHandleData.nItemTemplateId = nItemTemplateId
        self.tbShipPartAvatarHandles[nItemTemplateId] = tbHandleData
        CacheItemAvatar(self, nItemTemplateId, tbHandleData, szAssetName, "pObject", "nHandle")
    else
        logerror("CacheShipPartResource failed! nAppearanceResId is not bigger than 0", nItemTemplateId, tbTemplate.nAppearanceResId)
    end
end

local function UnCacheShipPartAvatar(self, tbHandleData)
    UncacheItemAvatar(self, tbHandleData, "pObject", "nHandle")
end

local function UnCacheShipPartAvatars(self)
    if self.tbShipPartAvatarHandles == nil then
        return
    end
    for _, v in pairs(self.tbShipPartAvatarHandles) do
        UnCacheShipPartAvatar(self, v)
    end
    self.tbShipPartAvatarHandles = nil
end

local function UnCacheShipAvatar(self)
    if self.tbShipAvatarHandle then
        UncacheItemAvatar(self, self.tbShipAvatarHandle, "pObject", "nHandle")
        self.tbShipAvatarHandle = nil
    end
end

local function GetShipActorClassByTemplateId(self, nShipId)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local BattleShipSkinComponent = tbPlayerSelf.BattleShipSkinComponent
    if BattleShipSkinComponent then
        local tbResTemplate = BattleShipSkinComponent:GetShipResTemplate(nShipId)
        if tbResTemplate then
            return tbResTemplate.szPawnClassName
        end
    else
        logerror("GetShipActorClassByTemplateId failed! BattleShipSkinComponent is nil", nShipId)
    end
    local tbShipTemplate = ShipDataTable:GetTemplate(nShipId)
    if(tbShipTemplate ~= nil) then
        return tbShipTemplate.tbResData.szPawnClassName
    end
    logerror("GetShipActorClassByTemplateId failed! can not find ship templateid: ", nShipId)
    return nil
end

local function CacheShipResource(self, Item)
    local nItemTemplateId = Item:GetTemplateId()
    if self.tbShipAvatarHandle then
        UnCacheShipAvatar(self)
    end
    local tbTemplate = Item:GetTemplate()
    local nShipId = tbTemplate.nShipId
    local szClassName = GetShipActorClassByTemplateId(self, nShipId)
    if szClassName then
        self.tbShipAvatarHandle = {}
        self.tbShipAvatarHandle.nItemTemplateId = nItemTemplateId
        CacheItemAvatar(self, nItemTemplateId, self.tbShipAvatarHandle, szClassName, "pObject", "nHandle")
    else
        logerror("CacheShipResource failed! szClassName is nil", nItemTemplateId)
    end
end

OnBattleItemAdded = function(self, Item)
    -- 装备了船、船武器，船零件，提前加载资源
    local nCategory = Item:GetCategory()
    if nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        CacheShipWeaponResource(self, Item)
    elseif nCategory == BattleItemCategoryDef.SHIP_PART then
        CacheShipPartResource(self, Item)
    elseif nCategory == BattleItemCategoryDef.SHIP then
        CacheShipResource(self, Item)
    end
end

OnBattleItemRemoved = function(self, _, nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    if nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        local tbHandleData = self.tbShipWeaponAvatarHandles[nItemTemplateId]
        if tbHandleData then
            UnCacheShipWeaponAvatar(self, tbHandleData)
            self.tbShipWeaponAvatarHandles[nItemTemplateId] = nil
        end
    elseif nCategory == BattleItemCategoryDef.SHIP_PART then
        local tbHandleData = self.tbShipPartAvatarHandles[nItemTemplateId]
        if tbHandleData then
            UnCacheShipPartAvatar(self, tbHandleData)
            self.tbShipPartAvatarHandles[nItemTemplateId] = nil
        end
    elseif nCategory == BattleItemCategoryDef.SHIP then
        UnCacheShipAvatar(self)
    end
end

local function UnCacheWndUMGObjects(self)
    if self.tbWndUMGObjects == nil then
        return
    end
    for k, v in pairs(self.tbWndUMGObjects)do
        CancelLoad(self, v.nHandle)
        if v.pHoldObj then
            ResourceManager:Unhold(v.pHoldObj)
        end
    end
    self.tbWndUMGObjects = nil
end

local function CacheWndUMGObject(self, tbDataTable, Id, szKey)
    if self.tbWndUMGObjects[Id] == nil then
        local tbTemplate = tbDataTable:GetTemplate(Id)
        if(tbTemplate == nil) then
            error("CacheWndUMGObject failed, cannot find in table "..Id)
            return
        end
        local tbHandleData = {}
        self.tbWndUMGObjects[Id] = tbHandleData
        local function fnLoadUIPath(szAssetName, pObject, nHandle)
            tbHandleData.pHoldObj = pObject
            CacheUMGObjectToPool(self, tbDataTable, Id, szKey, 1, 1)
        end
        local szUIPath = tbTemplate[szKey]
        tbHandleData.nHandle = LoadAsync(self, szUIPath, fnLoadUIPath, true)
    end
end

OnFFAInfoChanged = function(self, rInfo)
    if rInfo.nAlivePlayerCount <= 8 then
        CacheWndUMGObject(self, WndDataTable, UIDef.UI_FFA_BATTLE_RESULT, "szUIPath")
        CacheWndUMGObject(self, WndDataTable, UIDef.UI_BATTLE_WIN_PROMPT, "szUIPath")
    end
end

OnFFAPawnDead = function(self, tbGameObject)
    if tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        CacheWndUMGObject(self, WndDataTable, UIDef.UI_FFA_BATTLE_RESULT, "szUIPath")
    end
end
--------------------------------------------------------------------------------
function ResourceCacheSystem:OnEnterLogin()
    LoadAsync(self, szBPBlurBGActorPath, nil, true)

    LoadAsync(self, szGlobalSettingsPath, OnGlobalSettingsLoaded, false)

    CacheUIResource(self, WidgetDataTable, UIDef.UW_HEAD_INFO, "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_NAME_WIDGET, "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_DIALOG_WIDGET, "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_MAP_OBJ, "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_FLOAT_NUM, "szUIPath")
    CacheSceneItem()
end

OnEnterLobby = function(self)
    self.tbUMGPool = {}

    CacheUIResource(self, WndDataTable, UIDef.UI_SEASON_BATTLEPASS, "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_LOBBY_DISPLAY_ITEM_ASYNC, "szUIPath")
end

OnLeaveLobby = function(self)
    ClearUMGObjectPools(self)
end

CacheDungeonDefaultResource = function(self)
    CacheUMGObjectToPool(self, WidgetDataTable, UIDef.UW_HEAD_INFO, "szUIPath", 8, 4)
    CacheUMGObjectToPool(self, PrefabDataTable, UIDef.UP_TEAM_HEAD_NAME, "szUIPath", 3, 3)
    --CacheUMGObjectToPool(self, PrefabDataTable, UIDef.UP_BATTLE_HEAD_INFO,  "szUIPath", 8, 4)
    CacheUMGObjectToPool(self, PrefabDataTable, UIDef.UP_MAP_OBJ,  "szUIPath", 280, 4)
    CacheWndUMGObject(self,    WndDataTable,    UIDef.UI_BUILD_ITEM_TIPS, "szUIPath")
    CacheWndUMGObject(self,    WndDataTable,    UIDef.UI_FFABACKPACK, "szUIPath")

    CacheBPPlayerStateChange(self)
    CacheDungeonBPObject(self)
    CacheUIResource(self, WndDataTable,    UIDef.UI_BUILD_ITEM,          "szUIPath")
    CacheUIResource(self, WndDataTable,    UIDef.UI_PICKUP_BOX,          "szUIPath")
    CacheUIResource(self, WndDataTable,    UIDef.UI_PICKUP_ITEM,         "szUIPath")
    CacheUIResource(self, WndDataTable,    UIDef.UI_WORLD_MAP,           "szUIPath")
    CacheUIResource(self, WndDataTable,    UIDef.UI_FIVECOUNTDOWN,       "szUIPath")
    CacheUIResource(self, WndDataTable,    UIDef.UI_EFFECT_CHANGE_DISPLAY,"szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_PICKUP_ITEM,         "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_PICKUP_LIST_ITEM,    "szUIPath")
    CacheUIResource(self, PrefabDataTable, UIDef.UP_ATTACK_WARNING_ITEM, "szUIPath")
end

OnEnterDungeon = function(self)
    self.tbDungeonHandles = {}
    self.tbDungeonRes = {}
    self.tbUMGPool = {}
    self.tbDungeonCacheObjects = {}
    self.bFirstPlayerSelfReadyInDungeon = true
    self.tbShipPartAvatarHandles = {}
    self.tbShipWeaponAvatarHandles = {}
    self.tbWndUMGObjects = {}
end

OnLeaveDungeon = function(self)
    UnCacheDungeonBPObject(self)
    OnPlayerSelfUnReady(self)
    UnCacheShipPartAvatars(self)
    UnCacheShipWeaponAvatars(self)
    UnCacheShipAvatar(self)
    UnCacheWndUMGObjects(self)

    local tbDungeonHandles = self.tbDungeonHandles
    if(tbDungeonHandles) then
        for nHandle, _ in pairs(tbDungeonHandles) do
            CancelLoad(self, nHandle)
        end
        self.tbDungeonHandles = nil
    end

    local tbDungeonRes = self.tbDungeonRes
    if(tbDungeonRes) then
        for _, v in ipairs(tbDungeonRes) do
            ResourceManager:Unhold(v)
        end
        self.tbDungeonRes = nil
    end

    ClearUMGObjectPools(self)

    self.tbDungeonHandles = nil
    self.tbDungeonRes = nil
    self.tbUMGPool = nil
    self.tbDungeonCacheObjects = nil
    self.bFirstPlayerSelfReadyInDungeon = false
end

function ResourceCacheSystem:CacheDungeonResources(tbResources)
    if(tbResources) then
        local OnLoaded = function(szAssetName, pObject, nHandle)
            self.tbDungeonHandles[nHandle] = nil
            table.insert(self.tbDungeonRes, pObject)
        end

        local nHandle
        local tbDungeonHandles = self.tbDungeonHandles
        for _, szRes in ipairs(tbResources) do
            nHandle = LoadAsync(self, szRes, OnLoaded, true)
            if(nHandle ~= nil) then
                tbDungeonHandles[nHandle] = true
            end
        end
    end
end


function ResourceCacheSystem:Init()
    UIManager = require("UIManager")

    self.tbHandlers = {}
    self.tbUMGPool = nil
    self.pBPChangeState = nil

    SelfEventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterDungeon)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveDungeon)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnBattleItemAdded)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnBattleItemRemoved)
    SelfEventHelper:RegisterEvent(ClientEventDef.EV_FFA_INFO_CHANGED, self, OnFFAInfoChanged)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnFFAPawnDead)
    CacheUEEnum()
end

function ResourceCacheSystem:Uninit()
    SelfEventHelper:UnregisterAll()

    if (self.pBPChangeState) then
        ResourceManager:Unhold(self.pBPChangeState)
        self.pBPChangeState = nil
    end

    OnLeaveDungeon(self)

    local tbHandlers = self.tbHandlers
    if(tbHandlers) then
        self.tbHandlers = nil
        for k, v in pairs(tbHandlers) do
            ResourceManager:CancelLoadAsync(k)
        end
    end

    -- Init在这个文件，Uninit暂时也先放在这吧，等人里的逻辑从HandlerManager中移除，可以直接删掉
    -- HandlerManagerHelper:Uninit()

    ClearUMGObjectPools(self)
end

-- 在副本中同步加载资源并Cache，退出副本时自动release
function ResourceCacheSystem:SyncCacheInDungeon(szRes)
    local tbData = self.tbDungeonCacheObjects[szRes]
    if not tbData then
        tbData = {}
        tbData.pObject = ResourceManager:LoadSync(szRes, true)
        self.tbDungeonCacheObjects[szRes] = tbData
    end
    return tbData.pObject
end

return ResourceCacheSystem
