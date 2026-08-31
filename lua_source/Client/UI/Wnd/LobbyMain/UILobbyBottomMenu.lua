-----------------------------------------------------
--File Name    : UILobbyBottomMenu.lua
--Create Time  : 2020-04-16
--Description  : 大厅主界面底部菜单
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyBottomMenu = luaclass("UILobbyBottomMenu", WndBase)

-- import require
local SelfCheckBoxGroupHelper = require("SelfCheckBoxGroupHelper")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
--local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")

local DEFAULT_MENU_INDEX = 1

UILobbyBottomMenu.tbMenuList = nil
UILobbyBottomMenu.nLastSelectIndex = nil
UILobbyBottomMenu.tbSubTabIndex = nil

local function AddMenu(self, nLobbySubType, ClickFunc)
    local tbMenuItem = {}
    tbMenuItem.nLobbySubType = nLobbySubType
    tbMenuItem.ClickFunc = ClickFunc
    table.insert(self.tbMenuList, tbMenuItem)
    self.tbSubTabIndex[nLobbySubType] = #self.tbMenuList
end

local function OnCheckBoxSelectChanged(self, nIndex)
    local tbMenuItem = self.tbMenuList[nIndex]
    if not tbMenuItem then
        return
    end
    log("UILobbyBottomMenu:OnCheckBoxSelectChanged", nIndex)
    --UIManager:ResetCurrentState()
    LobbySystem:Activate(tbMenuItem.nLobbySubType)
    if tbMenuItem.ClickFunc then
        tbMenuItem.ClickFunc(self, nIndex)
    end
end

local function RefreshCaptainRedDot(self)
    local bRedDotVisible = false
    if UILobbyCaptainHelper.HasNewHumanVisualItem() then
            bRedDotVisible = true
    end
    self.CheckBoxGroupHelper:SetRedDot(bRedDotVisible, 2)
end

local function RefreshSailorRedDotVisible(self)
    local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
    local bRedDotVisible = SailorComponent:GetSailorRedDotVisible()
    self.CheckBoxGroupHelper:SetRedDot(bRedDotVisible, 4)
end

local function OnRefreshBackpackTipIcon(self)
    local PlayerNewItemRecordComponent = GamePlayerSelfHelper:Get().PlayerNewItemRecordComponent
    local bHasNew = PlayerNewItemRecordComponent:HasNewItemInBackpack()
    self.CheckBoxGroupHelper:SetRedDot(bHasNew, 5)
end

local function OnRefreshShipTipIcon(self, bNew, nTemplateId)
    local LobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
    local bHasNew = LobbyShip:CheckLobbyShipShowTipIcon()
    self.CheckBoxGroupHelper:SetRedDot(bHasNew, 3)
end

local function OnPreOpenUI(self, szWndName)
    if szWndName == UIDef.UI_MAIL or szWndName == UIDef.UI_LOBBY_FRIEND or szWndName == UIDef.UI_PLAYER_INFO
    or szWndName == UIDef.UI_DEBUG_WIDGET then
        self.CheckBoxGroupHelper:UnselectAll()
    end
end

local function OnSubSystemActivate(self, nSubType)
    local pWidgetRef = self.pWidgetRef
    for k, v in ipairs(self.tbMenuList) do
        local imgEffect = pWidgetRef["imgChecked0"..k]
        if imgEffect then
            if v.nLobbySubType == nSubType then
                imgEffect:SetVisibility(ESlateVisibility_HitTestInvisible)
                self:PlayAnimation("animCheckedIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
                self.CheckBoxGroupHelper:SelectByIndex(k)
            else
                imgEffect:SetVisibility(ESlateVisibility_Hidden)
            end
        end
    end
end

-- local function NoFunc()
--     UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_NO_FUNC"))
-- end


--注册菜单项
local function RegisterAllMenus(self)
    self.tbMenuList = {}
    self.tbSubTabIndex = {}
    AddMenu(self, LobbySubTypeDef.MAIN,       nil)      --大厅
    AddMenu(self, LobbySubTypeDef.CAPTAIN,    nil)      --船长
    AddMenu(self, LobbySubTypeDef.SHIP,       nil)      --舰船
    AddMenu(self, LobbySubTypeDef.SAILOR,     nil)      --水手
    AddMenu(self, LobbySubTypeDef.BACKPACK,   nil)      --背包
end

function UILobbyBottomMenu:OnCreate()
    RegisterAllMenus(self)
end

function UILobbyBottomMenu:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.CheckBoxGroupHelper = SelfCheckBoxGroupHelper()
    self.CheckBoxGroupHelper:Init(self, self.pWidgetRef.hbxBottomMenu)
    self.CheckBoxGroupHelper.OnSelectedChangedDelegate:Bind(OnCheckBoxSelectChanged, self)
    self.nLastSelectIndex = -1
    local UILogicHelper = self.UILogicHelper
    local ulFFAMainStaticLayout = UILogicHelper:CreateUILogic("ULFFAMainStaticLayout")
    ulFFAMainStaticLayout:Init()
end

function UILobbyBottomMenu:OnEnter()
    --self.nLastSelectIndex = DEFAULT_MENU_INDEX
    
    RefreshSailorRedDotVisible(self)
    RefreshCaptainRedDot(self)
    OnRefreshBackpackTipIcon(self)
    OnRefreshShipTipIcon(self)
end

function UILobbyBottomMenu:OnShow()
    self:PlayAnimation("anim_LobbyMainIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self.CheckBoxGroupHelper:SelectByIndex(DEFAULT_MENU_INDEX, true)
end

function UILobbyBottomMenu:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshCaptainRedDot)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED, self, RefreshSailorRedDotVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_OPEN_UI, self, OnPreOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, self, OnSubSystemActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_NEW_STATE_IN_BACKPACK, self, OnRefreshBackpackTipIcon)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SHIP_TIP_ICON, self, OnRefreshShipTipIcon)
end

function UILobbyBottomMenu:OnDestroy()
    if self.CheckBoxGroupHelper then
        self.CheckBoxGroupHelper:Uninit()
    end
end

function UILobbyBottomMenu:HideBottom(bHide)
    self.pWidgetRef:SetVisibility(bHide and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible )
end
--外部接口
function UILobbyBottomMenu:SelectMenu(nSubType, bForceActivateSub)
    local nIndex = self.tbSubTabIndex[nSubType]
    if not nIndex then
        log("UILobbyBottomMenu:SelectMenu, no bottom menu", nSubType)
        return 
    end
    log("UILobbyBottomMenu:SelectMenu", nSubType, nIndex)
    OnSubSystemActivate(self, nSubType)
    self.CheckBoxGroupHelper:SelectByIndex(nIndex, bForceActivateSub)
end

function UILobbyBottomMenu:UnselectAll()
    self.CheckBoxGroupHelper:UnselectAll()
    local pWidgetRef = self.pWidgetRef
    local imgEffect = nil
    for k, v in ipairs(self.tbMenuList) do
        imgEffect = pWidgetRef["imgChecked0"..k]
        if imgEffect then
            imgEffect:SetVisibility(ESlateVisibility_Hidden)
        end
    end
end

return UILobbyBottomMenu
