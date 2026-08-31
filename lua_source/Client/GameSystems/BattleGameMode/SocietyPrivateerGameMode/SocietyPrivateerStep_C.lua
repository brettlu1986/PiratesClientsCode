local luaclass = require("luaclass")
local Timer = require("Timer")

local SocietyPrivateerStepClass = require("SocietyPrivateerStep")
local SocietyPrivateerStep_C = luaclass("SocietyPrivateerStep_C", SocietyPrivateerStepClass)

function SocietyPrivateerStep_C:Start()
    SocietyPrivateerStep_C.super.Start(self)

    local OnShowHeadDialog = function()
        local InteractionHelper = require("InteractionHelper")
        if self.MerchantShip then 
            InteractionHelper:CreatePortraitHeadDialog(self.HeadHintDialogId, nil, self.MerchantShip)
        end
    end
    -- 敌船对话延迟5秒
    self.TimerDialog = Timer.NewTimer(OnShowHeadDialog, 5, false)

end


return SocietyPrivateerStep_C
