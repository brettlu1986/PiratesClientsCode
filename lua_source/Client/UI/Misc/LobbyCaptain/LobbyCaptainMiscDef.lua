-----------------------------------------------------
--File Name    : LobbyCaptainMiscDef.lua
--Author       : WuJizhou
--Create Time  : 5/8/2020, 9:00:42 PM
--Description  : LobbyCaptainMiscDef
-----------------------------------------------------
local LobbyCaptainMiscDef = {}
local HumanAvatarDef = require("HumanAvatarDef")

local FashionSlotCategoryExtend = HumanAvatarDef.FashionSlotCategoryExtend

LobbyCaptainMiscDef.MaxArmorDescCount = 6

LobbyCaptainMiscDef.UnarmedWeaponInstanceType = 0

LobbyCaptainMiscDef.FeatureType =
{
    Visual      = 1,
    Decoration  = 2,
    PlaceHolder1= 3,
    PlaceHolder2= 4,
}

LobbyCaptainMiscDef.NOT_IN_BAG_ID = -1


LobbyCaptainMiscDef.Levels =
{
    Level1 = 1,
    Level2 = 2,
    Level3 = 3,
}


LobbyCaptainMiscDef.LevelToIndex =
{
    [LobbyCaptainMiscDef.Levels.Level1] = 3,
    [LobbyCaptainMiscDef.Levels.Level2] = 2,
    [LobbyCaptainMiscDef.Levels.Level3] = 1,
}

local IndexToLevel = {}

local function InitIndexToLevel()
    for nLevel, nIndex in pairs(LobbyCaptainMiscDef.LevelToIndex) do
        IndexToLevel[nIndex] = nLevel
    end
end

InitIndexToLevel()

LobbyCaptainMiscDef.IndexToLevel = IndexToLevel



local SlotCategoryExtendToTabIndex = {}
SlotCategoryExtendToTabIndex[FashionSlotCategoryExtend.Suit] = 1
SlotCategoryExtendToTabIndex[FashionSlotCategoryExtend.Hat] = 2
SlotCategoryExtendToTabIndex[FashionSlotCategoryExtend.Upper] = 3
SlotCategoryExtendToTabIndex[FashionSlotCategoryExtend.Lower] = 4
SlotCategoryExtendToTabIndex[FashionSlotCategoryExtend.Shoe] = 5

local TabIndexToSlotCategoryExtend = {}

local function ParseToSlotCategoryExtendFromTabIndex()
    for nCategory, nIndex in pairs(SlotCategoryExtendToTabIndex) do
        TabIndexToSlotCategoryExtend[nIndex] = nCategory
    end
end

ParseToSlotCategoryExtendFromTabIndex()

LobbyCaptainMiscDef.FashionSlotCategoryExtendToTabIndex = SlotCategoryExtendToTabIndex
LobbyCaptainMiscDef.TabIndexToFashionSlotCategoryExtend = TabIndexToSlotCategoryExtend

return LobbyCaptainMiscDef