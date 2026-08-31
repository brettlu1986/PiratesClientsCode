-----------------------------------------------------
--File Name    : UILobbyCaptain.lua
--Author       : WuJizhou
--Create Time  : 5/6/2020, 4:21:07 PM
--Description  : UILobbyCaptain
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")

local UILobbyCaptain = luaclass("UILobbyCaptain", WndBase)


local ClientEventDef = require("ClientEventDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local LobbyCaptainMiscDef = require("LobbyCaptainMiscDef")
local UIUtils = require("UIUtils")

UILobbyCaptain.tbTabBarHelper = nil
UILobbyCaptain.pbWindowFrame = nil

local FeatureType = LobbyCaptainMiscDef.FeatureType


local function OnFeatureBtnClicked(self, nFeatureType)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_ACIVATE_FEATURE, nFeatureType)
end

local function OnBack()
    UIUtils.BottomMenuSelect(1, true)
end

----------life cycle----------

-- function UILobbyCaptain:OnCreate()
-- end

function UILobbyCaptain:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBack, self)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxContainer, -1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnFeatureBtnClicked, self)
    local tbFeatureParams = self.tbOpenArgs.tbFeatures
    for _, nFeatureType in pairs(FeatureType) do
        local tbFeatureData = tbFeatureParams[nFeatureType]
        if tbFeatureData then
            self.tbTabBarHelper:SetVisibilityByIndex(nFeatureType, ESlateVisibility_SelfHitTestInvisible)
            self.tbTabBarHelper:SetTabText(nFeatureType, tbFeatureData.l10nTabKey)
        else
            self.tbTabBarHelper:SetVisibilityByIndex(nFeatureType, ESlateVisibility_Collapsed)

        end
    end
    self.UILogicHelper:CreateUILogic("ULLobbyCaptainRedDot")
end

-- function UILobbyCaptain:OnEnter()
-- end

function UILobbyCaptain:OnShow()
    self:PlayAnimation("anim_LobbyCaptainIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

-- function UILobbyCaptain:OnHide()
-- end

-- function UILobbyCaptain:OnExit()
-- end

-- function UILobbyCaptain:OnDestroy()
-- end

function UILobbyCaptain:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbyCaptain:OnBindEvent(EventHelper)
    
end


-- function UILobbyCaptain:OnLoadLevelFinished()
-- end


return UILobbyCaptain