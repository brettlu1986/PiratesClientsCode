-----------------------------------------------------
--File Name    : HumanWeaponItemPropertyHelper.lua
--Author       : WuJizhou
--Create Time  : 9/12/2018, 3:09:21 PM
--Description  : HumanWeaponItemPropertyHelper
-----------------------------------------------------

local HumanWeaponItemPropertyHelper = {}

local HumanWeaponDef = require("HumanWeaponDef")
local BattleItemDataTable = require("BattleItemDataTable")
local HumanWeaponRecoilDataTable = require("HumanWeaponRecoilDataTable")
local HumanWeaponCategoryPropertyDataTable = require("HumanWeaponCategoryPropertyDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanWeaponHelper = nil   -- 这里有循环包含的问题，惰性require
-- local StringUtil = require("StringUtil")

local TotalProperty = HumanWeaponDef.TotalProperty

local tbPropertyMetatable = {}
-- tbPropertyMetatable.__index = function (tb, key)

-- end

local function GetWeaponCategoryProperty(self)
    local tbTemplate = HumanWeaponCategoryPropertyDataTable:GetTemplate(self.nWeaponCategory)
    if tbTemplate ~= nil then
        return tbTemplate
    end
end

tbPropertyMetatable.__newindex = function (tb, key, value)
    if rawget(tb, key) == nil then
        logerror("HumanWeaponItemProperty table should not be assigned any new key", key, value)
    else
        rawset(tb, key, value)
    end
end

tbPropertyMetatable.__index = function (tb, key)
    if key == "tbWeaponCategoryProperty" then
        return GetWeaponCategoryProperty(tb)
    else
        return rawget(tb, key)
    end
end



function HumanWeaponItemPropertyHelper.CreateProperty(nTemplateId, bCreateForEmptyHanded)
    if bCreateForEmptyHanded then
        local tbProperty = {}
        tbProperty.nWeaponCategory = HumanWeaponDef.WeaponCategory.Melee
        tbProperty.nPrimaryCategory = HumanWeaponDef.WeaponPrimaryCategory.Melee
        local tbBaseProperty = {}
        tbBaseProperty.nWeaponCategory = HumanWeaponDef.WeaponCategory.Melee
        tbBaseProperty.nPrimaryCategory = HumanWeaponDef.WeaponPrimaryCategory.Melee
        setmetatable(tbProperty, tbPropertyMetatable)
        setmetatable(tbBaseProperty, tbPropertyMetatable)
        return tbProperty, tbBaseProperty
    end

    if nTemplateId == nil then
        logerror("HumanWeaponItemPropertyHelper.CreateProperty error, the template id is nil!")
        return nil
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local tbRecoilTemplate = HumanWeaponRecoilDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        logerror("HumanWeaponItemPropertyHelper.CreateProperty error, the recoil template id does not exist! template id : ", nTemplateId)
        return nil
    end

    local tbProperty = {}
    tbProperty.nTemplateId = nTemplateId
    tbProperty.nWeaponCategory = tbTemplate.nWeaponCategory
    tbProperty.nPrimaryCategory = tbTemplate.nPrimaryCategory

    local tbBaseProperty = {}
    tbBaseProperty.nTemplateId = nTemplateId
    tbBaseProperty.nWeaponCategory = tbTemplate.nWeaponCategory
    tbBaseProperty.nPrimaryCategory = tbTemplate.nPrimaryCategory
    local nTempValue = 0
    -- fill property from template
    for k, v in pairs(TotalProperty) do
        if v == HumanWeaponDef.Property.FireType then
            nTempValue = tbTemplate.tbFireTypes[1]
            tbProperty[v] = nTempValue
            tbBaseProperty[v] = nTempValue
        else
            nTempValue = tbTemplate[v]
            if nTempValue == nil and tbRecoilTemplate then
                nTempValue = tbRecoilTemplate[v]
            end
            tbProperty[v] = nTempValue
            tbBaseProperty[v] =nTempValue
        end
    end


    setmetatable(tbProperty, tbPropertyMetatable)
    setmetatable(tbBaseProperty, tbPropertyMetatable)
    return tbProperty, tbBaseProperty
end

-- only for gm command
function HumanWeaponItemPropertyHelper.GMSetBaseWeaponProperty(tbPlayer, tbParams, bIsClient)
    if not tbPlayer:IsHuman() then
        logerror("SetHumanWeaponProperty error", "not human")
        return
    end
    local WeaponComponent = tbPlayer.HumanWeaponComponent
    if not WeaponComponent then
        logerror("SetHumanWeaponProperty error", "no HumanWeaponComponent")
        return
    end
    local nCurrentWeaponInstanceId = WeaponComponent:GetCurrentWeaponInstanceId()
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    local tbCurrentWeapon = BattleItemSystem:GetItem(nCurrentWeaponInstanceId)
    if not tbCurrentWeapon then
        logerror("SetHumanWeaponProperty error", "current weapon is nil")
        return
    end
    local nCategory = tbCurrentWeapon:GetCategory()
    if nCategory ~= BattleItemCategoryDef.HUMAN_WEAPON then
        logerror("SetHumanWeaponProperty error", "current holding not weapon")
        return
    end
    local nOwnerCharacterId = tbCurrentWeapon:GetOwnerCharacterInstanceId()
    local nPlayerId = tbPlayer:GetServerInstanceId()
    if nOwnerCharacterId ~= nPlayerId then
        logerror("SetHumanWeaponProperty error", "target weapon's onwer illegal")
        return
    end

    local HumanWeaponProperty = HumanWeaponDef.Property
    local tbProperty = {}
	local nIdx = 1

    while true do
        local szProperty = tbParams[nIdx]
        local szValue = tbParams[nIdx + 1]
        if not szProperty or not szValue then
            break
        end
        local nValue = tonumber(szValue)
        if szProperty == HumanWeaponProperty.SpeedAffectDamage then
            if nValue == 0 then
                tbProperty[szProperty] = false
            else
                tbProperty[szProperty] = true
            end
        else
            tbProperty[szProperty] = nValue
        end
        nIdx = nIdx + 2
    end

    if(HumanWeaponHelper == nil) then
        HumanWeaponHelper = require("HumanWeaponHelper")
    end
    HumanWeaponHelper.SetBaseProperty(WeaponComponent:GetCurrentWeapon(), tbProperty)


    local tbAttachments = BattleItemSystemHelper:GetEquippedItems(nPlayerId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nCurrentWeaponInstanceId, bIsClient)
    local tbEfficientAttachments = {}
    for k, v in pairs(tbAttachments) do
        table.insert(tbEfficientAttachments, v)
    end

    tbCurrentWeapon:ActivateAttachmentProperty(tbEfficientAttachments)
end



return HumanWeaponItemPropertyHelper