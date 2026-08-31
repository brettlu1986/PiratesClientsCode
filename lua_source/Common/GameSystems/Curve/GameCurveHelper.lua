local GameCurveHelper = {}

local GameCurveDataTable = require("GameCurveDataTable")
local CurveDef = require("CurveDef")

function GameCurveHelper.GetCurve(nId)
    local tbCurveData = GameCurveDataTable:GetTemplate(nId)
    if tbCurveData then
        return tbCurveData.szPath:load()
    end
    return nil
end

function GameCurveHelper.GetValue(nId, nTime)
    local pCurve = GameCurveHelper.GetCurve(nId)
    if pCurve then   
        local tbCurveData = GameCurveDataTable:GetTemplate(nId)
        local CurveTypeDef = CurveDef.Type
        if tbCurveData.nType == CurveTypeDef.FLOAT then   
            return pCurve:GetFloatValue(nTime)
        elseif tbCurveData.nType == CurveTypeDef.LINEAR_COLOR then  
            return pCurve:GetLinearColorValue(nTime)
        elseif tbCurveData.nType == CurveTypeDef.VECTOR then  
            return pCurve:GetVectorValue(nTime)
        end
    end  
    return nil
end

return GameCurveHelper