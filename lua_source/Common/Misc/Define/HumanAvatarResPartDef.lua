-----------------------------------------------------
--File Name    : HumanAvatarResPartDef.lua
--Author       : WuJizhou
--Create Time  : 10/18/2018, 7:18:13 PM
--Description  : HumanAvatarResPartDef
-----------------------------------------------------
local HumanAvatarResPartDef = {}
--the value is same as string in proto
--时装
HumanAvatarResPartDef.Hat          = "hat"
HumanAvatarResPartDef.Hair         = "hair"
HumanAvatarResPartDef.Head         = "head"
HumanAvatarResPartDef.Mask         = "mask"
HumanAvatarResPartDef.UpperBody    = "upper_body"
HumanAvatarResPartDef.LowerBody    = "lower_body"
HumanAvatarResPartDef.Shoe         = "shoe"
HumanAvatarResPartDef.Costume      = "costume"
--战斗装备
HumanAvatarResPartDef.Helmet       = "helmet"
HumanAvatarResPartDef.Armor        = "armor"
HumanAvatarResPartDef.Backpack     = "backpack"

HumanAvatarResPartDef.PartIndexToPartType = {}

HumanAvatarResPartDef.PartIndexToPartType[1] = HumanAvatarResPartDef.Hat
HumanAvatarResPartDef.PartIndexToPartType[2] = HumanAvatarResPartDef.Hair
HumanAvatarResPartDef.PartIndexToPartType[3] = HumanAvatarResPartDef.Head
HumanAvatarResPartDef.PartIndexToPartType[4] = HumanAvatarResPartDef.Mask
HumanAvatarResPartDef.PartIndexToPartType[5] = HumanAvatarResPartDef.UpperBody
HumanAvatarResPartDef.PartIndexToPartType[6] = HumanAvatarResPartDef.LowerBody
HumanAvatarResPartDef.PartIndexToPartType[7] = HumanAvatarResPartDef.Shoe
HumanAvatarResPartDef.PartIndexToPartType[8] = HumanAvatarResPartDef.Costume
HumanAvatarResPartDef.PartIndexToPartType[9] = HumanAvatarResPartDef.Helmet
HumanAvatarResPartDef.PartIndexToPartType[10] = HumanAvatarResPartDef.Armor
HumanAvatarResPartDef.PartIndexToPartType[11] = HumanAvatarResPartDef.Backpack

return HumanAvatarResPartDef