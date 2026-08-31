local luaclass = require ("luaclass")
local UPTabButtonLobby = require("UPTabButtonLobby")
local UPLobbyCaptainSubCategoryTabButton = luaclass("UPLobbyCaptainSubCategoryTabButton", UPTabButtonLobby)

local UISetUtils = require("UISetUtils")

function UPLobbyCaptainSubCategoryTabButton:SetTipIconVisible(bVisible)
    self.pWidgetRef.btnTab:HideTipIcon(not bVisible)
    -- self.pWidgetRef.ovlTipIcon:SetVisibility(bVisible and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

function UPLobbyCaptainSubCategoryTabButton:SetTipCount(nCount)
    if nCount > 0 then
        self:SetTipIconVisible(true)
    else
        self:SetTipIconVisible(false)
    end
end

function UPLobbyCaptainSubCategoryTabButton:SetItemIcon(szSelectedIcon, szUnselectedIcon)
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItemSelected_1, szSelectedIcon:load())
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItemNotSelected, szUnselectedIcon:load())
end

function UPLobbyCaptainSubCategoryTabButton:SetOverlayIconVisible(bVisible)
    if bVisible then
        self.pWidgetRef.imgItemOverlay:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        self.pWidgetRef.imgItemOverlay:SetVisibility(ESlateVisibility_Collapsed)
    end
end

return UPLobbyCaptainSubCategoryTabButton
