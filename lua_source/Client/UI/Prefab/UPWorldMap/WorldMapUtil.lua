-----------------------------------------------------
--File Name    : WorldMapUtil.lua
--Author       : Zhang Yuzhen
--Create Time  : 2017-5-9
--Description  : WorldMapUtil
-----------------------------------------------------

local WorldMapUtil = {}

local SceneDataTable = require("SceneDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local UIResourceDef = require("UIResourceDef")
local NPCDataTable = require("NPCDataTable")
local WorldMapResDataTable = require("WorldMapResDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ShipDataTable = require("ShipDataTable")
local TemplateTypeDef = require("TemplateTypeDef")


WorldMapUtil.tbMapTipType = {
    NoTip = 0,                  --没有Tip窗口
    AutoCruise_Port = 1,        --自动巡航到港口
    AutoCruise_Coordiante = 2,  --自动巡航到坐标
    AutoCruise_NoReach = 3,     --自动巡航不可达
    SupplyAndConsume = 4,       --补给消耗
    AutoCruise_TransferPoint = 5,   --自动巡航到传送点
}

WorldMapUtil.tbZoomFactor = {
    ZOOM_MIN = 1,
    ZOOM_MAX = 5,
}

-- 与map_content_point中map_grade字段一致
WorldMapUtil.tbMapGrade = {
    None = 0,                   -- 不显示
    First = 1,
    Second = 2,
    Third = 3,
}

WorldMapUtil.tbRadarNavigationPosType = {
    RadarNavigationInLand = 1000,           --  导航点密度雷达 10m
    RadarNavigationInSea = 60000,          --  导航点密度雷达 400m
}

WorldMapUtil.tbFunctionalNpcRange = {
    nMinID = 1,
    nMaxID = 999,
}

WorldMapUtil.tbRelation = {
    Friend = 1,
    Enemy = 2,
    Team = 3,
    Other = 4,
}

WorldMapUtil.OffSet_Y = 15                  -- UPMapObj在地图上的偏移信息

WorldMapUtil.nWildOceanID = 1

WorldMapUtil.nMaxHight = 50000              --50000cm 地图导航需要

WorldMapUtil.nCurrentSliderValue = nil

WorldMapUtil.PinchSize = 540

function WorldMapUtil.GetShipIconRes(nShipType)
    if nShipType and nShipType > 0 and nShipType <= 4 then
        return UIResourceDef.SHIP_FLAG_BORDER[nShipType]
    end
    return nil
end

function WorldMapUtil.GetSceneSize(nSceneID)
    local tbSceneTemplate = SceneDataTable:GetTemplate(nSceneID)
    local tbSceneResTemplate = UIMapResDataTable:GetTemplate(tbSceneTemplate.nUIMapId)
    return tbSceneResTemplate.nMapSizeX, tbSceneResTemplate.nMapSizeY
end

-- 是否显示阵营关系，是否转向
function WorldMapUtil.GetIconResDecoratorByTemplateId(bMMap, nTemplateId)
    local pNpcData = NPCDataTable:GetTemplate(nTemplateId)
    if pNpcData then
        local nMapDisplay
        if bMMap and pNpcData.nWorldMapDisplay > 0 then
            nMapDisplay = pNpcData.nWorldMapDisplay
        elseif not bMMap and pNpcData.nRadarMapDisplay > 0 then
            nMapDisplay = pNpcData.nRadarMapDisplay
        end

        if nMapDisplay then
            local bShowFaction = nMapDisplay == 1 or nMapDisplay == 2
            local bShowOrientation = nMapDisplay == 1 or nMapDisplay == 3
            return bShowFaction, bShowOrientation
        end
    end
    return nil
end

-- NpcIconResoure, bAutoSize(Icon size)
function WorldMapUtil.GetIconResByTemplateId(bMMap, nTemplateId)
    local pNpcData = NPCDataTable:GetTemplate(nTemplateId)
    if pNpcData then
        -- logdebug("WorldMapUtil.GetIconResByTemplateId() nTemplateId:", nTemplateId, "Map:", pNpcData.nWorldMapDisplay, "Radar:", pNpcData.nRadarMapDisplay, "IconID:", pNpcData.nIconIdInMap)
        if (bMMap and pNpcData.nWorldMapDisplay > 0) or (not bMMap and pNpcData.nRadarMapDisplay > 0) then
            if pNpcData.nIconIdInMap == 0 then
                if pNpcData.nType == TemplateTypeDef.SHIP then
                    local nShipTypeID = ShipDataTable:GetShipCategoryData(pNpcData.nTypeID)
                    -- logdebug("WorldMapUtil.GetIconResByTemplateId() shipId:", pNpcData.nShipID, "nShipTypeID:", nShipTypeID)
                    return WorldMapUtil.GetShipIconRes(nShipTypeID)
                else
                    logerror("WorldMapUtil.GetIconResByTemplateId() invalid shipId:", pNpcData.nTypeID, "nTemplateId:", nTemplateId)
                end
            else
                if pNpcData.nIconIdInMap > 0 then
                    return WorldMapResDataTable:GetMapRes(pNpcData.nIconIdInMap), true
                else
                    logerror("WorldMapUtil.GetIconRes() invalid icon id, tbGameObj.nTemplateId", nTemplateId)
                end
            end
        end
    else
        logerror("WorldMapUtil.GetIconResByTemplateId() invalid nTemplateId:", nTemplateId)
    end
    return nil
end

function WorldMapUtil.GetDynamicRes(tbGameObj)
    if tbGameObj.GetDynamicFlagId then
        local nDynamicResID = tbGameObj:GetDynamicFlagId()
        return WorldMapResDataTable:GetMapRes(nDynamicResID)
    end
    return nil
end

function WorldMapUtil.HasDynamicRes(tbGameObj)
    if tbGameObj.GetDynamicFlagId then
        return tbGameObj:GetDynamicFlagId()
    end
    return nil
end

function WorldMapUtil.GetMapRes(nResId)
    return WorldMapResDataTable:GetMapRes(nResId)
end

-- 动态ResID优先级最高；
-- 然后是配置中的显示开关；在开的情况下，若没有配置ID则走默认的显示(如船的类型)
-- 返回值：szRes, bAutoSize(Icon size), 
function WorldMapUtil.GetIconRes(bMMap, tbGameObj)
    local nDynamicResID
    if tbGameObj.GetDynamicFlagId then
        nDynamicResID = tbGameObj:GetDynamicFlagId()
    end
    if nDynamicResID then
        -- logdebug("WorldMapUtil.GetIconRes() nDynamicResID:", nDynamicResID)
        return WorldMapResDataTable:GetMapRes(nDynamicResID), true
    else
        local ObjectType = tbGameObj.ObjectType
        if ObjectType == GameObjectTypeDef.Npc then
            -- logdebug("WorldMapUtil.GetIconRes() Npc ", "Name:", tbGameObj:GetName(), "IsShip()", tbGameObj:IsShip())    
            return WorldMapUtil.GetIconResByTemplateId(bMMap, tbGameObj.nTemplateId)
        elseif ObjectType == GameObjectTypeDef.PlayerSelf or ObjectType == GameObjectTypeDef.PlayerOther then
            -- logdebug("WorldMapUtil.GetIconRes() PlayerID:", tbGameObj:GetPlayerId(), " Name:", tbGameObj:GetName(), "IsShip()", tbGameObj:IsShip())
            if tbGameObj:IsShip() then
                local nShipTypeID = ShipDataTable:GetShipCategoryData(tbGameObj.nTemplateId)
                return WorldMapUtil.GetShipIconRes(nShipTypeID)
            else
                return UIResourceDef.RADAR_MAP_OTHER_PLAYER
            end
        end

        return nil
    end
end

function WorldMapUtil.GetNameByTemplateId(bMMap, nTemplateId)
    local pNpcData = NPCDataTable:GetTemplate(nTemplateId)
    if pNpcData then
        if (bMMap and pNpcData.nWorldMapDisplay > 0) or (not bMMap and pNpcData.nRadarMapDisplay > 0) then
            return pNpcData.szNameInMap
        end
    end
    return nil
end

function WorldMapUtil.IsDisplayForNpc(nTemplateId, nCurrentGrade)
    local pNpcData = NPCDataTable:GetTemplate(nTemplateId)
    if pNpcData and pNpcData.tbWorldMapDisplayLevel then
        local tbWorldMapDisplayLevel = pNpcData.tbWorldMapDisplayLevel
        for _, v in ipairs(tbWorldMapDisplayLevel) do
            if v == nCurrentGrade then
                return true
            end
        end
    end
    return false
end


return WorldMapUtil
