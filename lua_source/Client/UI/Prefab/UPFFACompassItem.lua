-----------------------------------------------------
--File Name    : UPFFACompassItem.lua
--Description  : UPFFACompassItem
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFFACompassItem = luaclass("UPFFACompassItem", UPFFABase)

local UISetUtils = require("UISetUtils")


local DIRECTION_TXT =
{
    [1] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_N"),
    [2] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_EN"),
    [3] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_E"),
    [4] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_ES"),
    [5] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_S"),
    [6] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_WS"),
    [7] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_W"),
    [8] = UISetUtils.GetL10NTextByKey("FFA_COMPASS_WN"),
}

--[[
    public function
]]


function UPFFACompassItem:SetDirection(nIndex)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtDirection:SetText(DIRECTION_TXT[nIndex])
    pWidgetRef.txtScale1:SetText((nIndex - 1) * 45 + 15)
    pWidgetRef.txtScale2:SetText((nIndex - 1) * 45 + 30)
end

return UPFFACompassItem
