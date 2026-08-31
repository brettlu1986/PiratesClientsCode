-----------------------------------------------------
--File Name    : ShipItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-18
--Description  : 船的物品的配置表读取helper
-----------------------------------------------------
local ShipItemDataTableHelper = {}

local ShipDataTable = require("ShipDataTable")

function ShipItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nShipId = Parser:Get("ship_id", 0, Parser.TypeInt)
    NewTemplate.nBuildingLevel = Parser:Get("building_level", 0, Parser.TypeInt)
    NewTemplate.tbRecommendedWeapons = Parser:Get("recommended_weapons", {}, Parser.TypeArrayInt)
end

function ShipItemDataTableHelper.ValidateAttriLine(NewTemplate)
    local nShipId = NewTemplate.nShipId
    local tbShipTemplate = ShipDataTable:GetTemplate(nShipId)
    if not tbShipTemplate then
        error("ShipItemDataTableHelper.ValidateAttriLine failed! Cannot find ship id!" .. NewTemplate.nId .. ", nShipId: "..nShipId)
    end
    if tbShipTemplate.nGrade ~= NewTemplate.nGrade then
        error("ShipItemDataTableHelper.ValidateAttriLine failed! Grade not equal!" .. NewTemplate.nId .. ", item grade: "..NewTemplate.nGrade..", ship grade:"..tbShipTemplate.nGrade)
    end
end

return ShipItemDataTableHelper