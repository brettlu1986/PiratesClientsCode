local PointTipsIni          = require("PointTipsIni")
local Proto                 = require("DungeonCommonProtoNames")
-- local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")

local PointTipsHelper = {}

PointTipsHelper.DropItemConfig              = 1
PointTipsHelper.PointLocationConfig         = 2

PointTipsHelper.PointTips             = 1
PointTipsHelper.ItemPointTips         = 2
PointTipsHelper.DEBUG_MODE            = false
PointTipsHelper.Proto_PointType = {
    [PointTipsHelper.PointTips]         = Proto.c2d_PointLocation_PointType.LOCATION,
    [PointTipsHelper.ItemPointTips]     = Proto.c2d_PointLocation_PointType.DROPITEM,
}

local nMaxPointTipsCount          = PointTipsIni.tbConfig.nPointTipsCount
local nMaxItemPointTipsCount      = PointTipsIni.tbConfig.nItemPointTipsCount

local nMaxPointTipsShowTime          = PointTipsIni.tbConfig.nPointTipsShowTime
local nMaxItemPointTipsShowTime      = PointTipsIni.tbConfig.nItemPointTipsShowTime

local tbShipIniData     = PointTipsIni.tbConfig.tbShip
local tbHumanIniData    = PointTipsIni.tbConfig.tbHuman

local tbShipData = {
    [PointTipsHelper.DropItemConfig] = {
        ["distance"]    = tbShipIniData.nItemPointDistance,
        ["lineLen"]     = tbShipIniData.nItemPointDistance,
        ["boxOrigen"]   = Vector{X = 0, Y = 0, Z = 0},
        ["boxExtent"]   = Vector{X = tbShipIniData.nBoxTriggerLen, Y = tbShipIniData.nBoxTriggerLen, Z = tbShipIniData.nBoxTriggerLen},
    },
    [PointTipsHelper.PointLocationConfig] = {
        ["distance"] = tbShipIniData.nLocationPointDistance,
    }
}

local tbHumanData = {
    [PointTipsHelper.DropItemConfig] = {
        ["distance"]    = tbHumanIniData.nItemPointDistance,
        ["lineLen"]     = tbHumanIniData.nItemPointDistance,
        ["boxOrigen"]   = Vector{X = 0, Y = 0, Z = 0},
        ["boxExtent"]   = Vector{X = tbHumanIniData.nBoxTriggerLen, Y = tbHumanIniData.nBoxTriggerLen, Z = tbHumanIniData.nBoxTriggerLen},
    },
    [PointTipsHelper.PointLocationConfig] = {
        ["distance"] = tbHumanIniData.nLocationPointDistance,
    }
}

local tbMaxTipsCount = {
    [PointTipsHelper.PointTips]     = nMaxPointTipsCount,
    [PointTipsHelper.ItemPointTips] = nMaxItemPointTipsCount,
}

local tbTipsShowTime = {
    [PointTipsHelper.PointTips]     = nMaxPointTipsShowTime,
    [PointTipsHelper.ItemPointTips] = nMaxItemPointTipsShowTime,
}

local DEFAULT_VECTOR = Vector2D()

function PointTipsHelper.GetConfig(bShip, nConfigType)
    local tbData = bShip and tbShipData or tbHumanData
    return tbData[nConfigType]
end

function PointTipsHelper.GetTipMaxCount(nTipsType)
    return tbMaxTipsCount[nTipsType]
end

function PointTipsHelper.GetTipMaxShowTime(nTipsType)
    return tbTipsShowTime[nTipsType]
end

function PointTipsHelper.GetDistance(v1, v2)
    if not v1 or not v2 then
        return
    end
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    local dz = v1.z - v2.z
    local nOriginDistance = math.sqrt(dx * dx + dy * dy + dz * dz)
    nOriginDistance = math.floor(nOriginDistance)
	return nOriginDistance
end

function PointTipsHelper.VectorDot(v1, v2)
    return v1.X*v2.X + v1.Y*v2.Y + v1.Z*v2.Z 
end

function PointTipsHelper.LinePlaneIntersectPoint(pStartPos, pWorldDirection)
    local planeVector = Vector{X = 0, Y = 0, Z = 0 - pStartPos.Z}
    local planePoint = Vector{X = pStartPos.X, Y = pStartPos.Y, Z = 0}
    local lineVector = pWorldDirection
    local linePoint = pStartPos
    local returnResult = Vector();
    local nPV1, nPV2, nPV3, nPP1, nPP2, nPP3, nLV1, nLV2, nLV3, nLP1, nLP2, nLP3, t,nVpt
    nPV1 = planeVector.X;
    nPV2 = planeVector.Y;
    nPV3 = planeVector.Z;
    nPP1 = planePoint.X;
    nPP2 = planePoint.Y;
    nPP3 = planePoint.Z;
    nLV1 = lineVector.X;
    nLV2 = lineVector.Y;
    nLV3 = lineVector.Z;
    nLP1 = linePoint.X;
    nLP2 = linePoint.Y;
    nLP3 = linePoint.Z;
    nVpt = nLV1 * nPV1 + nLV2 * nPV2 + nLV3 * nPV3
    --判断直线是否与平面平行
    if nVpt == 0 then
        return nil
    else
        t = ((nPP1 - nLP1) * nPV1 + (nPP2 - nLP2) * nPV2 + (nPP3 - nLP3) * nPV3) / nVpt
        returnResult.X = nLP1 + nLV1 * t
        returnResult.Y = nLP2 + nLV2 * t
        returnResult.Z = nLP3 + nLV3 * t
    end
    local resultVector = Vector{X = nLP1 - returnResult.X, Y = nLP2 - returnResult.Y, Z = nLP3 -returnResult.Z }
    local bOpposite = PointTipsHelper.VectorDot(lineVector, resultVector) > 0
    return returnResult, bOpposite
end

function PointTipsHelper.GetScreenCenter(uiFFAMainWidgetRef)
    local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    local pbCutoutScreenAdapter = uiFFAMainWidgetRef.pbCutoutScreenAdapter
    if not pbCutoutScreenAdapter then
        return DEFAULT_VECTOR
    end
    local nAdapterViewportWidth = pbCutoutScreenAdapter:GetCutoutSpacerWidth()
    local nRealViewportWidth = pViewportSize.X*0.5 - nAdapterViewportWidth * nViewPortScale
    return Vector2D{X = nRealViewportWidth, Y = pViewportSize.Y*0.5}
end

function PointTipsHelper.GetShipPointPos(uiFFAMainWidgetRef)
    local pbShip = uiFFAMainWidgetRef.pWidgetRef.pbFFAShip
    if not pbShip then
        return DEFAULT_VECTOR
    end
    local ovlCrosshairs = pbShip.pbShipWeaponCannon.imgDot
    local pLocalPosition
    local bCannonCrosshairsVisible = pbShip.pbShipWeaponCannon:IsVisible()
    if bCannonCrosshairsVisible then
        pLocalPosition = ovlCrosshairs.Slot:GetPosition()
    else
        return PointTipsHelper.GetScreenCenter(uiFFAMainWidgetRef)
    end
    local pGeometry = uiFFAMainWidgetRef.pWidgetRef:GetCachedGeometry()
    local pAbsolutePosition = SlateBlueprintLibrary.LocalToAbsolute(pGeometry, pLocalPosition)
    local pPpixelPosition, __ = SlateBlueprintLibrary.AbsoluteToViewport(GWorld, pAbsolutePosition)
    return pPpixelPosition
end

function PointTipsHelper.GetCrosshairPos(uiFFAMainWidgetRef, playerSelf, bShip)
    local ViewPortVector = nil
    if bShip then
        ViewPortVector = PointTipsHelper.GetShipPointPos(uiFFAMainWidgetRef)
    else
        ViewPortVector = PointTipsHelper.GetScreenCenter(uiFFAMainWidgetRef)
    end
    return ViewPortVector
end

return PointTipsHelper
