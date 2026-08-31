local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingCameraSub = luaclass("UPSettingCameraSub", PrefabBase)

UPSettingCameraSub.tbParent = nil
UPSettingCameraSub.nKey = nil
UPSettingCameraSub.nCurValue = nil

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local nRate = self.nCurValue / 100
    pWidgetRef.sdValue:SetValue(nRate)
    pWidgetRef.proValue:SetPercent(nRate)
    pWidgetRef.txtValue:SetText(string.format("%d", self.nCurValue))
end

local function OnClickedReduce(self)
    if self.nCurValue - 1 < 0 then
        return
    end
    self.tbParent:SetSubValue(self, self.nKey, self.nCurValue - 1)
end

local function OnClickedAdd(self)
    if self.nCurValue + 1 > 100 then
        return
    end
    self.tbParent:SetSubValue(self, self.nKey, self.nCurValue + 1)
end

local function OnValueChanged(self, nValue)
    local nCurValue = nValue * 100
    nCurValue = math.floor( nCurValue )
    self.tbParent:SetSubValue(self, self.nKey, nCurValue)
end

function UPSettingCameraSub:OnLoad()

end

function UPSettingCameraSub:OnShow()
end

function UPSettingCameraSub:OnCreate()
end

function UPSettingCameraSub:OnDestroy()
end

function UPSettingCameraSub:InitUI(tbParent, nKey, szName)
    self.tbParent = tbParent
    self.nKey = nKey
    self.pWidgetRef.txtName:SetText(szName)
end

function UPSettingCameraSub:OnRefresh(nCurValue)
    self.nCurValue = nCurValue

    RefreshUI(self)
end

function UPSettingCameraSub:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReduce.OnClicked, self, OnClickedReduce)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.sdValue.OnValueChanged, self, OnValueChanged)
end

function UPSettingCameraSub:Activate()

end

return UPSettingCameraSub