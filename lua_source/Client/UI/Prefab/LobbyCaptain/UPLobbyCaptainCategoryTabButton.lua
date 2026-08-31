local luaclass = require ("luaclass")
local UPTabButtonLobby = require("UPTabButtonLobby")
local UPLobbyCaptainCategoryTabButton = luaclass("UPLobbyCaptainCategoryTabButton", UPTabButtonLobby)


function UPLobbyCaptainCategoryTabButton:SetTipIconVisible(bVisible)
    self.pWidgetRef.btnTab:HideTipIcon(not bVisible)
    -- self.pWidgetRef.ovlTipIcon:SetVisibility(bVisible and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

function UPLobbyCaptainCategoryTabButton:SetTipCount(nCount)
    if nCount > 0 then
        self:SetTipIconVisible(true)
    else
        self:SetTipIconVisible(false)
    end
end


return UPLobbyCaptainCategoryTabButton
