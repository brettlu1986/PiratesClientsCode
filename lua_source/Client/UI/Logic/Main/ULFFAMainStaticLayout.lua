-----------------------------------------------------
--File Name    : ULFFAMainStaticLayout.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-23
--Description  : 用于适配静态UI的动态布局
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAMainStaticLayout = luaclass("ULFFAMainStaticLayout", UILogicBase)

local UIDef = require("UIDef")
local ScreenShapeHelper = require("ScreenShapeHelper")

local STATIC_WIDGET_TREE = {
    [UIDef.UI_FFA_MAIN] = {
        ["vboxPlayerStatus"]        = false,
        ["pbFFAHuman"]              = {
            ["ovlHeard"]            = false,
        }
    },
    [UIDef.UI_WATCHBATTLE] = {
        ["vboxPlayerStatus"]        = false,
        ["ImgRole"]                 = false,
        ["ImageWeaponBg"]           = false,
        ["SBWeapon"]               = false,
        ["ImageColor"]              = false,
        ["ImageLevel"]              = false,
        ["ImageThrow"]              = false,
        ["ImageWeaponThrow"]        = false,
        ["bulletInfo"]              = false,
    },
    [UIDef.UI_SETTING_LAYOUT] = {
        ["pbSubWidget"]             = {
            ["bdrHeart"]            = false,
        }
    },
    [UIDef.UI_LOBBY_BOTTOM_MENU] = {
        ["bdrDownBtn"]              = false,
    }
}

ULFFAMainStaticLayout.nBottonMargin = 0
ULFFAMainStaticLayout.fnWidgetByNameGetter = nil

local function UpdateWidget(self, pWidgetRef)
    if pWidgetRef then
        local pWidgetSlotRef = pWidgetRef.Slot
        local pPosition = pWidgetSlotRef:GetPosition()
        pPosition.Y = pPosition.Y - self.nBottonMargin
        pWidgetSlotRef:SetPosition(pPosition)
    end
end

local function GetWidget(self, pRootWidgetRef, szWidgetName)
    local pWidgetRef = pRootWidgetRef[szWidgetName]
    if pWidgetRef then
        return pWidgetRef
    end
    if self.fnWidgetByNameGetter then
        return self.fnWidgetByNameGetter(szWidgetName)
    end
    return nil
end

local function UpdateWidgets(self, pRootWidgetRef, tbWidgets)
    for szWidgetName, tbChildWidgets in pairs(tbWidgets) do
        local pWidgetRef = GetWidget(self, pRootWidgetRef, szWidgetName)
        if tbChildWidgets then
            UpdateWidgets(self, pWidgetRef, tbChildWidgets)
        else
            UpdateWidget(self, pWidgetRef)
        end
    end
end

-- 初始化适配类
-- @fnWidgetByNameGetter 适用于UI中动态创建的Widget获取
function ULFFAMainStaticLayout:Init(fnWidgetByNameGetter)
    local tbOwnerTemplate = self.Owner.tbTemplate
    local szName = tbOwnerTemplate.szWndName or tbOwnerTemplate.szPrefabName
    self.nBottonMargin = ScreenShapeHelper.GetSafeZoneMarginBottom()
    local tbWidgets = STATIC_WIDGET_TREE[szName]
    if (self.nBottonMargin > 0) and tbWidgets then
        self.fnWidgetByNameGetter = fnWidgetByNameGetter
        UpdateWidgets(self, self.pWidgetRef, tbWidgets)
    end
end

return ULFFAMainStaticLayout