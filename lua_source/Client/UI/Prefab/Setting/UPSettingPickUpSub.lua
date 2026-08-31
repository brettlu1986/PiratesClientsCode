local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingPickUpSub = luaclass("UPSettingPickUpSub", PrefabBase)

UPSettingPickUpSub.tbParent   = nil
UPSettingPickUpSub.nId        = nil
UPSettingPickUpSub.tbItemData = nil
UPSettingPickUpSub.nMinCount  = nil
UPSettingPickUpSub.nMaxCount  = nil
UPSettingPickUpSub.nCurCount  = nil

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local nRate = self.nCurCount / self.nMaxCount
    pWidgetRef.sdValue:SetValue(nRate)
    pWidgetRef.proValue:SetPercent(nRate)
    pWidgetRef.txtCount:SetText(self.nCurCount)
end

local function OnClickedReduce(self)
    if self.nCurCount - 1 < self.nMinCount then
        return
    end
    self.tbParent:SetValue(self, self.nId, self.nCurCount - 1)
end

local function OnClickedAdd(self)
    if self.nCurCount + 1 > self.nMaxCount then
        return
    end
    self.tbParent:SetValue(self, self.nId, self.nCurCount + 1)
end

local function OnValueChanged(self, nValue)
    local nCurValue = math.floor(nValue * self.nMaxCount)
    self.tbParent:SetValue(self, self.nId, nCurValue)
end

function UPSettingPickUpSub:OnLoad()
end

function UPSettingPickUpSub:OnShow()
end

function UPSettingPickUpSub:OnCreate()
end

function UPSettingPickUpSub:SetData(tbParent, nId, tbItemData, nMinCount, nMaxCount)
    self.tbParent = tbParent
    self.nId = nId
    self.tbItemData = tbItemData
    self.nMinCount = nMinCount
    self.nMaxCount = nMaxCount

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbItemData.l10nName)
end

function UPSettingPickUpSub:GetData()
    return self.nId, self.tbItemData.nId
end

function UPSettingPickUpSub:OnRefresh(nCurCount)
    self.nCurCount = nCurCount
    RefreshUI(self)
end

function UPSettingPickUpSub:OnDestroy()

end

function UPSettingPickUpSub:OnBindEvent(EventHelper)   
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReduce.OnClicked, self, OnClickedReduce)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.sdValue.OnValueChanged, self, OnValueChanged)
end

function UPSettingPickUpSub:Activate()
end

return UPSettingPickUpSub