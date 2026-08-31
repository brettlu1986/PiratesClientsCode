local NoobParachutingJsonTable = {}

local JsonConfigSystem     = require("JsonConfigSystem")
local DungeonDataTable     = require("DungeonDataTable")
local DungeonIni           = require("DungeonIni")
local LevelJsonTableHelper = require("LevelJsonTableHelper")

local function TwoPointToBox(tbPoint1, tbPoint2)
    tbPoint1.X = math.ceil(tbPoint1.X)
    tbPoint1.Y = math.ceil(tbPoint1.Y)
    tbPoint2.X = math.ceil(tbPoint2.X)
    tbPoint2.Y = math.ceil(tbPoint2.Y)
    local nCenterX = math.ceil((tbPoint2.X - tbPoint1.X) / 2) + math.min(tbPoint1.X, tbPoint2.X)
    local nCenterY = math.ceil((tbPoint2.Y - tbPoint1.Y) / 2) + math.min(tbPoint1.Y, tbPoint2.Y)
    local nSizeX = math.abs(tbPoint2.X - tbPoint1.X)
    local nSizeY = math.abs(tbPoint2.Y - tbPoint1.Y)
    local tbBox = {tbCenter = {X = nCenterX, Y = nCenterY}, tbSize = {X = nSizeX, Y = nSizeY}}
    return tbBox
end

local function TransformPointParse(tbJsonData, nTransformId)
    local tbGroups = {}

    local PointGroups = tbJsonData.RandomPointGroups
    if (PointGroups) then
        for _, v in ipairs(PointGroups) do
            local tbBox = {}
            tbGroups[v.TransformId] = tbBox
            if (v.StartPoint and v.EndPoint) then
                tbGroups[v.TransformId] = TwoPointToBox(v.StartPoint, v.EndPoint)
            end 
        end
    end

    local Volume
    local VolumeGroups = tbJsonData.VolumeGroups
    if (VolumeGroups) then
        for _, v in ipairs(VolumeGroups) do
            if v.TransformId == nTransformId then
                local tbVolume = {}
                for _, nId in ipairs(v.Group) do
                    Volume = tbGroups[nId]
                    if (Volume) then
                        table.insert(tbVolume, Volume)
                    end 
                end
                return tbVolume
            end
        end
    end
end

function NoobParachutingJsonTable:Export()
    local tbJsonRoot = {}

    local VolumeFileName = "VolumePointGroups.json"
    local tbDungeonId = DungeonIni.tbFFANoob.tbDungeonId
    local nAreaId = DungeonIni.tbFFANoob.nAreaId
    for i, v in ipairs(tbDungeonId) do
        local tbDungeonData = DungeonDataTable:GetTemplate(tonumber(v))
        if tbDungeonData ~= nil then
            local szDescriptorPath, _ = LevelJsonTableHelper:GetDungeonDescriptorFolderPath(tbDungeonData.nResID, tbDungeonData.szLogicLevelName)
            local tbTable = {}

            tbTable.szFolderName = szDescriptorPath
            tbTable.tbFileNames = { [1] = VolumeFileName }
            if JsonConfigSystem:Load(tbTable, false) == false then
                error("NoobParachutingJsonTable export failed")
            end

            local tbVolume = TransformPointParse(tbTable.tbContainer, nAreaId)
            tbJsonRoot[tbDungeonData.nID] = tbVolume
        else
            logerror("NoobParachutingJsonTable:Export failed: not find dungeon ", v)
        end
    end

    return "NoobParachutingJsonTable", tbJsonRoot
end

return NoobParachutingJsonTable