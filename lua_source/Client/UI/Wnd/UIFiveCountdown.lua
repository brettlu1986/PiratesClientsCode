local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIFiveCountdown = luaclass("UIFiveCountdown", WndBase)

local MAX_TIME = 5
local COUNT_IMGS = {
    "Img05",
    "Img04",
    "Img03",
    "Img02",
    "Img01",
}

function UIFiveCountdown:OnShow()
    local OnComplete = function()
        self:CloseSelf()
    end
    local nTime = math.max(math.min(MAX_TIME - self.tbOpenArgs.nTime, MAX_TIME), 0)
    
    local pWidgetRef = self.pWidgetRef
    local Collapsed, SelfHitTestInvisible = ESlateVisibility.Collapsed, ESlateVisibility.SelfHitTestInvisible
    for i = 1, MAX_TIME do
        pWidgetRef[COUNT_IMGS[i]]:SetVisibility(nTime <= i and SelfHitTestInvisible or Collapsed)
    end 
    self:PlayAnimation("animCoundown", nTime, 1, EUMGSequencePlayMode.Forward, 1 * GameplayStatics.GetGlobalTimeDilation(GWorld), OnComplete)
end

return UIFiveCountdown
