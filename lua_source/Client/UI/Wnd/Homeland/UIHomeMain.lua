-----------------------------------------------------
--File Name    : UIHomeMain.lua
--Author       : zhiyuan
--Create Time  : 2019-04-19
--Description  : 家园主界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIHomeMain = luaclass("UIHomeMain", WndBase)
local HomelandSystem = require("HomelandSystem")
local HomelandModeDef = require("HomelandModeDef")
local UITextDef = require("UITextDef")
local UIDef = require("UIDef")
local UIResourceDef = require("UIResourceDef")
local UIManager = require("UIManager")
local FriendSystem = require("FriendSystem")
local ClientEventDef = require("ClientEventDef")

UIHomeMain.ulHomeTrigger = nil
UIHomeMain.pbLobbyTeam = nil

local function OnClickReturnLobby()
    HomelandSystem:LeaveHomeland()
end

local function OnClickFriend()
    UIManager:OpenWnd(UIDef.UI_LOBBY_FRIEND)
end

local function OnHomelandModeChanged(self, bIsChecked)
    local ktxtModeName = self.pWidgetRef.ktxtModeName
    if bIsChecked then
        HomelandSystem:ChangeMode(HomelandModeDef.NORMAL)
        ktxtModeName:SetText(UITextDef.UI_HOMELAND_MODE_NORMAL)
    else
        HomelandSystem:ChangeMode(HomelandModeDef.BUILD)
        ktxtModeName:SetText(UITextDef.UI_HOMELAND_MODE_BUILD)
    end
end

local function OnRefreshFriendApplyCount(self)
    local FriendComponent = FriendSystem:GetComponent()
    if FriendComponent ~= nil then
        self.pWidgetRef.btn02:HideTipIcon(not FriendComponent:HadApplies())
    else
        self.pWidgetRef.btn02:HideTipIcon(true)
    end
end

local function OnClickedBtnInviteTeam(self)
    self.bOpenTeam = not self.bOpenTeam
    if self.bOpenTeam then
        self.pbLobbyTeam:ShowTeam()
        self.pWidgetRef.pbLobbyTeam:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self:PlayAnimation("animTeam", 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        self:PlayAnimation("animTeam", 0, 1, EUMGSequencePlayMode.Reverse, 1)
        self.pbLobbyTeam:HideTeam()
    end
end

function UIHomeMain:SetModeButtonVisible(bVisible)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ovlBuildBtn:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

function UIHomeMain:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulHomeTrigger = UILogicHelper:CreateUILogic("ULHomeTrigger")

    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    PrefabHelper:BindPrefab(pWidgetRef.pbCurrencyBar)
    local pbVirtualJoystick = PrefabHelper:BindPrefab(pWidgetRef.pbVirtualJoystick, UIDef.UP_HUMAN_VIRTUALSTICK)
    pbVirtualJoystick:SetVirtualJoystickIcon(UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON)
    PrefabHelper:BindPrefab(pWidgetRef.pbRadarMap, UIDef.UP_HOMELAND_RADAR_MAP)
    self.pbLobbyTeam = PrefabHelper:BindPrefab(pWidgetRef.pbLobbyTeam)
end



function UIHomeMain:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmBtnReturn.OnClicked, self, OnClickReturnLobby)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkBuild.OnCheckStateChanged, self, OnHomelandModeChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btn02.OnClicked, self, OnClickFriend)
    EventHelper:RegisterCppDelegate(pWidgetRef.btn03.OnClicked, self, OnClickedBtnInviteTeam)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS, self, OnRefreshFriendApplyCount)
end

function UIHomeMain:OnEnter()
    local pWidgetRef = self.pWidgetRef

    local nMode = HomelandSystem:GetCurrentMode()
    local bHomeModeChecked = (nMode == HomelandModeDef.NORMAL)

    pWidgetRef.chkBuild:SetIsChecked(bHomeModeChecked)
    OnHomelandModeChanged(self, bHomeModeChecked)
    OnRefreshFriendApplyCount(self)
end

function UIHomeMain:OnHide()

end

return UIHomeMain