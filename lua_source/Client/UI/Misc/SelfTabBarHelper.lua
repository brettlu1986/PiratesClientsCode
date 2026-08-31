-----------------------------------------------------
--File Name    : SelfTabBarHelper.lua
--Author       : Song Fuhao
--Create Time  : 2017-02-10
--Description  : SelfTabBarHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfTabBarHelper = luaclass("SelfTabBarHelper")

local LuaDelegate = require("LuaDelegate")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UninitCheckSystem = require("UninitCheckSystem")

local DEFAULT_SELECTED_IDX = 1

--[[
    OnSelectedChangedDelegate
    @param nIdx Current selected button index
]]
SelfTabBarHelper.OnSelectedChangedDelegate = nil
SelfTabBarHelper.tbButtonList = nil
SelfTabBarHelper.nDefaultIdx = DEFAULT_SELECTED_IDX
SelfTabBarHelper.nSelectedIdx = DEFAULT_SELECTED_IDX
SelfTabBarHelper.OwnerWnd = nil

local function ChangeButtonState(self, nSelectedIdx)
    if nSelectedIdx > #self.tbButtonList then
        return false
    end

    -- Changed Style
    local nCount = #self.tbButtonList
    for i = 1,nCount do
        if nSelectedIdx ~= i then
            self.tbButtonList[i]:OnUnselected()
        else
            self.nSelectedIdx = nSelectedIdx
            self.tbButtonList[self.nSelectedIdx]:OnSelected()
        end
    end
    return true
end

local function OnButtonSelected( self, nSelectedIdx )
    if ChangeButtonState(self, nSelectedIdx) then
        -- Fire Changed Event
        self.OnSelectedChangedDelegate:Fire(self.nSelectedIdx)
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SELECT_TAB, self.OwnerWnd.tbTemplate.szWndName, self.nSelectedIdx)
    end
end

function SelfTabBarHelper:Init(Owner, pTabBarRef, nDefaultIdx)
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfTabBarHelper init faild, owner is nil')
        return
    end
    if pTabBarRef == nil then
        logerror('[UI] SelfTabBarHelper init faild, tab bar refrence is nil')
        return
    end

    -- Init basic variable
    self.OnSelectedChangedDelegate = LuaDelegate()
    self.tbButtonList = {}
    self.OwnerWnd = Owner.PrefabHelper.Owner

    -- Init tab button prefab
    local nCount = pTabBarRef:GetChildrenCount()
    for i = 1,nCount do
        local pTabButton = pTabBarRef:GetChildAt(i - 1)
        local TabButton = Owner.PrefabHelper:BindPrefab(pTabButton)
        TabButton:Init(i)
        TabButton.OnClickedDelegated:Bind(function() OnButtonSelected(self, i) end)
        self.tbButtonList[i] = TabButton
    end

    -- select default button
    if (nDefaultIdx ~= nil) and (nDefaultIdx <= nCount) then
        self.nDefaultIdx = nDefaultIdx
    end
    ChangeButtonState(self, self.nDefaultIdx)
end

function SelfTabBarHelper:Uninit()
    UninitCheckSystem:Unregister(self)
    if self.tbButtonList then
        for i,v in ipairs(self.tbButtonList) do
            if v then
                v.OnClickedDelegated:UnbindAll()
            end
        end
    end
    self.tbButtonList = nil
end

function SelfTabBarHelper:Reset()
    ChangeButtonState(self, self.nDefaultIdx)
    OnButtonSelected(self, self.nDefaultIdx)
end

function SelfTabBarHelper:GetCurrentIdx()
    return self.nSelectedIdx
end

function SelfTabBarHelper:SetTabText(nIndex,szText)
    local TabButton = self.tbButtonList[nIndex]
    if(TabButton == nil)then
        return
    end
    TabButton:SetResourceText(szText)
end

function SelfTabBarHelper:SelectByIndex(nIndex, bWithEvent)
    if bWithEvent then
        OnButtonSelected(self, nIndex)
    else
        ChangeButtonState(self, nIndex)
    end
end

function SelfTabBarHelper:SetIsEnabledByIndex(nIndex, bIsEnabled)
    local TabButton = self.tbButtonList[nIndex]
    if(TabButton == nil)then
        return
    end
    TabButton:SetIsEnabled(bIsEnabled)
end

function SelfTabBarHelper:SetVisibilityByIndex(nIndex, eVisibility)
    local TabButton = self.tbButtonList[nIndex]
    if(TabButton == nil)then
        return
    end
    TabButton:SetVisibility(eVisibility)
end

function SelfTabBarHelper:UnselectAll()
    self:SelectByIndex(-1)
end

--@DEPRECATED
function SelfTabBarHelper:SetRedDot(bShow, nTabIndex)
    local TabButton = self.tbButtonList[nTabIndex]
    if TabButton == nil then
        logwarning("SelfTabBarHelper:SetRedDot, tabbutton is not found, TabIndex="..tostring(nTabIndex))
        return
    end
    TabButton:SetRedDot(bShow)
end

function SelfTabBarHelper:SetTipIconVisible(nIndex, bVisible)
    local TabButton = self.tbButtonList[nIndex]
    if TabButton == nil then
        logerror("SelfTabBarHelper:SetTipIconVisible, TabButton is not found, Index="..nIndex)
        return
    end
    TabButton:SetTipIconVisible(bVisible)
end

function SelfTabBarHelper:SetTipCount(nIndex, nCount)
    local TabButton = self.tbButtonList[nIndex]
    if TabButton == nil then
        logerror("SelfTabBarHelper:SetTipCount, TabButton is not found, Index="..nIndex)
        return
    end
    TabButton:SetTipCount(nCount)
end

function SelfTabBarHelper:GetButtonCount()
    return #self.tbButtonList
end

return SelfTabBarHelper
