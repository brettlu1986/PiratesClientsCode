-----------------------------------------------------
--File Name    : UPPackageDiscardPart.lua
--Author       : WuJizhou
--Create Time  : 9/14/2018, 8:11:36 PM
--Description  : UPPackageDiscardPart
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPPackageDiscardPart = luaclass("UPPackageDiscardPart", PrefabBase)
local BattleItemSystemClient = require("BattleItemSystemClient")
local ClientEventDef = require("ClientEventDef")

UPPackageDiscardPart.nCurCount = 0
UPPackageDiscardPart.nTotalCount = 0
UPPackageDiscardPart.nItemInstanceId = nil

local function RefreshInternal(self)
    local pWidgetRef = self.pWidgetRef
    local nValue = self.nCurCount / self.nTotalCount
    pWidgetRef.sldrController:SetValue(nValue)
    pWidgetRef.pgbContoller:SetPercent(nValue)
    pWidgetRef.txtCount:SetText(string.format("%s/%s", tostring(self.nCurCount), tostring(self.nTotalCount)))
end

local function AddCount(self)
    local nCurCount = self.nCurCount
    if nCurCount >= self.nTotalCount then
        return
    end
    self.nCurCount = nCurCount + 1

    RefreshInternal(self)
end

local function SubCount(self)
    local nCurCount = self.nCurCount
    if nCurCount <= 0 then
        return
    end
    self.nCurCount = self.nCurCount - 1
    RefreshInternal(self)
end

local function OnSlided(self, value)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbContoller:SetPercent(value)
    self.nCurCount = math.floor(self.nTotalCount * value)
    pWidgetRef.txtCount:SetText(string.format("%s/%s", tostring(self.nCurCount), tostring(self.nTotalCount)))
end

local function Cancel(self)
    self:HideView()
end

local function Discard(self)
    if self.nCurCount > 0 then
        BattleItemSystemClient:RequestThrowAwayItem(self.nItemInstanceId, self.nCurCount)
        self.EventHelper:FireEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM)
    end
    self:HideView()
end

--------public function--------
function UPPackageDiscardPart:ShowView(tbItem)
    self.nItemInstanceId = tbItem:GetInstanceId()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.nTotalCount = tbItem:GetStackCount()
    self.nCurCount = math.floor(self.nTotalCount / 2)
    RefreshInternal(self)
end

function UPPackageDiscardPart:HideView()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Hidden)
end


----------life cycle----------
-- function UPPackageDiscardPart:OnCreate()
-- end

-- function UPPackageDiscardPart:OnDestroy()
-- end

-- function UPPackageDiscardPart:OnLoad()

-- end

-- function UPPackageDiscardPart:OnUnload()
-- end

-- function UPPackageDiscardPart:OnEnter()
-- end

-- function UPPackageDiscardPart:OnShow()
-- end

-- function UPPackageDiscardPart:OnHide()
-- end

-- function UPPackageDiscardPart:OnExit()
-- end

function UPPackageDiscardPart:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDone.OnClicked, self, Discard)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, Cancel)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUp.OnClicked, self, AddCount)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDown.OnClicked, self, SubCount)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrController.OnValueChanged, self, OnSlided)
    EventHelper:RegisterEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM, self, self.HideView)

end

-- function UPPackageDiscardPart:OnUnbindEvent( EventHelper )
-- end

return UPPackageDiscardPart