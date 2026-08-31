-----------------------------------------------------
--File Name    : UIDebugWidget.lua
--Author       : Zhang Yuzhen
--Create Time  : 2017-7-11
--Description  : 游戏调试面板界面
--Param        :
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDebugWidget = luaclass("UIDebugWidget", WndBase)

local UIDef = require("UIDef")
local SaveGameDef = require("SaveGameDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local DebugPanelDefDataTable = require("DebugPanelDefDataTable")
local ClientEventDef = require("ClientEventDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local UIUtils = require("UIUtils")

UIDebugWidget.tbTabBarHelper = nil
UIDebugWidget.tbTabContentWidgets = nil

local function OnChannelChanged(self, nIndex)
    local tbTemplate = DebugPanelDefDataTable:GetTemplate(nIndex)
    if tbTemplate then
        if self.tbTabContentWidgets[nIndex] == nil then
            local pbDebugPanel = self.PrefabHelper:CreatePrefab(tbTemplate.szPrefabName)
            self.pWidgetRef.wsContent:AddChild(pbDebugPanel.pWidgetRef)
            self.tbTabContentWidgets[nIndex] = pbDebugPanel
        end
        self.pWidgetRef.wsContent:SetActiveWidget(self.tbTabContentWidgets[nIndex].pWidgetRef)
        local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
        pSaveGameMgr:AddIntData(SaveGameDef.DEBUG_PANEL_LAST_INDEX, nIndex)
    end
end

local function UpdateClientVersion(self)
    local szVersion = BuglyCrashReportBPLibrary.GetAppVersion()
    if #szVersion > 0 then
        self.pWidgetRef.txtVersion:SetText("Version:" .. szVersion)
        self.pWidgetRef.txtVersion:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end

local function InitTabBarHelper(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local nLastIndex = pSaveGameMgr:GetIntData(SaveGameDef.DEBUG_PANEL_LAST_INDEX)
    nLastIndex = (nLastIndex <= 0) and 1 or nLastIndex

    for i,v in ipairs(DebugPanelDefDataTable.tbContainer) do
        local pbTabButton = self.PrefabHelper:CreatePrefab(UIDef.UP_TAB_BUTTON_LOBBY)
        pbTabButton:Init(i)
        pbTabButton:SetResourceText(v.szTitleName)
        self.pWidgetRef.scrTab:AddChild(pbTabButton.pWidgetRef)
    end

    self.tbTabContentWidgets = {}
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.scrTab, nLastIndex)
    OnChannelChanged(self, nLastIndex)
end

local function OnUserWidgetTouchEnded(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, UIDef.UI_DEBUG_WIDGET, pGeometry, pMouseEvent)
end

-- override
function UIDebugWidget:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)

    InitTabBarHelper(self)
    UpdateClientVersion(self)
end

function UIDebugWidget:OnUnload()
    self.tbTabContentWidgets = nil
    self.tbTabBarHelper:Uninit()
end

function UIDebugWidget:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.tbTabBarHelper.OnSelectedChangedDelegate, OnChannelChanged, self)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.OnTouchEndedEvent, self, OnUserWidgetTouchEnded)
end

function UIDebugWidget:OnEnter()
    UIUtils.BottomMenuUnselectAll()
end

function UIDebugWidget:OnResume()
    UIUtils.BottomMenuUnselectAll()
end

-- @Override
function UIDebugWidget:CanOpen()
    return GlobalVariableSystem:IsDevMode()
end

return UIDebugWidget
