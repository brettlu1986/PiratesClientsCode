-- 涉及到多系统交互的都放这，尽量不要记录状态
local HumanWeaponHelper = {}

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local HumanThrownItemDef = require("HumanThrownItemDef")
local HumanWeaponDef = require("HumanWeaponDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local HumanWeaponMisc = require("HumanWeaponMisc")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local NetworkManager = dynamic_require("NetworkManager")
local HumanWeaponItemPropertyHelper = require("HumanWeaponItemPropertyHelper")
local HumanThrownItemPropertyHelper = require("HumanThrownItemPropertyHelper")
local Proto = require("DungeonCommonProtoNames")
local HumanBodyDef = require("HumanBodyDef")
local PropUtil = require("PropUtil")
local PropName = require("PropName")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local RelationshipSystem = require("RelationshipSystem")
local DamageTypeEx = require("DamageTypeEx")
local HumanArmorDef = require("HumanArmorDef")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local EventManager = require("EventManager")
local CommonEventDef = dynamic_require("CommonEventDef")
local HumanWeaponType = require("HumanWeaponType")
local HumanMovementStateType = require("HumanMovementStateType")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local GameNpcType = require("GameNpcType")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanArmorItemPropertyHelper = require("HumanArmorItemPropertyHelper")
local AnimDef = require("AnimDef")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local GenderTypeDef 	= require("GenderTypeDefine")
local HumanDataTable = require("HumanDataTable")

local GameCameraSystem = nil
local GameCameraModeGroupDef = nil
local TeamWatchClientHelper = nil

--local EMPTY_TABLE = {}
local PACKET_WEAPON_ID_ONLY = {}
local tbTempTable = {}
local DEFAULT_ARMOR_FACTOR = 1

local WeaponCategory = HumanWeaponDef.WeaponCategory
local ThrownItemCategory = HumanThrownItemDef.ItemCategory
local SlotDef = HumanWeaponMisc.SlotDef
local Property = HumanWeaponDef.Property
local TotalProperty = HumanWeaponDef.TotalProperty

local GetComponentFromHitResult = ExtendBlueprintFunctions.GetComponentFromHitResult
local GetObjectName = KismetSystemLibrary.GetObjectName
local ApplyDamage = PropUtil.ApplyDamage

local tbWeaponCategoryToClass = nil
local tbThrownCategoryToClass = nil

local tbPartPropertyToEnum =
{
    ["Uparm_l"]                         = HumanBodyDef.HUMAN_ALLFOURS,          --后臂 左
    ["Uparm_r"]                         = HumanBodyDef.HUMAN_ALLFOURS,          --后臂 右
    ["Forearm_l"]                       = HumanBodyDef.HUMAN_ALLFOURS,          --前臂 左
    ["Forearm_r"]                       = HumanBodyDef.HUMAN_ALLFOURS,          --前臂 右
    ["Head"]                            = HumanBodyDef.HUMAN_HEAD,              --头
    ["Body"]                            = HumanBodyDef.HUMAN_BODY,              --上半身
    ["Thigh_r"]                         = HumanBodyDef.HUMAN_ALLFOURS,          --大腿 右
    ["Thigh_l"]                         = HumanBodyDef.HUMAN_ALLFOURS,          --大腿 左
    ["Calf_l"]                          = HumanBodyDef.HUMAN_ALLFOURS,          --小腿 左
    ["Calf_r"]                          = HumanBodyDef.HUMAN_ALLFOURS,          --小腿 右
    ["L_Calf"]                          = HumanBodyDef.HUMAN_ALLFOURS,          --马后腿 左
    ["R_Calf"]                          = HumanBodyDef.HUMAN_ALLFOURS,          --马后腿 右
    ["L_Toe"]                           = HumanBodyDef.HUMAN_ALLFOURS,          --马后腿 左
    ["R_Toe"]                           = HumanBodyDef.HUMAN_ALLFOURS,          --马后腿 右
    ["L_Forearm"]                       = HumanBodyDef.HUMAN_ALLFOURS,          --马前腿 左
    ["R_Foream"]                        = HumanBodyDef.HUMAN_ALLFOURS,          --马前腿 右
    ["L_Finger"]                        = HumanBodyDef.HUMAN_ALLFOURS,          --马前腿 左
    ["R_Finger"]                        = HumanBodyDef.HUMAN_ALLFOURS,          --马前腿 右
}

local tbHumanPartProperty =
{
    "Uparm_l",
    "Uparm_r",
    "Forearm_l",
    "Forearm_r",
    "Head",
    "Body",
    "Thigh_r",
    "Thigh_l",
    "Calf_l",
    "Calf_r"
}

local tbMovementStateToHeadInfo = {
    [HumanMovementStateType.None] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.UpRight_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Crouch_State] = "HeadInfoCrouchLoc",
    [HumanMovementStateType.Crawl_State] = "HeadInfoCrawlLoc",
    [HumanMovementStateType.Dying_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.InPlane_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Parachutine_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Falling_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Gliding_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Driving_State] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Jumping_SpeelWall] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Swimming] = "HeadInfoUpRightLoc",
    [HumanMovementStateType.Vehicle] = "HeadInfoRideLoc",
}

local tbPartPropertyNames =
{
    [HumanBodyDef.HUMAN_ALLFOURS]     = PropName.nAllFoursInjuryRatio,          --后臂 左
    [HumanBodyDef.HUMAN_HEAD]         = PropName.nHeadInjuryRatio,              --后臂 右
    [HumanBodyDef.HUMAN_BODY]         = PropName.nBodyInjuryRatio,              --前臂 左
}

local tbWeaponItemCategoryToDamageEx =
{
    [WeaponCategory.Melee]            = DamageTypeEx.HUMAN_MELEE,               -- 刀
    [WeaponCategory.Pistol]           = DamageTypeEx.HUMAN_PISTOL,              -- 手枪
    [WeaponCategory.Flintlock]        = DamageTypeEx.HUMAN_FLINTLOCK,           -- 燧发枪
    [WeaponCategory.Matchlock]        = DamageTypeEx.HUMAN_MATCHLOCK,           -- 火绳枪
    [WeaponCategory.Crossbow]         = DamageTypeEx.HUMAN_CROSSBOW,            -- 弩
    [WeaponCategory.Bow]              = DamageTypeEx.HUMAN_BOW,                 -- 弓
    [WeaponCategory.TwoHand]          = DamageTypeEx.HUMAN_MELEE,               -- 刀
    [WeaponCategory.ThrowWeapon]      = DamageTypeEx.HUMAN_FLYINGKNIFE,         -- 飞刀
}

local tbThrownItemCategoryToDamageEx =
{
    [ThrownItemCategory.Hit]          = DamageTypeEx.HUMAN_FLYINGKNIFE,         -- 飞刀
    [ThrownItemCategory.Explosive]    = DamageTypeEx.HUMAN_GRENADE,             -- 手雷
    [ThrownItemCategory.RangedBuff]   = DamageTypeEx.HUMAN_FIREBOMB,            -- 燃烧弹
}

local tbArmorMap
if not GlobalVariableSystem.bUseNewBattleItem then
    tbArmorMap =
    {
        [HumanBodyDef.HUMAN_HEAD] = HumanArmorDef.ArmorCategory.Head,
        [HumanBodyDef.HUMAN_BODY] = HumanArmorDef.ArmorCategory.Body,
    }
else
    tbArmorMap =
    {
        [HumanBodyDef.HUMAN_HEAD]     = HumanArmorDef.ArmorCategory.All,
        [HumanBodyDef.HUMAN_BODY]     = HumanArmorDef.ArmorCategory.All,
        [HumanBodyDef.HUMAN_ALLFOURS] = HumanArmorDef.ArmorCategory.All,
    }
end

--------------------------------------------------------------------------------------------
-- 其他
function HumanWeaponHelper.Init()
    -- 循环包含了，所以才放这
    tbWeaponCategoryToClass =
    {
        [WeaponCategory.Melee]              = dynamic_require("HumanWeaponMelee"),          -- 刀
        [WeaponCategory.Pistol]             = dynamic_require("HumanWeaponInstant"),        -- 手枪
        [WeaponCategory.Flintlock]          = dynamic_require("HumanWeaponInstant"),        -- 燧发枪
        [WeaponCategory.Matchlock]          = dynamic_require("HumanWeaponInstant"),        -- 火绳枪
        [WeaponCategory.Crossbow]           = dynamic_require("HumanWeaponProjectile"),     -- 弩
        [WeaponCategory.Bow]                = dynamic_require("HumanWeaponBow"),            -- 弓
        [WeaponCategory.TwoHand]            = dynamic_require("HumanWeaponMelee"),          -- 双手武器
        [WeaponCategory.ThrowWeapon]        = dynamic_require("HumanWeaponDualWield"),      -- 双持
        [WeaponCategory.Wand]               = dynamic_require("HumanWeaponWand"),           -- 魔杖
    }

    tbThrownCategoryToClass =
    {
        [ThrownItemCategory.Hit]            = dynamic_require("HumanWeaponThrow"),          -- 飞刀
        [ThrownItemCategory.Explosive]      = dynamic_require("HumanWeaponThrow"),          -- 手雷
        [ThrownItemCategory.RangedBuff]     = dynamic_require("HumanWeaponThrow"),          -- 燃烧弹
        [ThrownItemCategory.VisibleEffect]  = dynamic_require("HumanWeaponThrow"),          -- 烟雾
    }
end


local function GetPairKey(nSlot, bPistol)
    if(bPistol ~= nil and bPistol == true) then
        return -nSlot
    else
        return nSlot
    end
end

local function GetPairKeyNew(nSlot, nCategory)
    if nSlot == SlotDef.PRIMARY then
        if nCategory == WeaponCategory.Pistol then
            return HumanWeaponType.HandGunPrimary
        elseif nCategory == WeaponCategory.Melee or nCategory == WeaponCategory.TwoHand then
            return HumanWeaponType.MeleePrimary
        else
            return HumanWeaponType.LongGunPrimary
        end
    elseif nSlot == SlotDef.SECONDARY then
        if nCategory == WeaponCategory.Pistol then
            return HumanWeaponType.HandGunSecondary
        elseif nCategory == WeaponCategory.Melee  or nCategory == WeaponCategory.TwoHand then
            return HumanWeaponType.MeleeSecondary
        else
            return HumanWeaponType.LongGunSecondary
        end
    else
        return HumanWeaponType.Explosive
    end
end

-- local SlotDef = HumanWeaponMisc.SlotDef
local tbBPInfosNew = {
    [HumanWeaponType.LongGunPrimary] = {
        nBPType             = HumanWeaponType.LongGunPrimary,
        szHoldedAnimKey     = AnimDef.LONG_GUN_PRIMARY_HOLDED,
        szUnholdedAnimKey   = AnimDef.LONG_GUN_PRIMARY_UNHOLDED,
        szReloadAnimKey     = AnimDef.LONG_GUN_RELOAD,
        szHoldedSocket      = "LongGunPrimaryHoldedSocket",
        szUnholdedSocket    = "LongGunPrimaryUnholdedSocket",
    },
    [HumanWeaponType.LongGunSecondary] = {
        nBPType             = HumanWeaponType.LongGunSecondary,
        szHoldedAnimKey     = AnimDef.LONG_GUN_SECONDARY_HOLDED,
        szUnholdedAnimKey   = AnimDef.LONG_GUN_SECONDARY_UNHOLDED,
        szReloadAnimKey     = AnimDef.LONG_GUN_RELOAD,
        szHoldedSocket      = "LongGunSecondaryHoldedSocket",
        szUnholdedSocket    = "LongGunSecondaryUnholdedSocket",
    },
    [HumanWeaponType.HandGunPrimary] = {
        nBPType             = HumanWeaponType.HandGunPrimary,
        szHoldedAnimKey     = AnimDef.HAND_GUN_PRIMARY_HOLDED,
        szUnholdedAnimKey   = AnimDef.HAND_GUN_PRIMARY_UNHOLDED,
        szReloadAnimKey     = AnimDef.HAND_GUN_RELOAD,
        szHoldedSocket      = "HandGunPrimaryHoldedSocket",
        szUnholdedSocket    = "HandGunPrimaryUnholdedSocket",
    },
    [HumanWeaponType.HandGunSecondary] = {
        nBPType             = HumanWeaponType.HandGunSecondary,
        szHoldedAnimKey     = AnimDef.HAND_GUN_SECONDARY_HOLDED,
        szUnholdedAnimKey   = AnimDef.HAND_GUN_SECONDARY_UNHOLDED,
        szReloadAnimKey     = AnimDef.HAND_GUN_RELOAD,
        szHoldedSocket      = "HandGunSecondaryHoldedSocket",
        szUnholdedSocket    = "HandGunSecondaryUnholdedSocket",
    },
    [HumanWeaponType.MeleePrimary] = {
        nBPType             = HumanWeaponType.MeleePrimary,
        szHoldedAnimKey     = AnimDef.MELEE_PRIMARY_HOLDED,
        szUnholdedAnimKey   = AnimDef.MELEE_PRIMARY_UNHOLDED,
        szHoldedSocket      = "MeleeHoldedSocket",
        szUnholdedSocket    = "MeleeUnholdedSocket",
    },
    [HumanWeaponType.MeleeSecondary] = {
        nBPType             = HumanWeaponType.MeleeSecondary,
        szHoldedAnimKey     = AnimDef.MELEE_SECONDARY_HOLDED,
        szUnholdedAnimKey   = AnimDef.MELEE_SECONDARY_UNHOLDED,
        szHoldedSocket      = "MeleeHoldedSocket",
        szUnholdedSocket    = "MeleeUnholdedSocket",
    },
    [HumanWeaponType.Explosive] = {
        nBPType             = HumanWeaponType.Explosive,
        szHoldedAnimKey     = AnimDef.EXPLOSIVE_HOLDED,
        szUnholdedAnimKey   = AnimDef.EXPLOSIVE_UNHOLDED,
        szHoldedSocket      = "ExplosiveHoldedSocket",
        szUnholdedSocket    = "ExplosiveHoldedSocket",
    },
}

local tbBPInfos = {
    [GetPairKey(SlotDef.PRIMARY, false)] = {
        nBPType             = HumanWeaponType.LongGunPrimary,
        szHoldedAnimKey     = "LongGunPrimaryHoldedMontage",
        szUnholdedAnimKey   = "LongGunPrimaryUnholdedMontage",
        szHoldedSocket      = "LongGunPrimaryHoldedSocket",
        szUnholdedSocket    = "LongGunPrimaryUnholdedSocket",
        szReloadAnimKey     = "LongGunReloadMontage",
    },
    [GetPairKey(SlotDef.SECONDARY, false)] = {
        nBPType             = HumanWeaponType.LongGunSecondary,
        szHoldedAnimKey     = "LongGunSecondaryHoldedMontage",
        szUnholdedAnimKey   = "LongGunSecondaryUnholdedMontage",
        szHoldedSocket      = "LongGunSecondaryHoldedSocket",
        szUnholdedSocket    = "LongGunSecondaryUnholdedSocket",
        szReloadAnimKey     = "LongGunReloadMontage",
    },
    [GetPairKey(SlotDef.PRIMARY, true)] = {
        nBPType             = HumanWeaponType.HandGunPrimary,
        szHoldedAnimKey     = "HandGunPrimaryHoldedMontage",
        szUnholdedAnimKey   = "HandGunPrimaryUnholdedMontage",
        szHoldedSocket      = "HandGunPrimaryHoldedSocket",
        szUnholdedSocket    = "HandGunPrimaryUnholdedSocket",
        szReloadAnimKey     = "HandGunReloadMontage",
    },
    [GetPairKey(SlotDef.SECONDARY, true)] = {
        nBPType             = HumanWeaponType.HandGunSecondary,
        szHoldedAnimKey     = "HandGunSecondaryHoldedMontage",
        szUnholdedAnimKey   = "HandGunSecondaryUnholdedMontage",
        szHoldedSocket      = "HandGunSecondaryHoldedSocket",
        szUnholdedSocket    = "HandGunSecondaryUnholdedSocket",
        szReloadAnimKey     = "HandGunReloadMontage",
    },
    [GetPairKey(SlotDef.PRIMARY)] = {
        nBPType             = HumanWeaponType.Melee,
        szHoldedAnimKey     = "MeleePrimaryHoldedMontage",
        szUnholdedAnimKey   = "MeleePrimaryUnholdedMontage",
        szHoldedSocket      = "MeleeHoldedSocket",
        szUnholdedSocket    = "MeleeUnholdedSocket",
    },
    [GetPairKey(SlotDef.SECONDARY)] = {
        nBPType             = HumanWeaponType.Melee,
        szHoldedAnimKey     = "MeleeSecondaryHoldedMontage",
        szUnholdedAnimKey   = "MeleeSecondaryUnholdedMontage",
        szHoldedSocket      = "MeleeHoldedSocket",
        szUnholdedSocket    = "MeleeUnholdedSocket",
    },    
    [GetPairKey(SlotDef.THROW)] = {
        nBPType             = HumanWeaponType.Explosive,
        szHoldedAnimKey     = "ExplosiveHoldedMontage",
        szUnholdedAnimKey   = "ExplosiveTakeBackMontage",
        szHoldedSocket      = "ExplosiveHoldedSocket",
        szUnholdedSocket    = "ExplosiveHoldedSocket",
    },
}

function HumanWeaponHelper.GetHumanPartDamageRatio(tbTaker, nPorpertyType)
    local szPropertyName = tbPartPropertyNames[nPorpertyType]
    if szPropertyName == "" or (szPropertyName == nil) then
        return 1
    end

    local nPartRatio = PropUtil.GetProp(tbTaker, szPropertyName)
    return nPartRatio and nPartRatio or 1
end

function HumanWeaponHelper.GetHitBodyType(pHitResult)
    local pHitComponent = GetComponentFromHitResult(pHitResult)
    if(pHitComponent == nil) then
        return nil
    end

    local szHitName = GetObjectName(pHitComponent)
    return tbPartPropertyToEnum[szHitName]
end

function HumanWeaponHelper.GetLocationByHitType(pUEActor, szType)
    if not pUEActor or not pUEActor[szType] then
        log("HumanWeaponHelper.GetLocationByHitType, returns nil, szType=", szType)
        return nil
    end

    return pUEActor[szType]:K2_GetComponentLocation()
end

function HumanWeaponHelper.GetLocationByHitTypeAndMovementState(pUEActor, szType, nMovementState)
    if not pUEActor or not pUEActor[szType] then
        return nil
    end

    local pLoc = HumanWeaponHelper.GetLocationByHitType(pUEActor, szType)

    if not pLoc then
        return nil
    end

    if nMovementState and HumanWeaponHelper.GetHumanPartProperty(szType) <= 6 then
        if pUEActor.HeadInfoUpRightLoc and pUEActor[tbMovementStateToHeadInfo[nMovementState]] then
            local nOffset = pUEActor.HeadInfoUpRightLoc.Z - pUEActor[tbMovementStateToHeadInfo[nMovementState]].Z
            pLoc.Z = pLoc.Z - nOffset
        else
            log("GetLocationByHitTypeAndMovementState, pUEActor.HeadInfoUpRightLoc or pUEActor[tbMovementStateToHeadInfo[nMovementState]] is nil, nMovementState=", nMovementState)
        end
    end
    return pLoc

end

function HumanWeaponHelper.GetHitType(szType)
    return tbPartPropertyToEnum[szType]
end

function HumanWeaponHelper.GetHumanPartPropertyName(nType)
    return tbHumanPartProperty[nType]
end

function HumanWeaponHelper.GetHumanPartProperty(szType)
    for i,v in pairs(tbHumanPartProperty) do
        if v == szType then
            return i
        end
    end
    return -1
end

function HumanWeaponHelper.OnIllegalAttack(Character, szReason)
    BattleGameModeSystem:OnHumanIllegalAttack(Character, szReason)
end

function HumanWeaponHelper.GetDamageTypeEx(tbWeapon)
    if(tbWeapon.nInstanceId == 0) then
        return DamageTypeEx.HUMAN_EMPTY_HAND
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(tbWeapon.nTemplateId)
    local nCategory = tbTemplate.nCategory
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        return tbWeaponItemCategoryToDamageEx[tbTemplate.nWeaponCategory]
    elseif(nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        return tbThrownItemCategoryToDamageEx[tbTemplate.nThrownItemCategory]
    else
        assert(false)
    end
end

function HumanWeaponHelper.ApplyDamage(tbWeapon, tbTaker, nDamage, nDamageType)
    local tbCauser = tbWeapon.OwnerComponent.Owner
    if(nDamageType == nil) then
        nDamageType = HumanWeaponHelper.GetDamageTypeEx(tbWeapon)
    end

    if(tbTaker and not tbTaker:IsDead()) then
        if RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
            nDamage = 0
        end
        ApplyDamage(tbTaker, tbCauser, nDamageType, nDamage, nil)
    end
end

function HumanWeaponHelper.ApplyDamages(tbWeapon, tbTakerIds, nDamage, nDamageType)
    local tbTaker
    local tbCauser = tbWeapon.OwnerComponent.Owner
    if(nDamageType == nil) then
        nDamageType = HumanWeaponHelper.GetDamageTypeEx(tbWeapon)
    end

    for _, nTakerId in ipairs(tbTakerIds) do
        tbTaker = GameObjectSystem:FindByInstanceId(nTakerId)
        if(tbTaker and not tbTaker:IsDead()) then
            if RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
                nDamage = 0
            end
            ApplyDamage(tbTaker, tbCauser, nDamageType, nDamage, nil)
        end
    end
end

function HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(Owner)
    return Owner.nSavedHumanCurrentWeapon
end

function HumanWeaponHelper.SaveCurrentWeaponToOwner(Owner, nInstanceId)
    Owner.nSavedHumanCurrentWeapon = nInstanceId
end

--------------------------------------------------------------------------------------------
-- 和道具相关的接口
local function ItemTypeToWeaponClass(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    assert(tbTemplate)
    local nCategory = tbTemplate.nCategory
    assert(nCategory == BattleItemCategoryDef.HUMAN_WEAPON or
            nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM)

    local RetClass = nil
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        RetClass = tbWeaponCategoryToClass[tbTemplate.nWeaponCategory]
    else
        RetClass = tbThrownCategoryToClass[tbTemplate.nThrownItemCategory]
    end
    if(not RetClass) then
        error("ItemTypeToWeaponClass failed, templateid: "..tostring(nItemTemplateId))
    end
    return RetClass
end

function HumanWeaponHelper.CreateWeaponInfo(nItemTemplateId)
    local Class = ItemTypeToWeaponClass(nItemTemplateId)
    return Class()
end

function HumanWeaponHelper.CreateEmptyHandWeapon()
    return tbWeaponCategoryToClass[WeaponCategory.Melee]()
end

function HumanWeaponHelper.UpdatePropertyWithAttachments(tbProperty, tbBaseProperty, tbEfficientAttachments)
    local tbAttachmentProperties = {}
    for _, v in pairs(tbEfficientAttachments) do
        local tbTemplate = v:GetTemplate()
        local tbProperties = tbTemplate.tbProperty
        for k, property in pairs(tbProperties) do   --遍历配件的每条属性
            local tbTemp = tbAttachmentProperties[k]
            if tbTemp == nil then
                tbTemp = {0, 1}
                tbAttachmentProperties[k] = tbTemp
            end
            if k ~= Property.FireType and k ~= Property.BulletType then -- todo@ WuJizhou 开火类型和子弹类型需要特殊处理，暂时空缺，待策划有需求时再加
                if property[3] ~= nil then  -- 替代列生效
                    tbTemp[3] = property[3]
                else    --使用加法列和乘法列
                    tbTemp[1] = tbTemp[1] + property[1]
                    tbTemp[2] = tbTemp[2] * property[2]
                end
            end
        end
    end

    -- local tbTemplate = BattleItemDataTable:GetTemplate(self:GetTemplateId())
    for _, v in pairs(TotalProperty) do
        if v ~= Property.FireType and v ~= Property.BulletType then  --todo@ WuJizhou 开火类型和子弹类型需要特殊处理，暂时空缺，待策划有需求时再加
            local nValue
            local tbP = tbAttachmentProperties[v]
            if tbP ~= nil then
                if tbP[3] ~= nil then -- 替代列生效
                    nValue = tbP[3]
                else
                    local nAddValue = tbP[1]
                    local nMultiplyValue = tbP[2]
                    nValue = (tbBaseProperty[v] + nAddValue) * nMultiplyValue
                end
            else
                nValue = tbBaseProperty[v]
            end
            if v == Property.BulletMax or
                v == Property.DecreaseBulletCount or
                v == Property.MaxSpotCount then
                nValue = math.floor(nValue)
            end
            tbProperty[v] = nValue
        end
    end
end

function HumanWeaponHelper.SetBaseProperty(tbWeapon, tbNewProperty)
    if(not tbWeapon) then
        return
    end

    local tbBaseProperty = tbWeapon.tbBaseProperty
    if(not tbBaseProperty) then
        return
    end

    for _, v in pairs(Property) do
        if v ~= Property.FireType and v ~= Property.FireType then  --todo@ WuJizhou 开火类型和子弹类型需要特殊处理，暂时空缺，待策划有需求时再加
            local nValue = tbNewProperty[v]
            if nValue == nil then
                nValue = tbBaseProperty[v]
            end
            if not nValue then
                logerror("HumanWeaponItem:SetBaseProperty error, illegal property type : ", v)
            else
                if v == Property.BulletMax or
                v == Property.DecreaseBulletCount or
                v == Property.MaxSpotCount then
                    nValue = math.floor(nValue)
                end
                tbBaseProperty[v] = nValue
            end
        end
    end
end

function HumanWeaponHelper.GetWeaponResClassPath(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if(not tbTemplate) then
        error("Find weapon failed, invalid item template: "..tostring(nItemTemplateId))
    end

    local tbRes = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    if(not tbRes or not tbRes.szEquipClassName) then
        error("Find weapon res failed, invalid res: "..tostring(nItemTemplateId))
    end

    return tbRes.szEquipClassName
end

function HumanWeaponHelper.GetWeaponResClass(nItemTemplateId)
    local szPath = HumanWeaponHelper.GetWeaponResClassPath(nItemTemplateId)
    local pRes = szPath:load()
    if(not isvalidhandle(pRes)) then
        error("Weapon res class is invalid: "..tostring(nItemTemplateId)..", "..szPath)
    end
    return pRes
end

function HumanWeaponHelper.GetWeaponLaunchClass(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if(not tbTemplate) then
        error("Find weapon failed, invalid item template: "..tostring(nItemTemplateId))
    end

    local tbRes = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    if(not tbRes or not tbRes.szLaunchClassName) then
        error("Find weapon res failed, invalid res: "..tostring(nItemTemplateId))
    end

    local pRes = tbRes.szLaunchClassName:load()
    if(not isvalidhandle(pRes)) then
        error("Weapon res class is invalid: "..tostring(nItemTemplateId)..", "..tbRes.szLaunchClassName)
    end
    return pRes
end


function HumanWeaponHelper.GetWeaponSlot(tbItem)
    local tbTemplate = tbItem:GetTemplate()
    local nCategory = tbTemplate.nCategory
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        if not GlobalVariableSystem.bUseNewBattleItem then
            local nPrimaryCategory = tbTemplate.nPrimaryCategory
            if nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
                return SlotDef.MELEE
            else
                local nSlotIndex = tbItem:GetStorageLocation().nSlotIndex
                if nSlotIndex == 1 then
                    return SlotDef.PRIMARY
                else
                    return SlotDef.SECONDARY
                end
            end
        else
            local nSlotIndex = tbItem:GetStorageLocation().nSlotIndex
            if nSlotIndex == 1 then
                return SlotDef.PRIMARY
            else
                return SlotDef.SECONDARY
            end
        end
    elseif(nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        return SlotDef.THROW
    else
        assert(false)
    end
end

function HumanWeaponHelper.GetWeaponCategory(nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if(not tbTemplate) then
        return 0
    end
    local nCategory = tbTemplate.nCategory

    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        return tbTemplate.nWeaponCategory
    elseif(nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        return tbTemplate.nThrownItemCategory
    end
    return 0
end

function HumanWeaponHelper.IsPistol(nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if(not tbTemplate) then
        return false
    end
    local nCategory = tbTemplate.nCategory
    if nCategory ~= BattleItemCategoryDef.HUMAN_WEAPON then
        return false
    end

    return tbTemplate.nWeaponCategory == HumanWeaponDef.WeaponCategory.Pistol
end

function HumanWeaponHelper.ReloadAmmo(nInstanceId)
    assert(GlobalVariableSystem:IsServerLogic())
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbItem = BattleItemSystemServer:GetItem(nInstanceId)
    assert(tbItem)
    local tbTemplate = tbItem:GetTemplate()
    if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        return
    end
    local nCharacterInstanceId = tbItem:GetOwnerCharacterInstanceId()
    local nCount = tbItem:GetBulletMax()
    if not HumanWeaponHelper.IsBulletInfinite() then
        local nMaxCount = BattleItemSystemServer:GetUnequippedItemCount(nCharacterInstanceId, tbTemplate.nBulletType)
        nCount = nCount > nMaxCount and nMaxCount or nCount
    end
    BattleItemSystemServer:EquipStackableItem(nCharacterInstanceId, nInstanceId, tbTemplate.nBulletType, nCount)
    return tbItem:GetCurrentAmmoCount(false), nCount
end

function HumanWeaponHelper.GetAmmoInfo(nInstanceId)
    local bClient = not GlobalVariableSystem:IsServerLogic()
    local Item = BattleItemSystemHelper:GetItem(nInstanceId, bClient)
    assert(Item)
    if(Item:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        return nil
    end
    return Item:GetCurrentAmmoCount(bClient), Item:GetBulletMax()
end

function HumanWeaponHelper.GetUnequipedAmmoCount(nInstanceId)
    local bClient = not GlobalVariableSystem:IsServerLogic()
    local Item = BattleItemSystemHelper:GetItem(nInstanceId, bClient)
    assert(Item)
    if(Item:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        return nil
    end
    return Item:GetUnequipedMatchingAmmoCount(bClient)
end

function HumanWeaponHelper.IsBulletInfinite()
    return BattleItemSystemHelper:IsHumanBulletInfinite()
end

function HumanWeaponHelper.DecreaseAmmo(nInstanceId, nCount)
    local Item = BattleItemSystemHelper:GetItem(nInstanceId, false)
    Item:DecreaseAmmoCount(nCount)
end

function HumanWeaponHelper.RemoveThrownItem(nInstanceId)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbAmmo =  BattleItemSystemHelper:GetItem(nInstanceId, false)
    assert(tbAmmo)
    BattleItemSystemServer:DecreaseItemCount(nInstanceId, 1)
end

function HumanWeaponHelper.GetCurrentThrownItemCount(tbThrowWeapon)
    return BattleItemSystemHelper:GetUnequippedItemCount(
        tbThrowWeapon.Owner:GetServerInstanceId(),
        tbThrowWeapon:GetTemplateId(),
        not GlobalVariableSystem:IsServerLogic())
end

local function GetArmorItemByType(nCharacterInstanceId, nType)
    assert(GlobalVariableSystem:IsServerLogic())
    local nSlotIndex
    local nArmorCategory = tbArmorMap[nType]
    for nIdx, v in ipairs(HumanArmorSlotDef.ArmorSlots) do
        if v == nArmorCategory then
            nSlotIndex = nIdx
            break
        end
    end
    if not nSlotIndex then
        return
    end
    local tbArmorItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId, nSlotIndex, false)
    return tbArmorItem
end

function HumanWeaponHelper.DecreaseArmorDurability(nCharacterInstanceId, nType, nValue)
    assert(GlobalVariableSystem:IsServerLogic())
    local tbArmorItem = GetArmorItemByType(nCharacterInstanceId, nType)
    if not tbArmorItem then
        return
    end
    local nDurability = tbArmorItem.nDurability
    local tbTemplate = tbArmorItem:GetTemplate()
    local bDestroyedOnZero = tbTemplate.bDestroyedOnZeroDurability
    if bDestroyedOnZero then
        assert(nDurability > 0)
    end
    local bDirty = true
    if nValue == 0 or nDurability == 0 then
        bDirty = false
    end
    nDurability = nDurability - nValue
    nDurability = nDurability > 0 and math.floor(nDurability) or 0
    local nItemInstanceId = tbArmorItem:GetInstanceId()
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_SERVER, nItemInstanceId, nDurability)
    if nDurability == 0 and bDestroyedOnZero then
        local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
        BattleItemSystemServer:DestroyPlayerItem(nCharacterInstanceId, nItemInstanceId)
    else
        if bDirty then
            tbArmorItem:SetDurability(nDurability)
            local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
            BattleItemSystemServer:SyncDurability(nItemInstanceId)
        end
    end
end

local function GetCurrentWeaponItemCountInfo(WeaponComponent, nWeaponInstanceId)
    nWeaponInstanceId = nWeaponInstanceId > 0 and nWeaponInstanceId or -nWeaponInstanceId
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, false)
    local nTemplateId = 0
    local nBulletCount = 0
    local nBulletMax = 0
    if WeaponItem then
        nTemplateId = WeaponItem:GetTemplateId()
        if WeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
            nBulletCount = BattleItemSystemHelper:GetUnequippedItemCount(WeaponComponent.Owner.nServerInstanceId, WeaponItem:GetTemplateId(), false)
            nBulletMax = nBulletCount
        else
            local nPrimaryCategory = WeaponItem:GetTemplate().nPrimaryCategory
            if nPrimaryCategory ~= HumanWeaponDef.WeaponPrimaryCategory.Melee then
                nBulletCount = WeaponItem:GetCurrentAmmoCount(false)
                nBulletMax = 0
                if WeaponItem:IsBulletInfinite() then
                    nBulletMax = WeaponItem.tbProperty[HumanWeaponDef.Property.BulletMax]
                else
                    nBulletMax = WeaponItem:GetUnequipedMatchingAmmoCount(false)
                end
            end
        end
    end
    return nTemplateId, nBulletCount, nBulletMax
end

function HumanWeaponHelper.SendWeaponAmmoInfoToViewers(WeaponComponent, nWeaponInstanceId)
    if(not GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local nControllerId = WeaponComponent.Owner.nUEControllerUniqueId
    if(nControllerId == nil) then
        return
    end

    local nTemplateId, nBulletCount, nBulletMax = GetCurrentWeaponItemCountInfo(WeaponComponent, nWeaponInstanceId)
    TeamWatchServerHelper.NotifyViewersWeaponBullet(WeaponComponent.Owner, nTemplateId, nBulletCount, nBulletMax)
end


function HumanWeaponHelper.GetArmorFactorOld(nCharacterInstanceId, nType)
    assert(GlobalVariableSystem:IsServerLogic())
    local tbArmorItem = GetArmorItemByType(nCharacterInstanceId, nType)
    if tbArmorItem == nil then
        return DEFAULT_ARMOR_FACTOR
    end
    if tbArmorItem:GetDurability() <= 0 then
        return DEFAULT_ARMOR_FACTOR
    end
    if nType == HumanBodyDef.HUMAN_HEAD then
        return tbArmorItem.tbProperty.nReduceHeadDamage
    elseif nType == HumanBodyDef.HUMAN_BODY then
        return tbArmorItem.tbProperty.nReduceBodyDamage
    else
        return DEFAULT_ARMOR_FACTOR
    end
end

function HumanWeaponHelper.GetArmorFactorNew(nCharacterInstanceId, nWeaponDamageType, nHumanBodyType)
    assert(GlobalVariableSystem:IsServerLogic())
    local tbArmorItem = GetArmorItemByType(nCharacterInstanceId, nHumanBodyType)
    if tbArmorItem == nil then
        return DEFAULT_ARMOR_FACTOR
    end
    if tbArmorItem:GetDurability() <= 0 then
        return DEFAULT_ARMOR_FACTOR
    end
    local nFactor = HumanArmorItemPropertyHelper.GetReduceDamageFactor(tbArmorItem, nWeaponDamageType, nHumanBodyType)
    if not nFactor then
        return DEFAULT_ARMOR_FACTOR
    else
        return nFactor
    end
end

local function ReplaceGetArmorFactorfunction()
    if GlobalVariableSystem.bUseNewBattleItem then
        HumanWeaponHelper.GetArmorFactor = HumanWeaponHelper.GetArmorFactorNew
    else
        HumanWeaponHelper.GetArmorFactor = HumanWeaponHelper.GetArmorFactorOld
    end
end

ReplaceGetArmorFactorfunction()


function HumanWeaponHelper.CreateCommonWeaponProperty(nTemplateId, bCreateForEmptyHanded)
    return HumanWeaponItemPropertyHelper.CreateProperty(nTemplateId, bCreateForEmptyHanded)
end

function HumanWeaponHelper.CreateThrownWeaponProperty(nTemplateId)
    return HumanThrownItemPropertyHelper.CreateProperty(nTemplateId)
end

function HumanWeaponHelper.CheckAndPlayHoldToAim(tbCharacter, bAiming)
    if not TeamWatchClientHelper then
        TeamWatchClientHelper= require("TeamWatchClientHelper")
    end

    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    local bWatch = nCurrentWatchId == tbCharacter:GetServerInstanceId()

    local bRun = HumanWeaponHelper.IsSprintRuning(tbCharacter)
    local bPlayerSelf = tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf
    --客户端自己因为狙击枪会有缩镜的动画，所以不播动作了，防止穿帮，只给其他人播
    if (not bRun) and bAiming and (not bPlayerSelf) and (not bWatch) then
        tbCharacter.HumanWeaponComponent:PlayMontageWithAnimKey(AnimDef.ON_GUN_HOLD_TO_AIM)
    end
end

function HumanWeaponHelper.ChangeWeaponActorStateForAim(tbCharacter, pWeaponActor, bAiming)
    if not pWeaponActor or not tbCharacter then
        return
    end

    if not GameCameraSystem then
        GameCameraSystem = require("GameCameraSystem")
        GameCameraModeGroupDef = require("GameCameraModeGroupDef")
        TeamWatchClientHelper= require("TeamWatchClientHelper")
    end

    local bWatchHumanMode = GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.ViewTeammateHuman)
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    local bWatchHumanPlayer = nCurrentWatchId == tbCharacter:GetServerInstanceId()
    local bOtherAiming = tbCharacter.ObjectType == GameObjectTypeDef.PlayerOther
    local bWatchBattleModeAim = bWatchHumanMode and bWatchHumanPlayer and bOtherAiming

    local bPlayerSelf = tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf
    if bWatchBattleModeAim or bPlayerSelf then
        ExtendBlueprintFunctions.SetLargeCoordPrecisionOptimize(pWeaponActor, bAiming)
        EngineExtActorShell.SetActorSkeletalMeshCastShadow(pWeaponActor, not bAiming)
    end
end

function HumanWeaponHelper.IsHumanAiming(tbCharacter)
    if tbCharacter and tbCharacter:IsHuman() then
        local HumanWeaponComponent = tbCharacter.HumanWeaponComponent
        if HumanWeaponComponent and HumanWeaponComponent:IsAiming() then
            return true
        end
    end
    return false
end

function HumanWeaponHelper.IsCurrentSniperAim(tbPlayer)
    local nTemplateId = tbPlayer.HumanWeaponComponent:GetCurrentWeaponTemplateId()
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate then
        return tbTemplate.bUseSniperUi
    end
    return false
end

--------------------------------------------------------------------------------------------
-- 从component内部或者weapon内部发包走这
function HumanWeaponHelper.SendSetCurrentWeaponRequest(nInstanceId, bTemporary)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    if bTemporary then 
        NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanWeaponSetCurrentTemporary, PACKET_WEAPON_ID_ONLY)
    else
        NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanWeaponSetCurrent, PACKET_WEAPON_ID_ONLY)
    end
end

local tbTempCurrentWeaponPacket = {}
function HumanWeaponHelper.SendCurrentWeaponToClient(WeaponComponent, nWeaponInstanceId, bForce)
    if(not GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local nControllerId = WeaponComponent.Owner.nUEControllerUniqueId
    if(nControllerId == nil) then
        return
    end
    tbTempCurrentWeaponPacket.weapon_id = nWeaponInstanceId
    tbTempCurrentWeaponPacket.force = bForce
    NetworkManager:GetRPCNetworkProxy():SendToClient(nControllerId, Proto.d2c_HumanSetCurrentWeapon, tbTempCurrentWeaponPacket)
end

function HumanWeaponHelper.SendReloadRequest(nInstanceId, nTime)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local tbPacket = {
        weapon_id = nInstanceId,
        time = nTime,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanWeaponReload, tbPacket)
end

function HumanWeaponHelper.SendCancelReloadRequest(nInstanceId)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanWeaponCancelReload, PACKET_WEAPON_ID_ONLY)
end

function HumanWeaponHelper.TryReload(WeaponComponent)
    if(WeaponComponent and WeaponComponent.bPlayerSelf ) then
        local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
        if(not tbCurrentWeapon or not tbCurrentWeapon:IsType(HumanWeaponMisc.Type.GUN)) then
            return
        end

        if(tbCurrentWeapon:GetCurrentAmmo() == 0) then
            WeaponComponent:Reload()
        end
    end
end

function HumanWeaponHelper.SendAttackStart()
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanAttackStart)
end

function HumanWeaponHelper.SendAttackEnd()
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanAttackEnd)
end

function HumanWeaponHelper.SendGunAttackOnceRequest(nInstanceId, nTaker, tbStart, tbEnd, nHitBodyType, nProjectileIndex)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    if not nProjectileIndex then
        nProjectileIndex = 0
    end

    local tbPacket = {
        weapon_id = nInstanceId,
        taker = nTaker,
        start = tbStart,
        end_pos = tbEnd,
        hit_type = nHitBodyType,
        index = nProjectileIndex, 
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanGunAttackOnceRequest, tbPacket)
end

function HumanWeaponHelper.SendGunAttackMultiRequest(nInstanceId, tbTakers, tbStart, tbEnds, tbHitBodyTypes, tbMissEnds, tbIndexes)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    if not tbIndexes then
        tbIndexes = {}
        tbIndexes[1] = 0
    end

    local tbPacket = {
        weapon_id = nInstanceId,
        takers = tbTakers,
        start = tbStart,
        hit_ends = tbEnds,
        hit_types = tbHitBodyTypes,
        miss_ends = tbMissEnds,
        indexes = tbIndexes,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanGunAttackMultiRequest, tbPacket)
end

-- function HumanWeaponHelper.SendGunAttackResponse(Owner, tbStart, tbEnds)
--     if(GlobalVariableSystem:IsClient()) then
--         return
--     end

--     local nUEControllerUniqueId = Owner.nUEControllerUniqueId
--     if(nUEControllerUniqueId == nil) then
--         return
--     end

--     local tbPacket = {
--         start = tbStart,
--         ends = tbEnds,
--     }
--     NetworkManager:GetRPCNetworkProxy():SendToClient(nUEControllerUniqueId, Proto.d2c_HumanGunAttackResponse, tbPacket)
-- end

function HumanWeaponHelper.SendGunAttackRoute(nInstanceId, tbStart, tbEnd, bMultiEnd, nAccumulateTime, tbIndexes)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local tbEnds = tbEnd
    if(not bMultiEnd) then
        tbTempTable[1] = tbEnd
        tbEnds = tbTempTable
    end

    if not tbIndexes then
        tbIndexes = {}
        tbIndexes[1] = 0
    end

    local tbPacket = {
        weapon_id = nInstanceId,
        start = tbStart,
        ends = tbEnds,
        accumulate_time = nAccumulateTime,
        indexes = tbIndexes,
    }
    return NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanGunAttackRoute, tbPacket)
end

function HumanWeaponHelper.SendBowPreAttack(nInstanceId)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end


    local tbPacket = {
        weapon_id = nInstanceId,
    }
    return NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanBowPreAttack, tbPacket)
end

function HumanWeaponHelper.HumanAttackSubstateRequest(nInstanceId, nSubstate)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end


    local tbPacket = {
        weapon_id = nInstanceId,
        substate = nSubstate,
    }
    logdebug("pre attack bow lzz2")
    return NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanAttackSubstateRequest, tbPacket)
end

function HumanWeaponHelper.SendCancelBowAttack(nInstanceId)
    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanCancelBowAttack, PACKET_WEAPON_ID_ONLY)
end

function HumanWeaponHelper.SendProjectAttackRoute(nInstanceId, tbStart, tbEnd, bMultiEnd, tbProjectileIndexs)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local tbEnds = tbEnd
    if(not bMultiEnd) then
        tbTempTable[1] = tbEnd
        tbEnds = tbTempTable
    end

    if not tbProjectileIndexs then
        tbProjectileIndexs = {}
        tbProjectileIndexs[1] = 0
    end

    local tbPacket = {
        weapon_id = nInstanceId,
        start = tbStart,
        ends = tbEnds,
        indexes = tbProjectileIndexs,
    }
    return NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanProjectAttackRoute, tbPacket)
end

function HumanWeaponHelper.SendDualWieldAttack(nInstanceId, bLeft)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end


    local tbPacket = {
        weapon_id = nInstanceId,
        left_weapon = bLeft,
    }
    return NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanDualWieldAttack, tbPacket)
end

local tbAttackRequestPacket = {}
function HumanWeaponHelper.SendAttackRequest(nInstanceId, tbTakerIds)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    tbAttackRequestPacket.weapon_id = nInstanceId
    tbAttackRequestPacket.takers = tbTakerIds
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanAttackRequest, tbAttackRequestPacket)
end

local tbMeleeAttackRoutePacket = {}
function HumanWeaponHelper.SendMeleeAttackRoute(nInstanceId, nMontageIndex, bJumping, StartPos, Yaw)
    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    tbMeleeAttackRoutePacket.weapon_id = nInstanceId
    tbMeleeAttackRoutePacket.montage_index = nMontageIndex
    tbMeleeAttackRoutePacket.in_jumping = bJumping
    tbMeleeAttackRoutePacket.start = StartPos
    if Yaw ~= nil then 
        tbMeleeAttackRoutePacket.yaw = math.floor(Yaw)
    end
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanMeleeAttackRoute, tbMeleeAttackRoutePacket)
end

function HumanWeaponHelper.SendHoldThrownWeapon(nInstanceId)
    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanHoldThrownWeapon, PACKET_WEAPON_ID_ONLY)
end

function HumanWeaponHelper.SendUnholdThrownWeapon()
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanUnholdThrownWeapon)
end

function HumanWeaponHelper.SendSelectThrownWeapon(nInstanceId)
    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanSelectThrownWeapon, PACKET_WEAPON_ID_ONLY)
end

function HumanWeaponHelper.SendChangeThrowType(nInstanceId, bHigh)
    local tbPacket = {
        weapon_id = nInstanceId,
        high = bHigh,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanChangeThrowType, tbPacket)
end

function HumanWeaponHelper.SendThrowReady(nInstanceId, bHigh)
    local tbPacket = {
        weapon_id = nInstanceId,
        high = bHigh,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanThrowReady, tbPacket)
end

function HumanWeaponHelper.SendThrowExplodeBegin(nInstanceId)

    local tbPacket = {
        weapon_id = nInstanceId,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanThrowExplodeBegin, tbPacket)
end

function HumanWeaponHelper.SendCancelThrow(nInstanceId)

    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanCancelThrow, PACKET_WEAPON_ID_ONLY)
end

function HumanWeaponHelper.SendBeginThrow(nInstanceId)
    local tbPacket = {
        weapon_id = nInstanceId,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanBeginThrowRequest, tbPacket)
end

function HumanWeaponHelper.SendThrowRequest(nInstanceId, tbPos, nTime)
    local tbPacket = {
        weapon_id = nInstanceId,
        pos = tbPos,
        time = nTime,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanThrowRequest, tbPacket)
end

function HumanWeaponHelper.SendThrowAllFinishedClient(Object, nInstanceId)
    local nUEControllerUniqueId = Object.nUEControllerUniqueId
    if(nUEControllerUniqueId == nil) then
        return
    end

    PACKET_WEAPON_ID_ONLY.weapon_id = nInstanceId
    NetworkManager:GetRPCNetworkProxy():SendToClient(nUEControllerUniqueId, Proto.d2c_HumanThrowResponse, PACKET_WEAPON_ID_ONLY)
end

function HumanWeaponHelper.ServerChangeWeaponState(Owner)
    if(not GlobalVariableSystem:IsServerLogic()) then
        return
    end

    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, 0, Owner)
end

function HumanWeaponHelper.ServerAttackEvent(Owner, nInstanceId)
    if not GlobalVariableSystem:IsServerLogic() then
        return
    end
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACK_IN_SERVER, Owner:GetServerInstanceId(), nInstanceId)
end

function HumanWeaponHelper.GetWeaponBPInfo(nSlot, nTemplateId)
    if GlobalVariableSystem.bUseNewBattleItem then
        local nCategory = WeaponCategory.Melee

        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        if( tbTemplate) then
            nCategory = tbTemplate.nWeaponCategory
        end
        -- logdebug("nCategory", nCategory, "nSlot", nSlot)
        return tbBPInfosNew[GetPairKeyNew(nSlot, nCategory)]
    else
        return tbBPInfos[GetPairKey(nSlot, HumanWeaponHelper.IsPistol(nTemplateId))]
    end
end

function HumanWeaponHelper.IsSprintRuning(Object)
    if Object and Object.HumanMovementStateComponent then
        return Object.HumanMovementStateComponent:GetRun()
    end
    return false
end

function HumanWeaponHelper.GetMatchedSlotIndexes(nItemTemplateId)
    local tbSlots = {}
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local tbMatchedSlotTypes = tbTemplate.tbMatchedSlotTypes
    if #tbMatchedSlotTypes == 0 then
        return tbSlots
    end
    for nSlotIndex, nSlotType in ipairs(HumanWeaponSlotDef.Slots) do
        for __, nMatchedType in ipairs(tbMatchedSlotTypes) do
            if nSlotType & nMatchedType ~= 0 then
                table.insert(tbSlots, nSlotIndex)
            end
        end
    end
    return tbSlots
end

function HumanWeaponHelper.CanBeAttacked(tbObject)
    if not tbObject then
        return false
    end
    local nObjectType = tbObject.ObjectType
    if ((nObjectType == GameObjectTypeDef.PlayerSelf)
    or (nObjectType == GameObjectTypeDef.Npc and (tbObject:GetNpcType() ~= GameNpcType.BattleCollection))
    or (nObjectType == GameObjectTypeDef.PlayerOther)
    or (nObjectType == GameObjectTypeDef.DestructibleObject)) 
    or (nObjectType == GameObjectTypeDef.Horse) then
        return true
    end

    return false
end

function HumanWeaponHelper.GetWeaponHoldSocket(pPlayer, nTemplateId, nSlot)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if(not tbTemplate) then
        return nil
    end
    if pPlayer.ObjectType == GameObjectTypeDef.Npc then 
        return tbTemplate.szHoldSocketNpc
    end  
    local tbHumanTable = HumanDataTable:GetTemplate(pPlayer:GetTemplateId())
    if not tbHumanTable then 
        logwarning("GetWeaponHoldSocket Can't Find Human TemplateID ", pPlayer:GetTemplateId())
        return tbTemplate.szHoldSocketMale
    end 
    if tbHumanTable.nGender == GenderTypeDef.MALE then 
        return tbTemplate.szHoldSocketMale
    else 
        return tbTemplate.szHoldSocketFemale
    end

end

function HumanWeaponHelper.GetWeaponUnHoldSocket(nTemplateId, nSlot)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if(not tbTemplate) then
        return nil
    end

    if nSlot == SlotDef.PRIMARY then
        return tbTemplate.szUnholdPrimarySocket
    elseif nSlot == SlotDef.SECONDARY then
        return tbTemplate.szUnholdSecondarySocket
    end
    return nil
end

function HumanWeaponHelper.GetHumanCapsuleHalfHeight(GamePlayer)
    if not GamePlayer then
        return 0
    end

    if not GamePlayer.HumanMovementStateComponent then
        return 0
    end

    local tbCapsuleData = HumanCapsuleDataTable:GetTemplate(GamePlayer:GetHumanTemplateId(), GamePlayer.HumanMovementStateComponent:GetCurrentState())

    if not tbCapsuleData then
        return 0
    end

    return tbCapsuleData.nCapsuleHalfHeight and tbCapsuleData.nCapsuleHalfHeight or 0
end

return HumanWeaponHelper