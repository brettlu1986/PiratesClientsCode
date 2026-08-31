-----------------------------------------------------
--File Name    : UIMail.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 2:56:33 PM
--Description  : UIMail
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDef = require("UIDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIUtils = require("UIUtils")

local UIMail = luaclass("UIMail", WndBase)


local UITabContentCategory = {}
UITabContentCategory.System        = 1
UITabContentCategory.Friend        = 2
UITabContentCategory.MessageCenter = 3


UIMail.nCurrentTabCategory = UITabContentCategory.System
UIMail.tbULTabContent = {}
UIMail.ULMailCommon = nil
UIMail.ListHelper = nil


local function OnTabBarSelectedChanged(self, nTabIndex)
    local nLastIndex = self.nCurrentTabCategory
    self.nCurrentTabCategory = nTabIndex
    self.tbULTabContent[nLastIndex]:Deactivate()
    self.tbULTabContent[nTabIndex]:Activate()
end

local function SelectTab(self, nIndex)
    OnTabBarSelectedChanged(self, nIndex)
end

local function CreateListHelper(self)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.pList, {}, UIDef.UP_MAIL_LIST_ITEM)
end

local function InitWindowFrame(self)
    local pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    pbWindowFrame:SetSelectedTabChanged(OnTabBarSelectedChanged, self)
    self.pbWindowFrame = pbWindowFrame
end

local function RefreshUnreadMailCount(self)
    local tbTabBarHelper = self.pbWindowFrame:GeTabBarHelper()
    for k, v in pairs(UITabContentCategory) do
        local nCount = self.tbULTabContent[v]:GetUnreadMailCount()
        tbTabBarHelper:SetTipIconVisible(v, nCount > 0)
        -- tbTabBarHelper:SetTipCount(v, nCount)
    end
end

local function OnMailSynced(self)
    RefreshUnreadMailCount(self)
    SelectTab(self, self.nCurrentTabCategory)
end

local function OnMailMarked(self)
    RefreshUnreadMailCount(self)
    SelectTab(self, self.nCurrentTabCategory)
end

local function OnMailDeleted(self)
    RefreshUnreadMailCount(self)
    SelectTab(self, self.nCurrentTabCategory)
end

local function OnMailAttachmentGet(self)
    RefreshUnreadMailCount(self)
    SelectTab(self, self.nCurrentTabCategory)
end

local function InitULMailCommon(self)
    self.ULMailCommon = self.UILogicHelper:CreateUILogic("ULMailCommon")
    self.ULMailCommon:SetOnMailSyncedCallback(function() OnMailSynced(self) end)
    self.ULMailCommon:SetOnMailMarkedCallback(function() OnMailMarked(self) end)
    self.ULMailCommon:SetOnMailDeletedCallback(function() OnMailDeleted(self) end)
    self.ULMailCommon:SetOnMailAttachmentGetCallback(function() OnMailAttachmentGet(self) end)
end

local function OnMarkAllMailReadBtnClicked(self)
    self.ULMailCommon:MarkAllMailsRead()
end

local function OnGetAllMailAttachmentsBtnClicked(self)
    self.ULMailCommon:GetAllMailAttachments()
end

local function OnDeleteAllReadedMailBtnClicked(self)
    self.ULMailCommon:DeleteAllMails()
end

local function InitULMailBoxSystem(self)
    local ULMailBoxSystem = self.UILogicHelper:CreateUILogic("ULMailBoxSystem")
    ULMailBoxSystem:Init()
    self.tbULTabContent[UITabContentCategory.System] = ULMailBoxSystem
end
local function InitULMailBoxFriend(self)
    local ULMailBoxFriend = self.UILogicHelper:CreateUILogic("ULMailBoxFriend")
    ULMailBoxFriend:Init()
    self.tbULTabContent[UITabContentCategory.Friend] = ULMailBoxFriend
end
local function InitULMailBoxMessageCenter(self)
    local ULMailBoxMessageCenter = self.UILogicHelper:CreateUILogic("ULMailBoxMessageCenter")
    ULMailBoxMessageCenter:Init()
    self.tbULTabContent[UITabContentCategory.MessageCenter] = ULMailBoxMessageCenter
end


----------life cycle----------

function UIMail:OnLoad()
    InitWindowFrame(self)
    InitULMailCommon(self)
    InitULMailBoxSystem(self)
    InitULMailBoxFriend(self)
    InitULMailBoxMessageCenter(self)
    CreateListHelper(self)
end


function UIMail:OnUnload()
    for k, v in pairs(self.tbULTabContent) do
        v:Uninit()
    end
    self.ListHelper:Uninit()
end

function UIMail:OnEnter()
    self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1)
    UIUtils.BottomMenuUnselectAll()
end

function UIMail:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnMarkReadAll.OnClicked, self, OnMarkAllMailReadBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnGetAll.OnClicked, self, OnGetAllMailAttachmentsBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnDeleteAll.OnClicked, self, OnDeleteAllReadedMailBtnClicked)
end


return UIMail