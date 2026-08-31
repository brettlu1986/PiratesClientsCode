local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

local UIFFABackpackHelper = { }

function UIFFABackpackHelper.SetItemIcon(pWidgetButton, nResId)
    local tbRes = BattleItemResDataTable:GetTemplate(nResId)
    if not tbRes then
        logerror("UIFFABackpackHelper: invalid res id ", nResId)
        return
    end
    local szItemIconPath = tbRes.szIconPath
    local IconObj = szItemIconPath:load()
    if(IconObj == nil)then
        logwarning("UIFFABackpackHelper: icon is not found,path="..tostring(szItemIconPath))
        return
    end
    UISetUtils.SetButtonBrushRes(pWidgetButton, IconObj, true)
end

function UIFFABackpackHelper.SetPartLevel(pWidgetImage, nLevel)
    local tbLevelSprs = UIResourceDef.ITEM_GRADE_ICON
    if tbLevelSprs[nLevel] then
        local IconObj = tbLevelSprs[nLevel]:load()
        if(IconObj == nil)then
            logwarning("UIFFABackpackHelper: icon is not found,path="..tostring(tbLevelSprs[nLevel]))
            return
        end
        UISetUtils.SetImageBrushRes(pWidgetImage, IconObj, true)
    end
end

return UIFFABackpackHelper