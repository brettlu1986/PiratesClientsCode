local TransformDef = require("BattleTransformDef")

local BattleTransformPointHelper = {}

local tbGroups = nil

local function PointToInt(tbPoint)
    tbPoint.X = math.ceil(tbPoint.X)
    tbPoint.Y = math.ceil(tbPoint.Y)
    tbPoint.Z = math.ceil(tbPoint.Z)
    return tbPoint
end

function BattleTransformPointHelper:Init(tbJsonData)
    tbGroups = {}    

    if(not tbJsonData) then
        return
    end
    
    local TransformType = TransformDef.TransformType

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

function BattleTransformPointHelper:Uninit()
    tbGroups = nil
end

function BattleTransformPointHelper:Find(nId)
    return tbGroups[nId]
end

function BattleTransformPointHelper:FindByTag(szTag)
    for k, v in pairs(tbGroups) do
        if v.Tag and v.Tag == szTag then
            return v
        end
    end
end

return BattleTransformPointHelper