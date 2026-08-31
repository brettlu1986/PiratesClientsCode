local luaclass = require("luaclass")
local LogEventOpBase = luaclass("LogEventOpBase")
local SelfEventHelper = require("SelfEventHelper")

local ShipDataTable = require("ShipDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")

LogEventOpBase.tbParam          = nil
LogEventOpBase.EventHelper      = nil

function LogEventOpBase:Init(tbParam)
    self.EventHelper = SelfEventHelper()
end

local function UnregisterAllEvent(self)
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

function LogEventOpBase:Uninit()
    UnregisterAllEvent(self)
end

--战斗开始
function LogEventOpBase:OnBattleBegin()
end

--战斗
function LogEventOpBase:OnBattleEnd()
    UnregisterAllEvent(self)
end

--获取是否战斗已经开始
function LogEventOpBase:IsBattleBegin()
    return self.tbParam.bIsBattleBegin
end

--获取战斗开始时的时间戳
function LogEventOpBase:GetBattleBeginTime()
    return self.tbParam.nBattleBeginTime
end

function LogEventOpBase:GetBattleItemDetail(nItemTemplateId)
    local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if not tbBattleItemTemplate then
        return nil
    end
    local tbBattleItemDetail = {}
    tbBattleItemDetail.item_template_id = nItemTemplateId
    local nCategory = tbBattleItemTemplate.nCategory
    tbBattleItemDetail.category = nCategory
    tbBattleItemDetail.grade = tbBattleItemTemplate.nGrade
    local nSubCategory = tbBattleItemTemplate.nSubCategory
    if nCategory == BattleItemCategoryDef.MATERIAL then
        tbBattleItemDetail.sub_category1 = tbBattleItemTemplate.nIndex
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        tbBattleItemDetail.sub_category2 = nSubCategory
        tbBattleItemDetail.sub_category1 = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        tbBattleItemDetail.sub_category1 = tbBattleItemTemplate.tbMatchedSlotTypes[1]
        tbBattleItemDetail.sub_category2 = tbBattleItemTemplate.nWeaponCategory
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        tbBattleItemDetail.sub_category1 = tbBattleItemTemplate.nArmorCategory
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        tbBattleItemDetail.sub_category1 = tbBattleItemTemplate.nAttachmentCategory
    elseif nCategory == BattleItemCategoryDef.SHIP then
        local nShipId = tbBattleItemTemplate.nShipId
        tbBattleItemDetail.sub_category1 = ShipDataTable:GetShipCategoryData(nShipId)
    elseif nCategory == BattleItemCategoryDef.BUILD_KEY_ITEM then
        local nBuiltItemTemplateId = BattleItemBuildDataTable:GetKeyItemBuildItemTemplateId(nItemTemplateId)
        local tbBuiltBattleItemTemplate = BattleItemDataTable:GetTemplate(nBuiltItemTemplateId)
        tbBattleItemDetail.sub_category2 = tbBuiltBattleItemTemplate.nSubCategory
        tbBattleItemDetail.sub_category1 = ShipWeaponCategoryDataTable:GetWeaponSlot(tbBuiltBattleItemTemplate.nSubCategory)
    else
        -- nCategory == BattleItemCategoryDef.SHIP_PART
        -- or nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT
        -- or nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE
        -- or nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM
        tbBattleItemDetail.sub_category1 = nSubCategory
    end
    return tbBattleItemDetail
end

function LogEventOpBase:GetBattleItemCategory(nItemTemplateId)
    local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if not tbBattleItemTemplate then
        return nil
    end
    return tbBattleItemTemplate.nCategory
end

function LogEventOpBase:LogEvent(nPropName, tbPacket)
end

return LogEventOpBase