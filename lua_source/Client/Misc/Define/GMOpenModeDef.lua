-----------------------------------------------------
--File Name    : GMOpenModeDef.lua
--Author       : Song Fuhao
--Create Time  : 2020-03-12
--Description  : GM面板打开方式枚举
-----------------------------------------------------
local GMOpenModeDef = {}

GMOpenModeDef.DOUBLE_CLICK = 1
GMOpenModeDef.LONG_PRESS = 2

local tbTransformationData = {
    ["double_click"] = GMOpenModeDef.DOUBLE_CLICK,
    ["long_press"] = GMOpenModeDef.LONG_PRESS,
}

function GMOpenModeDef.TransformByString(szMode)
    local nMode = tbTransformationData[szMode]
    return nMode and nMode or GMOpenModeDef.DOUBLE_CLICK
end

return GMOpenModeDef