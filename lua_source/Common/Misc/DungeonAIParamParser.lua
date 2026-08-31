local DungeonAIParamParser = {}

local StringUtil = require("StringUtil")

local tbParser = {}

tbParser["int"] = function(pBBComponent, szKey, szData, pCustomData)
    if(szData ~= nil and string.len(szData) > 0) then
        pBBComponent:SetValueAsInt(szKey, tonumber(szData))
    end    
end

tbParser["string"] = function(pBBComponent, szKey, szData, pCustomData)
    if(szData ~= nil and string.len(szData) > 0) then
        pBBComponent:SetValueAsString(szKey, szData)
    end
end

tbParser["float"] = function(pBBComponent, szKey, szData, pCustomData)
    if(szData ~= nil and string.len(szData) > 0) then
        pBBComponent:SetValueAsFloat(szKey, tonumber(szData))
    end
end

tbParser["bool"] = function(pBBComponent, szKey, szData, pCustomData)
    if(szData ~= nil and string.len(szData) > 0) then
        pBBComponent:SetValueAsBool(szKey, StringUtil.ToBool(szData))
    end    
end

tbParser["enum"] = function(pBBComponent, szKey, szData, pCustomData)    
    if(szData ~= nil and string.len(szData) > 0) then
        local pAIController = pCustomData
        pAIController:SetBlackboardValueAsEnum(pBBComponent, szKey, tonumber(szData))
    end
end

-------------------------------------------------------------------------------------------
tbParser["int_array"] = function(pBBComponent, szKey, szData, pCustomData)    
    if(szData ~= nil and string.len(szData) > 0) then
        local pAIController = pCustomData
        if(pAIController[szKey]) then
            local tbData = StringUtil.Split(szData, ',')
            for i, szSingleData in ipairs(tbData) do
                tbData[i] = tonumber(szSingleData)
            end
            pAIController[szKey] = tbData
        end
    end
end

tbParser["string_array"] = function(pBBComponent, szKey, szData, pCustomData)    
    if(szData ~= nil and string.len(szData) > 0) then
        local pAIController = pCustomData
        if(pAIController[szKey]) then
            local tbData = StringUtil.Split(szData, ',')
            pAIController[szKey] = tbData
        end
    end
end

tbParser["float_array"] = function(pBBComponent, szKey, szData, pCustomData)
    tbParser["int_array"](pBBComponent, szKey, szData, pCustomData)
end

tbParser["bool_array"] = function(pBBComponent, szKey, szData, pCustomData)    
    if(szData ~= nil and string.len(szData) > 0) then
        local pAIController = pCustomData
        if(pAIController[szKey]) then
            local tbData = StringUtil.Split(szData, ',')
            for i, szSingleData in ipairs(tbData) do
                tbData[i] = StringUtil.ToBool(szSingleData)
            end
            pAIController[szKey] = tbData
        end
    end
end

-------------------------------------------------------------------------------------------
function DungeonAIParamParser:Parse(tbTableParser, tbLineData)
    if(#tbLineData == 0 or tbLineData[1] ~= '#AIParamType') then
        return false
    end

    local szData, fnParse
    local nCount = #tbLineData
    for i=2, nCount do
        szData = tbLineData[i]
        if(szData ~= nil and szData ~= '') then
            fnParse = tbParser[szData]
            if(fnParse) then
                tbTableParser[i] = fnParse
            end
        end
    end
    return true
end

return DungeonAIParamParser