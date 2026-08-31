-----------------------------------------------------
--File Name    : HumanAvatarDef.lua
--Author       : WuJizhou
--Create Time  : 4/1/2020, 8:53:11 PM
--Description  : HumanAvatarDef
-----------------------------------------------------
local HumanAvatarDef = {}


HumanAvatarDef.PLACE_HOLDER_PART_VALUE_INCLUDE_APPEARANCE = math.maxinteger
HumanAvatarDef.PLACE_HOLDER_PART_VALUE_WITHOUT_APPEARANCE = 0

HumanAvatarDef.FashionSlotCategory =
{
    Hat       = 1,
    Upper     = 2,
    Lower     = 3,
    Shoe      = 4,
}

-- 策划设计和ui上都存在套装的概念，但是时装本身槽位的程序设计上并不存在套装的概念
-- 以此枚举区别于FashionSlotCategory
-- 通过metatable 包含FashionSlotCategory
HumanAvatarDef.FashionSlotCategoryExtend =
{
    Suit      = 5,
}

local fnNext = function (tb, key)
    local nk, nv
    nk = key
    local tbBase = HumanAvatarDef.FashionSlotCategory
    if rawget(tb, nk) and rawget(tbBase, nk) then
        error("duplicate key in FashionSlotCategoryExtend and FashionSlotCategory!")
    end
    if rawget(tb, nk) or not nk then
        nk, nv = next(tb, nk)
    end
    if not nv then
        nk, nv = next(tbBase, nk)
    end
    return nk, nv
end

local fnPairs = function (tb)
    return fnNext, tb, nil
end

local fnIndex = function (tb, key)
    local ret = rawget(tb, key)
    local tbBase = HumanAvatarDef.FashionSlotCategory
    if not ret then
        ret = tbBase[key]
    end
    return ret
end

local fnNewIndex = function(tb, key, value)
    error("this table should be read-only!")
end

local FashionSlotCategoryExtendMT = {}
FashionSlotCategoryExtendMT.__index = fnIndex
FashionSlotCategoryExtendMT.__newindex = fnNewIndex
FashionSlotCategoryExtendMT.__pairs = fnPairs
setmetatable(HumanAvatarDef.FashionSlotCategoryExtend, FashionSlotCategoryExtendMT)

local FashionSlotCategory = HumanAvatarDef.FashionSlotCategory

local FashionSlotCategoryToConfigName = {}
FashionSlotCategoryToConfigName[FashionSlotCategory.Hat]        = "hat_slot"
FashionSlotCategoryToConfigName[FashionSlotCategory.Upper]      = "upper_slot"
FashionSlotCategoryToConfigName[FashionSlotCategory.Lower]      = "lower_slot"
FashionSlotCategoryToConfigName[FashionSlotCategory.Shoe]       = "shoe_slot"
HumanAvatarDef.FashionSlotCategoryToConfigName = FashionSlotCategoryToConfigName

-- 概念上，part type与part id/color id相对应
HumanAvatarDef.PartType =
{
    Hat       = 1,
    Hair      = 2,
    Head      = 3,
    Upper     = 4,
    Lower     = 5,
    Shoe      = 6,
    HairColor = 7,
    SkinColor = 8,
}



local PartType = HumanAvatarDef.PartType

local PartTypeToConfigName = {}
PartTypeToConfigName[PartType.Hat]        = "hat"
PartTypeToConfigName[PartType.Hair]       = "hair"
PartTypeToConfigName[PartType.Head]       = "head"
PartTypeToConfigName[PartType.Upper]      = "upper"
PartTypeToConfigName[PartType.Lower]      = "lower"
PartTypeToConfigName[PartType.Shoe]       = "shoe"
PartTypeToConfigName[PartType.HairColor]  = "hair_color"
PartTypeToConfigName[PartType.SkinColor]  = "skin_color"

HumanAvatarDef.PartTypeToConfigName = PartTypeToConfigName


HumanAvatarDef.PartName =
{
    Hat       = "HumanHat",
    Hair      = "HumanHair",
    Head      = "HumanHead",
    Upper     = "HumanUpper",
    Lower     = "HumanLower",
    Shoe      = "HumanShoe",
    HairColor = "HairColor",  --当前并不是真的一个part
    SkinColor = "SkinColor",  --当前并不是真的一个part
}

local PartTypeToPartName = {}
PartTypeToPartName[PartType.Hat]        = HumanAvatarDef.PartName.Hat
PartTypeToPartName[PartType.Hair]       = HumanAvatarDef.PartName.Hair
PartTypeToPartName[PartType.Head]       = HumanAvatarDef.PartName.Head
PartTypeToPartName[PartType.Upper]      = HumanAvatarDef.PartName.Upper
PartTypeToPartName[PartType.Lower]      = HumanAvatarDef.PartName.Lower
PartTypeToPartName[PartType.Shoe]       = HumanAvatarDef.PartName.Shoe
PartTypeToPartName[PartType.HairColor]  = HumanAvatarDef.PartName.HairColor
PartTypeToPartName[PartType.SkinColor]  = HumanAvatarDef.PartName.SkinColor
HumanAvatarDef.PartTypeToPartName = PartTypeToPartName

HumanAvatarDef.ProtoFieldName =
{
    Hat       = "hat",
    Hair      = "hair",
    Head      = "head",
    Upper     = "upper",
    Lower     = "lower",
    Shoe      = "shoe",
    HairColor = "hair_color",
    SkinColor = "skin_color",
}


local PartTypeToProtoFieldName = {}
PartTypeToProtoFieldName[PartType.Hat]        = HumanAvatarDef.ProtoFieldName.Hat
PartTypeToProtoFieldName[PartType.Hair]       = HumanAvatarDef.ProtoFieldName.Hair
PartTypeToProtoFieldName[PartType.Head]       = HumanAvatarDef.ProtoFieldName.Head
PartTypeToProtoFieldName[PartType.Upper]      = HumanAvatarDef.ProtoFieldName.Upper
PartTypeToProtoFieldName[PartType.Lower]      = HumanAvatarDef.ProtoFieldName.Lower
PartTypeToProtoFieldName[PartType.Shoe]       = HumanAvatarDef.ProtoFieldName.Shoe
PartTypeToProtoFieldName[PartType.HairColor]  = HumanAvatarDef.ProtoFieldName.HairColor
PartTypeToProtoFieldName[PartType.SkinColor]  = HumanAvatarDef.ProtoFieldName.SkinColor
HumanAvatarDef.PartTypeToProtoFieldName = PartTypeToProtoFieldName


local ProtoFieldNameToPartName = {}
ProtoFieldNameToPartName[HumanAvatarDef.ProtoFieldName.Hat]   = HumanAvatarDef.PartName.Hat
ProtoFieldNameToPartName[HumanAvatarDef.ProtoFieldName.Hair]  = HumanAvatarDef.PartName.Hair
ProtoFieldNameToPartName[HumanAvatarDef.ProtoFieldName.Head]  = HumanAvatarDef.PartName.Head
ProtoFieldNameToPartName[HumanAvatarDef.ProtoFieldName.Upper] = HumanAvatarDef.PartName.Upper
ProtoFieldNameToPartName[HumanAvatarDef.ProtoFieldName.Lower] = HumanAvatarDef.PartName.Lower
ProtoFieldNameToPartName[HumanAvatarDef.ProtoFieldName.Shoe]  = HumanAvatarDef.PartName.Shoe
HumanAvatarDef.ProtoFieldNameToPartName = ProtoFieldNameToPartName



local SlotTypeToPartType = {}
SlotTypeToPartType[FashionSlotCategory.Hat] = {PartType.Hat}
SlotTypeToPartType[FashionSlotCategory.Upper] = {PartType.Upper}
SlotTypeToPartType[FashionSlotCategory.Lower] = {PartType.Lower}
SlotTypeToPartType[FashionSlotCategory.Shoe] = {PartType.Shoe}
HumanAvatarDef.SlotTypeToPartType = SlotTypeToPartType


HumanAvatarDef.FashionType =
{
    Basic   = 1,
    Knight  = 2,
    Light   = 3,
    Robe    = 4,
    Stealth = 5,
}
return HumanAvatarDef