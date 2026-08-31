-----------------------------------------------------
--File Name    : PropertyComboOperationTypeDef.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-27
--Description  : 
-----------------------------------------------------
local PropertyComboOperationTypeDef = {}
PropertyComboOperationTypeDef.PLUS       = 1
PropertyComboOperationTypeDef.MULTIPLY   = 2

function PropertyComboOperationTypeDef:GetOperationByString(szOperationSymbol)
    if szOperationSymbol == "+" then
        return PropertyComboOperationTypeDef.PLUS
    elseif szOperationSymbol == "-" then
        return PropertyComboOperationTypeDef.PLUS
    elseif szOperationSymbol == "*" then
        return PropertyComboOperationTypeDef.MULTIPLY
    elseif szOperationSymbol == "/" then
        return PropertyComboOperationTypeDef.MULTIPLY
    end
    error("PropertyComboOperationTypeDef : invalid operation symbol", szOperationSymbol)
end

return PropertyComboOperationTypeDef