local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIScheduleContinuous = luaclass("UIScheduleContinuous", WndBase)
local UIDef = require("UIDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local UIManager = require("UIManager")

local MAX_COUNT = 15

UIScheduleContinuous.tbDays = nil

local function OnClickedClose(self)
    self:CloseSelf()
    if self.tbOpenArgs.szFrom ~= nil and self.tbOpenArgs.szFrom ~= "LobbyMain" then
        UIManager:OpenWnd(self.tbOpenArgs.szFrom, {szFrom = UIDef.UI_SCHEDULE_NOOB_LOGIN, nId = self.tbOpenArgs.nId})
    end 
end

function UIScheduleContinuous:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper

    self.tbDays = {}
    for i = 1, MAX_COUNT do
        local pbDay = PrefabHelper:BindPrefab(pWidgetRef["pbScheduleContinuous"..i], UIDef.UP_SCHEDULE_CONTINUOUS)
        pbDay:Init(i)
        table.insert(self.tbDays, pbDay)
    end
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
end

function UIScheduleContinuous:OnShow()
end

function UIScheduleContinuous:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickedClose)
end

function UIScheduleContinuous:OnDestroy()
    self.tbDays = nil
end

function UIScheduleContinuous:OnSelect(nId, nIndex)
end


function UIScheduleContinuous:OnPause()
    local nSubSystem = LobbySystem:GetActiveSub()
    log("UIScheduleContinuous:OnPause:nSubSystem.nSubType=",nSubSystem.nSubType)
    if nSubSystem and (nSubSystem.nSubType == LobbySubTypeDef.AWARD) then
        self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function UIScheduleContinuous:OnResume()
    log("UIScheduleContinuous:OnResume")
    if not self.pWidgetRef:IsVisible() then
        self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        -- UIUtils.BottomMenuUnselectAll()
    end
end

return UIScheduleContinuous
