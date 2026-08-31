local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonGo = luaclass("UISeasonGo", WndBase)
local Proto = require("ClientProtoNames")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
-------------------------------------------------------------------------------------------------------

local function OnClickContinue(self)
    -- local pWidgetRef = self.pWidgetRef
    -- if not pWidgetRef:IsAnimationPlaying(pWidgetRef.animDisappear) then
    --     local fnComplete = function()
    --         self:CloseSelf()
    --     end
    --     self:PlayAnimation("animDisappear", 0, 1, EUMGSequencePlayMode.Forward, 1, fnComplete)
    -- end

    self:CloseSelf()
    local nStatus = self.tbOpenArgs.nStatus
    if nStatus and nStatus == Proto.PlayerSeasonStatus.RESET then
        UIManager:OpenWnd(UIDef.UI_SEASON_RANK_RESULT)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    end
end

function UISeasonGo:OnLoad()
end

function UISeasonGo:OnShow()
    local fnComplete = function()
        self:PlayAnimation("anim_Glow", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
    self:PlayAnimation("anim_SeasonGoln", 0, 1, EUMGSequencePlayMode.Forward, 1, fnComplete)
end

function UISeasonGo:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnContinue.OnClicked, self, OnClickContinue)
end

function UISeasonGo:OnDestroy()

end

return UISeasonGo