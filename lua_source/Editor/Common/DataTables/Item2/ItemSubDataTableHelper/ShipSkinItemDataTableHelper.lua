-----------------------------------------------------
--File Name    : ShipSkinItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-12
--Description  : Lobby中ShipSkinItem配置表
-----------------------------------------------------
local ShipSkinItemDataTableHelper = {}

local L10N = require("L10N")

function ShipSkinItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nShipItemId = Parser:Get("ship_item_id", -1, Parser.TypeInt)
    NewTemplate.nShipResId = Parser:Get("ship_res_id", -1, Parser.TypeInt)
    NewTemplate.bDefaultSkin = Parser:Get("default_skin", false, Parser.TypeBool)
    NewTemplate.l10nPrefixName = Parser:Get("prefix_name", L10N.NullString, Parser.TypeL10N)
    NewTemplate.nSourceType = Parser:Get("source_type", -1, Parser.TypeInt)
    NewTemplate.tbChangedEffects = Parser:Get("changed_effects", {}, Parser.TypeArrayInt)
end

-- 以下逻辑是在GamePlay里调用的接口
local function GetShipResTemplate(nShipSkinId)
    local ItemDataTable = require("ItemDataTable")
    local ShipResDatatable = require("ShipResDatatable")
    local tbShipSkinTemplate = ItemDataTable:GetTemplate(nShipSkinId)
    if tbShipSkinTemplate then
        return ShipResDatatable:GetTemplate(tbShipSkinTemplate.nShipResId)
    end
    return nil
end

function ShipSkinItemDataTableHelper.GetVerticalPosterPath(nShipSkinId)
    local tbShipResTemplate = GetShipResTemplate(nShipSkinId)
    if tbShipResTemplate then
        return tbShipResTemplate.szPortrait
    end
    return nil
end

function ShipSkinItemDataTableHelper.GetHorizontalPosterPath(nShipSkinId)
    local tbShipResTemplate = GetShipResTemplate(nShipSkinId)
    if tbShipResTemplate then
        return tbShipResTemplate.szIconPath
    end
    return nil
end

function ShipSkinItemDataTableHelper.GetSkinModel(nShipSkinId)
    local tbShipResTemplate = GetShipResTemplate(nShipSkinId)
    if tbShipResTemplate then
        return tbShipResTemplate.szPawnClassName
    end
    return nil
end


return ShipSkinItemDataTableHelper