local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIScheduleNoobLogin = luaclass("UIScheduleNoobLogin", WndBase)
local SelfListHelperNew = require("SelfListHelperNew")
local ScheduleSystem = require("ScheduleSystem")
local ClientEventDef = require("ClientEventDef")
local NoobLoginDataTable = require("NoobLoginDataTable")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

local NOOBLOGINSTATE = {
    UNREACH = -1,
    UNGET = 0,
    GETED = 1
}

local SCROLLDEST_INTOVIEW = 1

UIScheduleNoobLogin.ListHelper = nil

local function ScrollToFirstUnget(self, tbData)
    local nIndex
    for i, v in ipairs(tbData) do
        if v.nState == NOOBLOGINSTATE.UNGET then
            nIndex = i
            break
        end
    end
    if nIndex == nil then
        for i, v in ipairs(tbData) do
            if v.nState == NOOBLOGINSTATE.UNREACH then
                nIndex = i
                break
            end
        end
    end
    if nIndex == nil then
        nIndex = 1
    end
    self.pWidgetRef.kmList:ScrollToIndex(nIndex - 1, SCROLLDEST_INTOVIEW, false)
end

local function RefreshUI(self, bScroll)
    local Component = ScheduleSystem:GetComponent()
    local tbData = Component:GetNoobLogin()
    local nMaxCount = NoobLoginDataTable:GetCount()
    if tbData == nil then
        -- 已结束，则客户端自己构造全部获取奖励的数据
        tbData = {} 
        for i = 1, nMaxCount do
            table.insert(tbData, {nDay = i, nState = NOOBLOGINSTATE.GETED})
        end 
        self.ListHelper:SetData(tbData)
    elseif #tbData < nMaxCount then
        local tbTemp = {}    
        -- 登录天数小于奖励表中的天数
        for i, v in ipairs(tbData) do
            table.insert(tbTemp, v)
        end
        for i = #tbData + 1, nMaxCount do
            table.insert(tbTemp, {nDay = i, nState = NOOBLOGINSTATE.UNREACH})
        end
        self.ListHelper:SetData(tbTemp)
        if bScroll then
            ScrollToFirstUnget(self, tbTemp)
        end
    else
        self.ListHelper:SetData(tbData)
        if bScroll then    
            ScrollToFirstUnget(self, tbData)
        end
    end
end

local function OnClickClose(self)
    self:CloseSelf()
    if self.tbOpenArgs.szFrom ~= nil and self.tbOpenArgs.szFrom ~= "LobbyMain" then
        UIManager:OpenWnd(self.tbOpenArgs.szFrom, {szFrom = UIDef.UI_SCHEDULE_NOOB_LOGIN, nId = self.tbOpenArgs.nId})
    end 
end

function UIScheduleNoobLogin:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, self.pWidgetRef.kmList)
end

function UIScheduleNoobLogin:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UIScheduleNoobLogin:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickClose)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH, self, RefreshUI)
end

function UIScheduleNoobLogin:OnShow()
    RefreshUI(self, true)
    self:PlayAnimation("animScheduleNoobLoginIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

-- function UIScheduleNoobLogin:OnPause()
--     local nSubSystem = LobbySystem:GetActiveSub()
--     log("UIScheduleNoobLogin:OnPause:nSubSystem.nSubType=",nSubSystem.nSubType)
--     if nSubSystem and (nSubSystem.nSubType == LobbySubTypeDef.AWARD) then
--         self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
--     end
-- end

-- function UIScheduleNoobLogin:OnResume()
--     log("UIScheduleNoobLogin:OnResume")
--     if not self.pWidgetRef:IsVisible() then
--         self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
--         -- UIUtils.BottomMenuUnselectAll()
--     end
-- end

return UIScheduleNoobLogin
