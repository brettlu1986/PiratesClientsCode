local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayerSeasonStar = luaclass("UPPlayerSeasonStar", PrefabBase)

function UPPlayerSeasonStar:OnRefresh(nIndex, bNewShow, bOldShow)
    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    local imgSee = self.pWidgetRef.imgSee

    if bOldShow == true then
        if bNewShow then
            imgSee:SetVisibility(Visible)
        else
            -- play hide animation
            imgSee:SetVisibility(Collapsed)           
        end
    elseif bOldShow == false then
        if bNewShow then
            -- play show animation
            imgSee:SetVisibility(Visible)
        else
            imgSee:SetVisibility(Collapsed)           
        end
    else
        imgSee:SetVisibility(bNewShow and Visible or Collapsed)
    end    
end

return UPPlayerSeasonStar