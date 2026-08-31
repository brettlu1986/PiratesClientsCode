local FFAMapPointJsonTable = {}

local JsonConfigSystem     = require("JsonConfigSystem")
local DungeonDataTable     = require("DungeonDataTable")
local LevelJsonTableHelper = require("LevelJsonTableHelper")
local FFAMapPointDataTable = require("FFAMapPointDataTable")


local function MakePointData(tbJsonPoint)
    local FFAMapPoint = {}
    -- local BaseUtil = require("BaseUtil")
    -- BaseUtil:PrintTable(tbJsonPoint, 3)
    for k, v in pairs(tbJsonPoint) do
        local tbPointData = tbJsonPoint[v.Name]
        if not tbPointData then
            tbPointData = {}
            tbPointData.X = v.Transform.X 
            tbPointData.Y = v.Transform.Y
            tbPointData.Z = v.Transform.Z
            FFAMapPoint[v.Name] = tbPointData
        else
            logerror("MakePointData, duplicate Point, name= ", v.Name)
        end
    end
    return FFAMapPoint
end

function FFAMapPointJsonTable:Export()
    local tbJsonRoot = {}
    local tbAllDungeonId = FFAMapPointDataTable:GetAllDungeonId()
    local PointFileName = "FFAMapPoint.json"
    for k, v in ipairs(tbAllDungeonId)do
        local tbDungeonData = DungeonDataTable:GetTemplate(v)
        if tbDungeonData ~= nil and tbDungeonData.nResID ~= -1 then
            local szDescriptorPath, _ = LevelJsonTableHelper:GetDungeonDescriptorFolderPath(tbDungeonData.nResID, "")
            --logdebug("FFAMapPointJsonTable:Export,szDescriptorPath=",szDescriptorPath)
            local tbTable = {}

            tbTable.szFolderName = szDescriptorPath
            --tbTable.tbFileNames = { [1] = PointFileName }
            tbTable.szRecursiveSearchFileName = PointFileName
            tbTable.bRecursiveSearchFolder = true
            if JsonConfigSystem:Load(tbTable, false) == false then
                error("FFAMapPointJsonTable export failed")
            end
            tbJsonRoot[v] = MakePointData(tbTable.tbContainer.FFAMapPoint)
        end
    end
    return "FFAMapPointJsonTable", tbJsonRoot
end

return FFAMapPointJsonTable