local luaclass = require ("luaclass")
local UIScheduleRoulette = require("UIScheduleRoulette")
local UIScheduleRoulettePop = luaclass("UIScheduleRoulettePop", UIScheduleRoulette)


function UIScheduleRoulettePop:OnShow()
    UIScheduleRoulettePop.super.OnShow(self)
    
    -- local pWidgetRef = self.pWidgetRef
    -- pWidgetRef.cbGetCount:SetVisibility(ESlateVisibility_Collapsed)
    -- pWidgetRef.btnGetReward:SetVisibility(ESlateVisibility_Collapsed)
end

return UIScheduleRoulettePop
