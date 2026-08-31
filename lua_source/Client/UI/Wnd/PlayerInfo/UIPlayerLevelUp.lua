-----------------------------------------------------
--File Name    : UIPlayerLevelUp.lua
--Author       : WuJizhou
--Create Time  : 3/25/2019, 2:48:29 PM
--Description  : UIPlayerLevelUp
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")

local UIPlayerLevelUp = luaclass("UIPlayerLevelUp", WndBase)
local PlayerBasicInfoSystem = require("PlayerBasicInfoSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local AwardSystem = require("AwardSystem")

local function OnConfirmClicked(self)
    local tbLevelUpAwardData = AwardSystem:GetAndDeleteLevelUpAwardDatas()
    if tbLevelUpAwardData and #tbLevelUpAwardData > 0 then
        UIManager:OpenWnd(UIDef.UI_LOBBY_LEVEL_UP_AWARD_ITEM,{tbItemDatas = tbLevelUpAwardData})
    end
    self:CloseSelf()
end


----------life cycle----------

-- function UIPlayerLevelUp:OnCreate()
-- end

-- function UIPlayerLevelUp:OnLoad()
-- end

function UIPlayerLevelUp:OnEnter()
    local tbLevelUpInfo = PlayerBasicInfoSystem:GetAndResetLevelUpInfo()
    local nNewLevel = tbLevelUpInfo[PlayerBasicInfoSystem.NEW_LEVEL_INDEX]
    local _nOldLevel = tbLevelUpInfo[PlayerBasicInfoSystem.OLD_LEVEL_INDEX]
    self.pWidgetRef.kmtxtNewLevel:SetText(nNewLevel)
    local OnAnimationFinished = function ()
        self:PlayAnimation("animShow_Loop", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1, OnAnimationFinished)
end

-- function UIPlayerLevelUp:OnShow()
-- end4

-- function UIPlayerLevelUp:OnHide()
-- end

-- function UIPlayerLevelUp:OnExit()
-- end

-- function UIPlayerLevelUp:OnDestroy()
-- end

-- function UIPlayerLevelUp:OnUnload()
-- end

function UIPlayerLevelUp:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnStart.OnClicked, self, OnConfirmClicked)
end

-- function UIPlayerLevelUp:OnUnbindEvent(EventHelper)
-- end

-- function UIPlayerLevelUp:OnLoadLevelFinished()
-- end


return UIPlayerLevelUp