local ShipScoreContainer = {}

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

ShipScoreContainer.tbDatas = nil

local function Init(self)
    if self.tbDatas then
        return
    end
    self.tbDatas = {}
    local tbDatas = self.tbDatas

    local tbAllBaseScores = {}
    local tbMinAndMaxScores = {}

    local tbTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.SHIP)

    local ShipDataDisplayHelper = require("ShipDataDisplayHelper")
    for _, v in pairs(tbTemplates) do
        local nShipItemTemplateId = v.nId
        local tbDataDisplayHelper = ShipDataDisplayHelper.New(nShipItemTemplateId)
        local tbBaseScores = tbDataDisplayHelper:CalBaseScores()
        tbAllBaseScores[nShipItemTemplateId] = tbBaseScores
        for nCategory, nScore in pairs(tbBaseScores) do
            local tbCategoryData = tbMinAndMaxScores[nCategory]
            if not tbCategoryData then
                tbMinAndMaxScores[nCategory] = {nMin = nScore, nMax = nScore}
                tbCategoryData = tbMinAndMaxScores[nCategory]
            end
            if tbCategoryData.nMin > nScore then
                tbCategoryData.nMin = nScore
            end
            if tbCategoryData.nMax < nScore then
                tbCategoryData.nMax = nScore
            end
        end
    end
    for nShipItemTemplateId, tbBaseScores in pairs(tbAllBaseScores) do
        local tbFinalScores = {}
        for nCategory, nScore in pairs(tbBaseScores) do
            local tbCategoryData = tbMinAndMaxScores[nCategory]
            local nFinalScore = ShipDataDisplayHelper.CalScore(nScore, tbCategoryData.nMax, tbCategoryData.nMin)
            tbFinalScores[nCategory] = nFinalScore
        end
        tbDatas[nShipItemTemplateId] = tbFinalScores
    end
end

function ShipScoreContainer:GetFinalScore(nShipItemTemplateId, nCategory)
    Init(self)
    local tbScores = self.tbDatas[nShipItemTemplateId]
    if not tbScores then
        return 0
    end
    log("ship score:", nShipItemTemplateId, nCategory, tbScores[nCategory])
    return tbScores[nCategory]
end

return ShipScoreContainer