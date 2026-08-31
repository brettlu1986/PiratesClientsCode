local ExportAIDoor = {}


ExportAIDoor.bNeedSaveTable = false
local GameDestructibleObjectType = require("GameDestructibleObjectType")
local DestructibleObjectNewDataTable = require("DestructibleObjectNewDataTable")

local tbExportLevels = {
    "LV_FFA_Island_01",
    "LV_FFA_Island_02",
}

local szSaveDir = "GameDataGenerated/common/ai/door/"

function ExportAIDoor:Export(nMode)
    local tbDoorIds = { }
    for k,v in pairs(DestructibleObjectNewDataTable.tbContainer) do
        if v.nType == GameDestructibleObjectType.Door then
            table.insert(tbDoorIds, v.nId)
        end
    end
    for i,v in ipairs(tbExportLevels) do
        AIDoorExporter.Export(v, tbDoorIds, szSaveDir, false)
    end
end

return ExportAIDoor