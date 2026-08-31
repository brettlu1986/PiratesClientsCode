local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingChat = luaclass("UPSettingChat", PrefabBase)
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local UISetUtils = require("UISetUtils")
local SelfVerticalListHelper= require("SelfVerticalListHelper")
local QuickChatDataTable = require("QuickChatDataTable")
local SettingIni = require("SettingIni")
local UIUtils = require("UIUtils")
local L10N = require("L10N")

local DEFAULT_SELECT_TYPE = 1

local BLANK_MSG = UISetUtils.GetTextByKey("UISETTING_CHAT_BLANK")
local QUICK_MAX_COUNT = SettingIni.tbChat.nMaxCount

UPSettingChat.tbInstance  = nil
UPSettingChat.tbQuickListHelper = nil
UPSettingChat.tbLibListHelper   = nil
UPSettingChat.pbChatType  = nil
UPSettingChat.tbQuickList = nil 
UPSettingChat.nSelectChatType = nil

UPSettingChat.bOpering    = nil
UPSettingChat.tbToRemove  = nil

local function CheckInToRemove(self, nIndex)
    if not self.bOpering then
        return false, false
    end
    local nToRemoveCount = #self.tbToRemove
    for i, v in ipairs(self.tbToRemove) do
        if v == nIndex then
            return true, nIndex == self.tbToRemove[nToRemoveCount]
        end
    end
    return false, false   
end

local function RefreshQuickList(self)
    local tbQuickList = self.tbQuickList

    local tbDatas = {}
    for i, v in ipairs(tbQuickList) do
        local _, bCurRemove = CheckInToRemove(self, i)
        
        local szMsg
        if v.nId > 0 then
            local tbChatData = QuickChatDataTable:GetTemplate(v.nId)
            szMsg = L10N:ToString(tbChatData.l10nMsg)
        end
        if not szMsg and bCurRemove then
            szMsg = BLANK_MSG
        end
        table.insert(tbDatas, {tbParent = self, nId = v.nId, bOpering = self.bOpering, szMsg = szMsg})
    end    
    self.tbQuickListHelper:SetData(tbDatas)
end

local function RefreshLibList(self)
    local tbQuickList = self.tbQuickList
    local tbQuickDatas = QuickChatDataTable:GetAll()

    local fnInQuickList = function(nId)
        for i, v in ipairs(tbQuickList) do
            if v.nId == nId then
                return true
            end
        end
        return false
    end

    local nSelectChatType = self.nSelectChatType
    local tbDatas = {}
    local bShowOper = self.bOpering and #self.tbToRemove > 0
    for k, v in pairs(tbQuickDatas) do
        if v.nCategory == nSelectChatType then
            table.insert(tbDatas, {tbParent = self, bShowOper = bShowOper, tbQuickData = v, bInQuickList = fnInQuickList(v.nId)})
        end
    end    
    self.tbLibListHelper:SetData(tbDatas)
end

local function OnSelectChatType(self, nNewChatType)
    if self.nSelectChatType ~= nil then
        local pbOldSelectType = self.pbChatType[self.nSelectChatType] 
        pbOldSelectType:OnUnselected()
    end
    self.pbChatType[nNewChatType]:OnSelected()
    self.nSelectChatType = nNewChatType

    RefreshLibList(self, nNewChatType)
    self.pWidgetRef.kmLibList:ScrollToTop(false)
end

local function SetQuickList(self)
    local tbList = self.tbInstance:GetValues()
    local tbQuickList = {}
    for i, v in ipairs(tbList) do
        table.insert(tbQuickList, {nId = v})
    end
    self.tbQuickList = tbQuickList
end

local function ResetQuickList(self)
    self.tbInstance:Reset()
    SetQuickList(self)
end

local function ClearQuickList(self)
    for i, v in ipairs(self.tbQuickList) do
        v.nId = 0
    end
end

local function RemoveQuickList(self, nIndex)
    if nIndex <= 0 or nIndex > #self.tbQuickList then
        logerror("UPSettingChat remove, invalid index ", nIndex)
        return
    end

    table.insert(self.tbToRemove, nIndex)
    
    self.tbQuickList[nIndex] = {tbParent = self, nId = 0, bOpering = self.bOpering, szMsg = BLANK_MSG}
end

local function AddQuickList(self, tbQuickData)
    local nIndex = self.tbToRemove[#self.tbToRemove]
    if not nIndex then
        return
    end 
    if nIndex <= 0 or nIndex > #self.tbQuickList then
        logerror("UPSettingChat add, invalid index ", nIndex)
        return
    end
    table.remove(self.tbToRemove, #self.tbToRemove)
    self.tbQuickList[nIndex] = {tbParent = self, nId = tbQuickData.nId, bOpering = self.bOpering, szMsg = L10N:ToString(tbQuickData.l10nMsg)}
end

local function RefreshQuickCount(self)
    local fnGetCurQuickCount = function()
        local nCount = 0
        for i, v in ipairs(self.tbQuickList) do
            if v.nId > 0 then
                nCount = nCount + 1
            end
        end
        return nCount
    end
    self.pWidgetRef.txtCount:SetText(string.format("%d/%d", fnGetCurQuickCount(), QUICK_MAX_COUNT))
end

local function RefreshUI(self)
    RefreshQuickList(self)
    OnSelectChatType(self, self.nSelectChatType)
    RefreshQuickCount(self)
    
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    pWidgetRef.btnCancel:SetVisibility(self.bOpering and Visible or Collapsed)
    pWidgetRef.txtChange:SetText(self.bOpering and UISetUtils.GetL10NTextByKey("UPMAINPLAYERINFO_CONFIRM_BUTTON_DESC")
        or UISetUtils.GetL10NTextByKey("UISETTING_CHAT_CHANGE"))
    pWidgetRef.btnAllRemove:SetVisibility(self.bOpering and Visible or Collapsed)
end

local function SetOpering(self, bValue)
    self.bOpering = bValue
    self.tbToRemove = {}
    for i = #self.tbQuickList, 1, -1 do
        if self.tbQuickList[i].nId <= 0 then
            table.insert(self.tbToRemove, i)
        end
    end
    RefreshUI(self)
end

local function OnClickedReset(self)
    ResetQuickList(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SETTING_CHAT_RESET_SUCCESS"))
    SetOpering(self, false)
    SettingSystemNew:SaveLocalData()
end

local function OnClickedAllRemove(self)
    ClearQuickList(self)
    SetOpering(self, self.bOpering)
end

local function OnClickedCancel(self)
    SetQuickList(self)
    SetOpering(self, false)
end

local function OnClickedChanged(self)
    if self.bOpering then
        local tbDatas = {}
        for i, v in ipairs(self.tbQuickList) do
            if v.nId > 0 then
                table.insert(tbDatas, v.nId)
            else
                table.insert(tbDatas, 0)
            end
        end
        self.tbInstance:SetValues(tbDatas)
        SetOpering(self, false)
        SettingSystemNew:SaveLocalData()
    else
    -- 
        SetOpering(self, true)
    end
end

function UPSettingChat:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.tbQuickListHelper = SelfVerticalListHelper()
    self.tbQuickListHelper:Init(self, pWidgetRef.kmQuickList)
    self.tbLibListHelper = SelfVerticalListHelper()
    self.tbLibListHelper:Init(self, pWidgetRef.kmLibList)   


    local PrefabHelper = self.PrefabHelper
    local pbChatType = {}
    for i = 1, 3 do
        local pbType = PrefabHelper:BindPrefab(pWidgetRef["chk"..i])
        pbType:Init(i)
        pbType:OnUnselected()
        pbType.OnClickedDelegated:Bind(function() OnSelectChatType(self, i) end)   
        table.insert(pbChatType, pbType)
    end
    self.pbChatType = pbChatType
end

function UPSettingChat:OnCreate()
    self.tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Chat)
    self.tbInstance:LoadDefaultValue() 
end

function UPSettingChat:OnDestroy()
    self.tbQuickListHelper:Uninit()
    self.tbQuickListHelper = nil
    self.tbLibListHelper:Uninit()
    self.tbLibListHelper = nil
    self.pbChatType = nil
    self.tbToRemove = nil

    self.tbInstance = nil
end

function UPSettingChat:OnShow()
    -- SetQuickList(self)
    -- self.nSelectChatType = DEFAULT_SELECT_TYPE
    -- SetOpering(self, false)
end

function UPSettingChat:Activate()
    SetQuickList(self)
    self.nSelectChatType = DEFAULT_SELECT_TYPE
    SetOpering(self, false)
end

function UPSettingChat:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReset.OnClicked, self, OnClickedReset)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAllRemove.OnClicked, self, OnClickedAllRemove)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCancel.OnClicked, self, OnClickedCancel)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChanged.OnClicked, self, OnClickedChanged)
end

function UPSettingChat:OnRemove(nIndex)
    RemoveQuickList(self, nIndex)
    RefreshUI(self)
end

function UPSettingChat:OnAdd(tbQuickData)
    AddQuickList(self, tbQuickData)
    RefreshUI(self)
end

return UPSettingChat