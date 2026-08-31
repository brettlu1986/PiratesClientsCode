local ExportAIVehicle = {}


ExportAIVehicle.bNeedSaveTable = false

local tbExportLevels = {
    "LV_FFA_Island_01",
    "LV_FFA_Island_02",
}

local nCellSize = 10000

local szSaveDir = "GameDataGenerated/common/ai/vehicle/"

function ExportAIVehicle:Export(nMode)
    for i,v in ipairs(tbExportLevels) do
        AIVehicleExporter.Export(v, nCellSize, szSaveDir, false)
    end
end

return ExportAIVehicle