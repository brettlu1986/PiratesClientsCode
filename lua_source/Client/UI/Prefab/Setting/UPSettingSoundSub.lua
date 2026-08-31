local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingSoundSub = luaclass("UPSettingSoundSub", PrefabBase)
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local SettingSystemNew = require("SettingSystemNew")

local CHECKED, UNCHECKED, UNDETERMINED = ECheckBoxState.Checked, ECheckBoxState.Unchecked, ECheckBoxState.Undetermined
UPSettingSoundSub.nKey = nil
UPSettingSoundSub.bActivate = nil
UPSettingSoundSub.tbParent = nil

local function OnClickedSound(self, bActivate)
    if not self.bActivate then
        self.pWidgetRef.cbSound:SetCheckedState(UNDETERMINED)
        UIUtils.ShowToast(UITextDef.IN_DEVELOPMENT)
        return
    end

    self.tbParent.tbInstance:SetActivate(self.nKey, bActivate)
    self:RefreshUI()
end

local function OnSoundValueChanged(self, nValue)
    if not self.bActivate then
        UIUtils.ShowToast(UITextDef.IN_DEVELOPMENT)
        return
    end

    self.tbParent.tbInstance:Set(self.nKey, nValue)
    self:RefreshUI()
end

local function OnMouseCaptureEnd(self)
    if not self.bActivate then
        UIUtils.ShowToast(UITextDef.IN_DEVELOPMENT)
        return
    end

    -- local nCurValue = self.tbParent.tbInstance:Get(self.nKey)
    -- self.tbParent.tbInstance:Set(self.nKey, nCurValue)
    SettingSystemNew:SaveLocalData()
    self:RefreshUI()
end

local function OnClickedReduce(self)
    local nCurValue = self.tbParent.tbInstance:Get(self.nKey)   
    if nCurValue > 0 then
        self.tbParent.tbInstance:Set(self.nKey, nCurValue - 0.1)
        self:RefreshUI()
    end
end

local function OnClickedAdd(self)
    local nCurValue = self.tbParent.tbInstance:Get(self.nKey)   
    if nCurValue < 1 then
        self.tbParent.tbInstance:Set(self.nKey, nCurValue + 0.1)
        self:RefreshUI()
    end
end

function UPSettingSoundSub:OnLoad()
end

function UPSettingSoundSub:OnShow()
end

function UPSettingSoundSub:OnDestroy()
    self.nKey = nil
    self.bActivate = nil
    self.tbParent = nil
end

function UPSettingSoundSub:InitUI(tbParent, tbData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtTitle:SetText(tbData.szTitle)
    self.nKey = tbData.nKey
    self.bActivate = tbData.bActivate
    self.tbParent = tbParent
end

function UPSettingSoundSub:RefreshUI()
    local pWidgetRef = self.pWidgetRef
    if self.bActivate then
        local nCurValue = self.tbParent.tbInstance:Get(self.nKey)   
        local bCurActivate = self.tbParent.tbInstance:GetActivate(self.nKey) 
        pWidgetRef.cbSound:SetCheckedState(bCurActivate and CHECKED or UNCHECKED)
        pWidgetRef.slSound:SetValue(nCurValue)
        pWidgetRef.proSound:SetPercent(nCurValue)
    else
        pWidgetRef.cbSound:SetCheckedState(UNDETERMINED)
        pWidgetRef.slSound:SetValue(0)
        pWidgetRef.proSound:SetPercent(0)
    end
end

function UPSettingSoundSub:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.slSound.OnValueChanged, self, OnSoundValueChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.slSound.OnMouseCaptureEnd, self, OnMouseCaptureEnd)
    EventHelper:RegisterCppDelegate(pWidgetRef.cbSound.OnCheckStateChanged,  self, OnClickedSound)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReduce.OnClicked, self, OnClickedReduce)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedAdd)
end

function UPSettingSoundSub:Activate()
end

return UPSettingSoundSub