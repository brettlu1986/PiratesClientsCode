-----------------------------------------------------
--File Name    : ConvertibleItem.lua
--Author       : zhiyuan
--Create Time  : 2018-10-08
--Description  : 可转换的物品类型
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemBase = require("BattleItemBase")
local ConvertibleItem = luaclass("ConvertibleItem", BattleItemBase)
local BattleItemDataTable = require("BattleItemDataTable")
local ConvertibleItemDef = require("ConvertibleItemDef")

function ConvertibleItem:GetCategoryAfterAddToCharacter()
    local nConvertItemTemplateId = self.tbTemplate.nConvertItemTemplateId
    local tbTemplate = BattleItemDataTable:GetTemplate(nConvertItemTemplateId)
    return tbTemplate.nCategory
end

function ConvertibleItem:GetTemplateIdAfterAddToCharacter()
    return self.tbTemplate.nConvertItemTemplateId
end

local function GetMaterialBoxPosition(self, tbTransform)
    local tbTemplate = self:GetTemplate()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(tbTransform.X, tbTransform.Y)
    local bIsOcean =  nRegionType == EPiratesGridRegionType.Ocean or nRegionType == EPiratesGridRegionType.Port
    local offSetX = tbTemplate.nOffsetXLand
    local offSetY = tbTemplate.nOffsetYLand
    if bIsOcean then
        offSetX = tbTemplate.nOffsetXSea
        offSetY = tbTemplate.nOffsetYSea
    end

    local tbTranformAfterRandom = {X = tbTransform.X + offSetX, Y = tbTransform.Y + offSetY, Z = tbTransform.Z}
    return tbTranformAfterRandom, tbTemplate.nYaw
end

function ConvertibleItem:GetCreateActorPosition(tbTransform)
    if self:GetSubCategory() == ConvertibleItemDef.MATERILA_BOX then
        return GetMaterialBoxPosition(self, tbTransform)
    else
        return ConvertibleItem.super.GetCreateActorPosition(self, tbTransform)
    end
end

return ConvertibleItem