-----------------------------------------------------
--File Name    : HumanAvatarSystem_C.lua
--Author       : WuJizhou
--Create Time  : 5/21/2020, 2:29:25 PM
--Description  : HumanAvatarSystem_C
-----------------------------------------------------
local luaclass = require("luaclass")
local HumanAvatarSystem = require("HumanAvatarSystem")

local HumanAvatarSystem_C = luaclass("HumanAvatarSystem_C", HumanAvatarSystem)

local HumanAvatarHelper     = require("HumanAvatarHelper")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")

HumanAvatarSystem_C.tbWeaponAvatarTemplateIds = nil

function HumanAvatarSystem_C:SetWeaponAvatarPresetForSelf(tbTemplateIds)
    self.tbWeaponAvatarTemplateIds = tbTemplateIds
    self.tbFashionData = HumanAvatarHelper.ParseToHumanWeaponFashionDataFromFashionTemplateIds(tbTemplateIds)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerSelfInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if tbPlayerSelf and tbPlayerSelf.HumanWeaponAvatarComponent then
        local tbInstanceId = {}
        local tbItems =  BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, nPlayerSelfInstanceId)
        for _nSlotIndex, tbItem in pairs(tbItems) do
            table.insert(tbInstanceId, tbItem:GetInstanceId())
        end
        tbPlayerSelf.HumanWeaponAvatarComponent:UpdateWeaponFashion(tbInstanceId)
    end
end

function HumanAvatarSystem_C:GetWeaponAvatarFashion()
    if self.tbFashionData then
        return self.tbFashionData
    end
    return {}
end

-- function HumanAvatarSystem_C:Init()
--     return true
-- end

-- function HumanAvatarSystem_C:Uninit()
--     return true
-- end

return HumanAvatarSystem_C