-----------------------------------------------------
--File Name    : PropertyComboDescParser.lua
--Author       : ZhangWei
--Create Time  : 2020-07-01
--Description  : PropCombo 一条属性的展示数据解析器，用于不按默认的 PropertyCombo 显示规则展示的属性描述拼装
-----------------------------------------------------
local PropertyComboDescParser = {}

local PropertyComboDefineDataTable = require("PropertyComboDefineDataTable")
local PropertyComboOperationTypeDef = require("PropertyComboOperationTypeDef")
local DungeonIni = require("DungeonIni")

local TIME_UNIT_CHAR = "s"

function PropertyComboDescParser.DiamondRefreshTimeOnMapParser(tbReturnDisplayInfo, szKey, nOperationType, nValue)
    tbReturnDisplayInfo.szKey = szKey
    tbReturnDisplayInfo.l10nDisplayName = PropertyComboDefineDataTable:GetPropertyDisplayName(szKey)

    local nRealRefreshTime = nil

    if nOperationType == PropertyComboOperationTypeDef.PLUS then
        nRealRefreshTime = DungeonIni.tbFFA.nDiamondRefreshTimeOnMap + nValue
        if nValue % 1 == 0 then
            tbReturnDisplayInfo.szDisplayValue = string.format("%d%s", nRealRefreshTime, TIME_UNIT_CHAR)
        else
            tbReturnDisplayInfo.szDisplayValue = string.format("%.2f%s", nRealRefreshTime, TIME_UNIT_CHAR)
        end
    elseif nOperationType == PropertyComboOperationTypeDef.MULTIPLY then
        nRealRefreshTime = DungeonIni.tbFFA.nDiamondRefreshTimeOnMap * (1 + nValue)
        tbReturnDisplayInfo.szDisplayValue = string.format("%.2f%s", nRealRefreshTime, TIME_UNIT_CHAR)
    end
end

return PropertyComboDescParser