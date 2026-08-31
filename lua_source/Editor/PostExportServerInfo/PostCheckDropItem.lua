local JsonConfigSystem = require("JsonConfigSystem")

local TransformDef = require("BattleTransformDef")
local TransformType = TransformDef.TransformType

local HUMAN_CELL_SIZE = 10000
local SHIP_CELL_SIZE = 50000
local READY_REGION_TRANSFORM_TAG = "ReadyRegion"

local nCount = 0
local nErrorCount = 0

local tbGroups = nil

local function PointToInt(tbPoint)
    tbPoint.X = math.ceil(tbPoint.X)
    tbPoint.Y = math.ceil(tbPoint.Y)
    tbPoint.Z = math.ceil(tbPoint.Z)
    return tbPoint
end

-- 抄了一遍BattleTransformPointHelper:Find
local function InitPoint(tbJsonData)
    tbGroups = {}

    if(not tbJsonData) then
        return
    end

    local Transforms = tbJsonData.Transforms
    if(Transforms) then
        for _, v in ipairs(Transforms) do
            local tbTempPoint = v.Transform
            tbGroups[v.TransformId] = {
                Type = TransformType.Point,
                X = tbTempPoint.X,
                Y = tbTempPoint.Y,
                Z = tbTempPoint.Z,
                Yaw = tbTempPoint.Yaw
            }
        end
    end

    local Point
    local Groups = tbJsonData.TransformGroups
    if(Groups) then
        for _, v in ipairs(Groups) do
            local tbTempPoints = {}
            tbTempPoints.Type = TransformType.Transform
            local tbGroup = {}
            tbTempPoints.Group= tbGroup

            tbGroups[v.TransformId] = tbTempPoints
            for _, nId in ipairs(v.Group) do
                Point = tbGroups[nId]
                if(Point and Point.Type == TransformType.Point) then
                    table.insert(tbGroup, Point)
                end -- end if
            end -- end for _, nId in ipairs(v.Group) do
        end -- end for _, v in ipairs(Groups) do
    end -- end if(Groups) then

    local PointGroups = tbJsonData.RandomPointGroups
    if (PointGroups) then
        for _, v in ipairs(PointGroups) do
            local tbTempPoints = {}
            tbTempPoints.Type = TransformType.Transform
            tbGroups[v.TransformId] = tbTempPoints

            if (v.StartPoint and v.EndPoint) then
                tbTempPoints.StartPoint = PointToInt(v.StartPoint)
                tbTempPoints.EndPoint = PointToInt(v.EndPoint)
                tbTempPoints.Yaw = v.Yaw
            elseif v.Group then
                local tbGroup = {}
                tbTempPoints.Group = tbGroup
                for _, p in ipairs(v.Group) do
                    table.insert(tbGroup, p)
                end
            end
        end
    end

    local Volume
    local VolumeGroups = tbJsonData.VolumeGroups
    if (VolumeGroups) then
        for _, v in ipairs(VolumeGroups) do
            local tbTempVolume = {}
            tbTempVolume.Type = TransformType.Volume
            local tbVolume = {}
            tbTempVolume.Volume = tbVolume

            tbGroups[v.TransformId] = tbTempVolume
            for _, nId in ipairs(v.Group) do
                Volume = tbGroups[nId]
                if (Volume and Volume.Type == TransformType.Transform) then
                    table.insert(tbVolume, nId)
                end
            end

            if (v.StartPoint and v.EndPoint) then
                tbTempVolume.StartPoint = PointToInt(v.StartPoint)
                tbTempVolume.EndPoint = PointToInt(v.EndPoint)
            end
            if (v.Tag) then
                tbTempVolume.Tag = v.Tag
            end
        end
    end
end

local function FindTransformByTag(szTag)
    for k, v in pairs(tbGroups) do
        if v.Tag and v.Tag == szTag then
            return v
        end
    end
    -- return tbGroups[nId]
end

-- 吃鸡专用
local function GetReadyRegionInfo()
    local tbTransform = FindTransformByTag(READY_REGION_TRANSFORM_TAG)
    if tbTransform then
        if tbTransform.StartPoint and tbTransform.EndPoint then
            local W = tbTransform.EndPoint.X - tbTransform.StartPoint.X
            local H = tbTransform.EndPoint.Y - tbTransform.StartPoint.Y
            return math.abs(W), math.abs(H), 
                (tbTransform.EndPoint.X + tbTransform.StartPoint.X) / 2, 
                (tbTransform.EndPoint.Y + tbTransform.StartPoint.Y) / 2
        end
    end
    error("GetReadyRegionCenterLocation failed")
end


local function CreateTemplateActorManager(nMapWidth, nMapHeight, nMapCenterX, nMapCenterY)
    local szManagerPath = "/Script/Common.TemplateActorDataManager"
    local pManager = ExtendBlueprintFunctions.CreateObject(szManagerPath:load(), nil)
    pManager:Init(nMapWidth, nMapHeight, nMapCenterX, nMapCenterY, HUMAN_CELL_SIZE, SHIP_CELL_SIZE)
    return luaholder(pManager)
end

local function IsValidLocation(tbManagers, tbPoint)
    local Error = ""
    nCount = nCount + 1
    for _, v in ipairs(tbManagers) do
        if v:IsValidLocation(tbPoint.X, tbPoint.Y) then
            return Error
        end
    end
    nErrorCount = nErrorCount + 1
    Error = "X:"..tbPoint.X..", Y:"..tbPoint.Y..", Z:"..tbPoint.Z..".\n"
    return Error
end

local function IsValidGroup(tbManagers, tbPoints)
    local Error = ""
    if tbPoints.StartPoint and tbPoints.EndPoint then
        Error = Error .. IsValidLocation(tbManagers, tbPoints.StartPoint)
        Error = Error .. IsValidLocation(tbManagers, tbPoints.EndPoint)
    else
        local tbGroup = tbPoints.Group
        for _, v in ipairs(tbGroup) do
            Error = Error .. IsValidLocation(tbManagers, v)
        end
    end
    return Error
end

local function IsTransformValid(tbManagers, tbPoint)
    local Error = ""
    if tbPoint.Type == TransformType.Point then
        Error = Error .. IsValidLocation(tbManagers, tbPoint)
    elseif (tbPoint.Type == TransformType.Transform) then
        Error = Error .. IsValidGroup(tbManagers, tbPoint)
    -- 因为Volume里只有id，所以不用检查了
    --  elseif (tbPoint.Type == TransformType.Volume) then
    --    local tbVolume = tbPoint.Volume
        -- for k, v in ipairs(tbVolume) do
        --     local tbVolumePoint = FindTransform(v)
        --     Error = Error .. IsValidGroup(pManager, tbVolumePoint)
        -- end
    end
    return Error
end

-- 检查是不是吃鸡地图
local function CheckFFA(tbContainer)
    local tbGameModesJson = tbContainer["GameMode"]
    if tbGameModesJson == nil then
        log("Cannot find Gamemodes json")
        return false
    end
    local tbGameModeJson = tbGameModesJson[1]
    if tbGameModeJson == nil then
        log("Cannot find Gamemode json")
        return false
    end
    local tbSettingJson = tbGameModeJson["Setting"]
    if tbSettingJson == nil then
        log("Cannot find setting json")
        return false
    end
    local szOperationName = tbSettingJson["OperationName"]
    if szOperationName ~= "Setting_FFA" then
        log("Map is not ffa. Do not excute checkdropitem script.")
        return false
    end
    return true
end

return function(szFilePath)
    local Error = ""

    -- load json
    local tbRet = {}
    tbRet.szFolderName = szFilePath
    tbRet.bRecursiveSearchFolder = true
    if(not JsonConfigSystem:Load(tbRet)) then
        return nil
    end
    local tbJsonTableFile = {}
    tbJsonTableFile.tbContainer = tbRet.tbContainer

    -- 检查是不是吃鸡地图
    if not CheckFFA(tbJsonTableFile.tbContainer) then
        return Error
    end

    InitPoint(tbJsonTableFile.tbContainer)

    -- 非集合区manager
    local tbMapSize = tbJsonTableFile.tbContainer.MapSize[1]
    local pNormalManager = CreateTemplateActorManager(tbMapSize.GamePlayWidth, tbMapSize.GamePlayHeight, 0, 0)

    -- 集合区manager
    local W, H, X, Y = GetReadyRegionInfo()
    local pReadyRegionManger = CreateTemplateActorManager(W, H, X, Y)

    local tbManagers = {}
    table.insert(tbManagers, pNormalManager)
    table.insert(tbManagers, pReadyRegionManger)
    -- check all drop points
    for k, v in pairs(tbGroups) do
        Error = Error .. IsTransformValid(tbManagers, v)
    end

    if Error ~= "" then
        Error = "Invalid points:\n"..Error
    end
    log("Check Drop Item Finish! Total count:", nCount, ".Error count:".. nErrorCount,"\nError info:".. Error)
    return Error
end