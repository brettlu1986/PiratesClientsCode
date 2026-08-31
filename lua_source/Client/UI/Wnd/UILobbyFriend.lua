local luaclass              = require("luaclass")
local WndBase               = require("WndBase")
local UILobbyFriend         = luaclass("UILobbyFriend", WndBase)
local ClientEventDef        = require("ClientEventDef")
local SelfVerticalListHelper= require("SelfVerticalListHelper")
local SelfTabBarHelperClass = require("SelfTabBarHelper")
local FriendSystem          = require("FriendSystem")
local UIDef                 = require("UIDef")
local UITextDef             = require("UITextDef")
local UIUtils               = require("UIUtils")
local UISetUtils            = require("UISetUtils")
local Proto                 = require("ClientProtoNames")
local UIManager             = require("UIManager")
local StringUtil            = require("StringUtil")
local L10N                  = require("L10N")
local StatsSystem           = require("StatsSystem")
local UTF8NameHelper        = require("UTF8NameValidatorHelper")
local FriendIni             = require("FriendIni")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local FriendRelationShipLevelDataTable = require("FriendRelationShipLevelDataTable")

UILobbyFriend.pbWindowFrame  = nil
UILobbyFriend.tbTabBarHelper = nil
UILobbyFriend.tbListHelper   = nil
UILobbyFriend.nTabIndex      = nil
UILobbyFriend.tbNameValidator= nil

local SwitchTab = nil

local TAB_FRIEND = 1
local TAB_TEAM = 2
local TAB_NEAR = 3
local TAB_ADDFRIEND = 4
local TAB_RELATION = 5

local nMinType = 1
local nMinLevel = 1

local TAB_LIST = {
    [TAB_FRIEND] = {
        fnGetData = function(Component)
            return Component:GetFriendSummaries()
        end
    },
    [TAB_TEAM] = {
        fnGetData = function(Component)
            return FriendSystem:GetRecentlyTeam() or {}
            -- StatsSystem:RequestGetHistoryStats()
            -- return {}
        end
    },
    [TAB_NEAR] = {
        fnGetData = function(Component)
        end
    },
    [TAB_ADDFRIEND] = {
        fnGetData = function(Component)
            return {}
        end 
    },
    [TAB_RELATION] = {
        fnGetData = function(Component)
            return {}
        end 
    }
}

local function SetData(self, tbDatas)
    local Component = FriendSystem:GetComponent()
    if tbDatas == nil then
        local tbTab = TAB_LIST[self.nTabIndex]
        tbDatas = tbTab.fnGetData(Component)
    end
    if tbDatas ~= nil then
        self.tbListHelper:SetData(tbDatas)
        return true
    else
        UIUtils.ShowToast(UITextDef.FFA_FUNCTION_NOT_OPEN)
        return false
    end
end

local function SwitchFriendsOrRelations(self, bRelation)
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(bRelation and 1 or 0)
    self.pWidgetRef.pbFriends:SetVisibility(bRelation and Collapsed or Visible)
    self.pWidgetRef.pbRelations:SetVisibility(bRelation and Visible or Collapsed)
    if bRelation then  
        local nSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
        self.ulRelations:Activate(self.pWidgetRef.kRelationList, false, nSelfId)
    else  
        self.ulRelations:Deactivate()
    end
end

SwitchTab = function(self, nTabIndex)
    self.nTabIndex = nTabIndex

    SwitchFriendsOrRelations(self, self.nTabIndex == TAB_RELATION)

    if not SetData(self) then
        SwitchTab(self, TAB_FRIEND)
        return
    end

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtId:SetText("")
    pWidgetRef.txtNoPlayer:SetText("")
    local Visible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.cvpNear:SetVisibility(self.nTabIndex == TAB_NEAR and Visible or Collapsed)
    pWidgetRef.hboxAddFriend:SetVisibility(self.nTabIndex == TAB_ADDFRIEND and Visible or Collapsed)
    pWidgetRef.imgLine:SetVisibility(self.nTabIndex == TAB_ADDFRIEND and Visible or Collapsed)
    pWidgetRef.hboxJustTeam:SetVisibility(self.nTabIndex == TAB_TEAM and Visible or Collapsed)
    pWidgetRef.hboxBlack:SetVisibility(self.nTabIndex == TAB_FRIEND and Visible or Collapsed)
    pWidgetRef.Border_1:SetVisibility(self.nTabIndex == TAB_FRIEND and Visible or Collapsed)
    
end

-- local function RefreshTabCount(self)
--      local Component = FriendSystem:GetComponent()
--     for i = 1, #TAB_LIST do 
--         local tbData = TAB_LIST[i].fnGetData(Component)
--         if tbData ~= nil and #tbData > 0 then
--             self.tbTabBarHelper:SetTipIconVisible(i, true)
--             self.tbTabBarHelper:SetTipCount(i, #tbData)
--         else
--             self.tbTabBarHelper:SetTipIconVisible(i, false)
--         end
--     end
-- end

local function RefreshApplyCount(self)
    local FriendComponent = FriendSystem:GetComponent()
    if FriendComponent ~= nil then
        local bHad = FriendComponent:HadApplies()
        self.pWidgetRef.btnApplyList:HideTipIcon(not bHad)
        self.tbTabBarHelper:SetTipIconVisible(TAB_FRIEND, bHad)
    else
        self.pWidgetRef.btnApplyList:HideTipIcon(true)
        self.tbTabBarHelper:SetTipIconVisible(TAB_FRIEND, false)
    end
end

local function RefreshNotProcessRelationRedDot(self)
    local FriendComponent = FriendSystem:GetComponent()
    if FriendComponent then
        self.tbTabBarHelper:SetTipIconVisible(TAB_RELATION, FriendComponent:HasRedDotRelation())
    end
end 

local function OnRefreshFriendList(self)
    if self.nTabIndex == TAB_FRIEND then
        SetData(self)
    end
    -- RefreshTabCount(self)
    RefreshApplyCount(self)
end

-- local function RefreshRecentTeam(self, tbTeam)
--     if self.nTabIndex == TAB_TEAM then
--         SetData(self, tbTeam)
--     end
-- end

local function OnSearchFriend(self, tbPacket)
    if self.nTabIndex == TAB_ADDFRIEND then
        if tbPacket.return_code ~= Proto.ReturnCode.OK then
            self.pWidgetRef.txtNoPlayer:SetText(UISetUtils.GetL10NTextByKey("UI_FRIEND_SEARCH_NOPLAYER"))
            SetData(self, {})
        else
            self.pWidgetRef.txtNoPlayer:SetText("")
            local tbDatas = {}
            for i, v in ipairs(tbPacket.player_summary) do
                local tbData = v
                tbData.bSearch = true
                table.insert(tbDatas, tbData)
            end
            SetData(self, tbDatas)
        end
    end
end

local function OnClickSearch(self)
    local szText = L10N:ToString(self.pWidgetRef.txtId:GetText())
    local szInput = StringUtil.Trim(szText)
    if szInput ~= szText then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FRIEND_ID_IVALID"))
        return
    end 
    local nId = tonumber(szInput)
    if nId ~= nil then
        FriendSystem:RequestPreciseSearch(nId)
    else
        local nRet, _ = self.tbNameValidator:Validate(szInput)
        if nRet == self.tbNameValidator.Result.InvalidUTF8 then
            UIUtils.ShowToast(UITextDef.USER_NAME_ID_EMPTY)
            return
        elseif nRet == self.tbNameValidator.Result.InvalidLength then
            UIUtils.ShowToast(UITextDef.USER_NAME_LEN_ERROR)
            return
        elseif nRet == self.tbNameValidator.Result.InvalidCodePoint then
            UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
            return
        end
        FriendSystem:RequestPreciseSearch(szInput)
    end
end

local function OnTabBarSelectedChanged(self, nIndex)
    SwitchTab(self, nIndex)
end

local function OnClickBlackList(self)
    UIUtils.ShowToast(UITextDef.BLACK_LIST_EMPTY)
    -- UIManager:OpenWnd(UIDef.UI_LOBBY_FRIEND_BLACKLIST)
end

local function OnClickApplyList(self)
    local tbApplies = FriendSystem:GetComponent():GetApplyFriends()
    if #tbApplies > 0 then
        -- FriendSystem:RequestGetApplyFriends()
        UIManager:OpenWnd(UIDef.UI_LOBBY_FRIEND_APPLYLIST)
    else
        UIUtils.ShowToast(UITextDef.APPLY_FRIEND_LIST_EMPTY)
    end
end

local function RefeshTipsInfo(self)
    local l10nStr = UISetUtils.GetL10NTextByKey("UI_RELATION_TIPS_ORDER")
    l10nStr = L10N:Format(l10nStr, FriendIni.nOrderInimacy)
    self.pWidgetRef.txtTips1:SetText(l10nStr)

    l10nStr = UISetUtils.GetL10NTextByKey("UI_RELATION_TIPS_DETAIL")
    
    local tbInfo = FriendRelationShipLevelDataTable:GetDataTemplate(nMinType, nMinLevel)
    l10nStr = L10N:Format(l10nStr, tbInfo.nIntimacyLimit)
    self.pWidgetRef.txtNotes:SetText(l10nStr)
end

local function ShowRelationTips(self)
    UIManager:OpenWnd(UIDef.UI_FRIEND_RELATION_TIPS)
end

function UILobbyFriend:OnLoad()
    local pWidgetRef = self.pWidgetRef

    self.tbTabBarHelper:Init(self, pWidgetRef.vboxTabBar, TAB_FRIEND)
    self.tbListHelper:Init(self, pWidgetRef.klistItem)

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(pWidgetRef.pbWindowFrame)

    local UILogicHelper = self.UILogicHelper
    self.ulRelations = UILogicHelper:CreateUILogic("ULLobbyFriendRelations")
    -- self.pbWindowFrame:SetOuterWnd(UIDef.UI_LOBBY_FRIEND)
end

function UILobbyFriend:OnCreate()
    self.tbTabBarHelper = SelfTabBarHelperClass()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbNameValidator = UTF8NameHelper:CreatePlayerNameValidator()
end


function UILobbyFriend:OnShow()
    local nTab = self.tbOpenArgs.nSelectTab
    if nTab ~= nil then
        SwitchTab(self, nTab)
        self.tbTabBarHelper:SelectByIndex(nTab)
    else
        SwitchTab(self, TAB_FRIEND)
        self.tbTabBarHelper:SelectByIndex(TAB_FRIEND)
    end
    -- RefreshTabCount(self)
    RefeshTipsInfo(self)
    RefreshApplyCount(self)
    RefreshNotProcessRelationRedDot(self)
    StatsSystem:RequestGetHistoryStats()
    UIUtils.BottomMenuUnselectAll()
    self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyFriend:OnDestroy()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
    self.tbTabBarHelper:Uninit()
    self.tbTabBarHelper = nil
    self.pbWindowFrame = nil
end

function UILobbyFriend:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterLuaDelegate(self.tbTabBarHelper.OnSelectedChangedDelegate, OnTabBarSelectedChanged, self)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSearch.OnClicked, self, OnClickSearch)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBlackList.OnClicked, self, OnClickBlackList)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnApplyList.OnClicked, self, OnClickApplyList)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnTips1.OnClicked, self, ShowRelationTips)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTips2.OnClicked, self, ShowRelationTips)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, OnRefreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SEARCH_FRIEND, self, OnSearchFriend)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS, self, RefreshApplyCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_RELATION_NOT_PROCESS_REDDOT, self, RefreshNotProcessRelationRedDot)
    
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM, self, RefreshRecentTeam)
end

return UILobbyFriend
