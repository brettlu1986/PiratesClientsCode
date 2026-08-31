local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSailorBag = luaclass("UPSailorBag", PrefabBase)

local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local DEFAULT_SELECTED_GRADE = 1
local MAX_FILTER_GRADE = 5

UPSailorBag.nSelectedGrade = DEFAULT_SELECTED_GRADE

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function RefreshList(self)
    local tbDatas = GetSailorComponent():GetSailorListByGrade(self.nSelectedGrade - 1)
    self.tbListHelper:SetData(tbDatas)
end

local function OnFilterCheckStateChanged(self, nGrade)
    for i = 1, MAX_FILTER_GRADE do
        self.pWidgetRef["chkFilter_"..i]:SetIsChecked(i == nGrade)
    end
    self.nSelectedGrade = nGrade
    RefreshList(self)
end

local function ShowUpgradeDialog(self, nSailorId)
    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("SAILOR_UPGRADE_DIALOG_TITLE"))
    local pbSailorUpLevelSingle = self.PrefabHelper:CreatePrefab(UIDef.UP_SAILOR_UP_LEVEL_SINGLE)
    pbSailorUpLevelSingle:SetSailorId(nSailorId)
    pbSailorUpLevelSingle:SetDialogFrame(Dialog)
    Dialog:SetView(pbSailorUpLevelSingle.pWidgetRef)
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

local function OnBagItemSelectedChanged(self, nIndex)
    local tbSailorData = self.tbListHelper:GetSelectedData()
    local nCount = tbSailorData.nCount
    local nSailorId = tbSailorData.nSailorId
    if nCount > 0 then
        ShowUpgradeDialog(self, tbSailorData.nSailorId)
    else
        local bHighGrade = false
        nSailorId, bHighGrade = GetSailorComponent():GetOtherSameSailorId(nSailorId)
        local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_BAG_TIPS_TITLE")
        local l10nMessage = bHighGrade and UISetUtils.GetL10NTextByKey("SAILOR_HIGH_GRADE_TIPS") or UISetUtils.GetL10NTextByKey("SAILOR_LOW_GRADE_TIPS")
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
            ShowUpgradeDialog(self, nSailorId)
        end)
    end
end

function UPSailorBag:OnLoad()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.listSailor)
    self.tbListHelper:SetAutoScrollEnabled(false)
end

function UPSailorBag:OnUnload()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UPSailorBag:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    for i=1, MAX_FILTER_GRADE do
        EventHelper:RegisterCppDelegateFunc(pWidgetRef["chkFilter_"..i].OnCheckStateChanged, function() OnFilterCheckStateChanged(self, i) end)
    end
    EventHelper:RegisterLuaDelegate(self.tbListHelper.OnSelectedChangedDelegate, OnBagItemSelectedChanged, self)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT, self, RefreshList)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, RefreshList)
end

function UPSailorBag:Activate()
    OnFilterCheckStateChanged(self, DEFAULT_SELECTED_GRADE)
end

return UPSailorBag