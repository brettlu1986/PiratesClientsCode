-----------------------------------------------------
--File Name    : SelfCheckBoxGroupHelper.lua
--Author       : Ran Jie
--Create Time  : 2020-04-14
--Description  : SelfCheckBoxGroupHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfCheckBoxGroupHelper = luaclass("SelfCheckBoxGroupHelper")

local LuaDelegate = require("LuaDelegate")
local CppDelegate = require("CppDelegate")
local UninitCheckSystem = require("UninitCheckSystem")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

local DEFAULT_SELECTED_IDX = 1

--[[
    OnSelectedChangedDelegate
    @param nIdx Current selected button index
]]
SelfCheckBoxGroupHelper.OnSelectedChangedDelegate = nil
SelfCheckBoxGroupHelper.tbCheckBoxList = nil
SelfCheckBoxGroupHelper.tbCheckStateDelegate = nil
SelfCheckBoxGroupHelper.nDefaultIdx = DEFAULT_SELECTED_IDX
SelfCheckBoxGroupHelper.nSelectedIdx = nil
SelfCheckBoxGroupHelper.OwnerWnd = nil

local function ChangeCheckBoxState(self, nSelectedIdx)
    if nSelectedIdx > #self.tbCheckBoxList then
        return false
    end
    -- Changed Style
    local nCount = #self.tbCheckBoxList
    for i = 1,nCount do
        if nSelectedIdx ~= i then
            self.tbCheckBoxList[i]:SetIsChecked(false)
            --if self.tbCheckBoxList[i]:IsVisible() then
                self.tbCheckBoxList[i]:SetVisibility(ESlateVisibility_Visible)
            --end
        else
            --self.nSelectedIdx = nSelectedIdx
            self.tbCheckBoxList[i]:SetIsChecked(true)
            self.tbCheckBoxList[i]:SetVisibility(ESlateVisibility_HitTestInvisible)
        end
    end
    self.nSelectedIdx = nSelectedIdx
    return true
end

local function OnCheckStateChanged(self, nIndex, bIsChecked)
    if bIsChecked then
        if ChangeCheckBoxState(self, nIndex) then
            -- Fire Changed Event
            self.OnSelectedChangedDelegate:Fire(self.nSelectedIdx)
        end
    end
end

local function ClearDelegate(self)
    if self.tbCheckStateDelegate then
        for k, v in pairs(self.tbCheckStateDelegate) do
            v:Unbind()
        end
        self.tbCheckStateDelegate = nil
    end
end

function SelfCheckBoxGroupHelper:Init(Owner, pGroupParent, nDefaultIdx)
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfCheckBoxGroupHelper init faild, owner is nil')
        return
    end
    if pGroupParent == nil then
        logerror('[UI] SelfCheckBoxGroupHelper init faild, tab bar refrence is nil')
        return
    end

    -- Init basic variable
    self.OnSelectedChangedDelegate = LuaDelegate()
    self.tbCheckBoxList = {}
    ClearDelegate(self)
    self.tbCheckStateDelegate = {}
    self.OwnerWnd = Owner.PrefabHelper.Owner
    -- Init tab button prefab
    local nCount = pGroupParent:GetChildrenCount()
    for i = 1, nCount do
        local pCheckBox = pGroupParent:GetChildAt(i - 1)
        self.tbCheckStateDelegate[i] = CppDelegate:Bind(pCheckBox.OnCheckStateChanged, function(bIsChecked) OnCheckStateChanged(self, i, bIsChecked) end)
        self.tbCheckBoxList[i] = pCheckBox
    end

    -- select default button
    if (nDefaultIdx ~= nil) and (nDefaultIdx <= nCount) then
        self.nDefaultIdx = nDefaultIdx
    end
end

function SelfCheckBoxGroupHelper:Uninit()
    UninitCheckSystem:Unregister(self)
    ClearDelegate(self)
    self.tbCheckBoxList = nil
end

function SelfCheckBoxGroupHelper:Reset()
    ChangeCheckBoxState(self, self.nDefaultIdx)
end

function SelfCheckBoxGroupHelper:GetCurrentIdx()
    return self.nSelectedIdx
end

function SelfCheckBoxGroupHelper:SetCheckBoxText(nIndex, szText)
    local pCheckBox = self.tbCheckBoxList[nIndex]
    if(pCheckBox == nil)then
        return
    end
    local pTextWidget = pCheckBox:GetContent()
    if pTextWidget then
        pTextWidget:SetText(szText)
    end
end

function SelfCheckBoxGroupHelper:SelectByIndex(nIndex, bWithEvent)
    -- if self.nSelectedIdx == nIndex then
    --     return
    -- end
    if bWithEvent then
        OnCheckStateChanged(self, nIndex, true)
    else
        ChangeCheckBoxState(self, nIndex)
    end
end

function SelfCheckBoxGroupHelper:SetIsEnabledByIndex(nIndex, bIsEnabled)
    local pCheckBox = self.tbCheckBoxList[nIndex]
    if(pCheckBox == nil)then
        return
    end
    pCheckBox:SetIsEnabled(bIsEnabled)
    local pTextWidget = pCheckBox:GetContent()
    if pTextWidget then
        if bIsEnabled then
            UISetUtils.SetTextblockColor(pTextWidget, UIResourceDef.COLOR.WHITE)
        else
            UISetUtils.SetTextblockColor(pTextWidget, UIResourceDef.COLOR.GREY)
        end
    end
    
end

function SelfCheckBoxGroupHelper:SetVisibilityByIndex(nIndex, eVisibility)
    local pCheckBox = self.tbCheckBoxList[nIndex]
    if(pCheckBox == nil)then
        return
    end
    pCheckBox:SetVisibility(eVisibility)
end

function SelfCheckBoxGroupHelper:UnselectAll()
    self:SelectByIndex(-1)
end

function SelfCheckBoxGroupHelper:SetRedDot(bShow, nIndex)
    local pCheckBox = self.tbCheckBoxList[nIndex]
    if pCheckBox == nil then
        logwarning("SelfCheckBoxGroupHelper:SetRedDot, tabbutton is not found, TabIndex="..tostring(nIndex))
        return
    end
    pCheckBox:HideTipIcon(not bShow)
end



function SelfCheckBoxGroupHelper:GetButtonCount()
    return #self.tbCheckBoxList
end

return SelfCheckBoxGroupHelper
