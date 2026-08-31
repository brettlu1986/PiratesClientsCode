-----------------------------------------------------
--File Name    : ULAppearanceSelector.lua
--Author       : WuJizhou
--Create Time  : 4/22/2020, 4:31:31 PM
--Description  : ULAppearanceSelector
-----------------------------------------------------
local luaclass                   = require("luaclass")
local UILogicBase                = require("UILogicBase")
local ULAppearanceSelector       = luaclass("ULAppearanceSelector", UILogicBase)

local DefaultAppearanceDataTable = require("DefaultAppearanceDataTable")


ULAppearanceSelector.nSlotType  = nil
ULAppearanceSelector.szWidgetName  = nil
ULAppearanceSelector.szPrefabKey  = nil
ULAppearanceSelector.nGender  = nil
ULAppearanceSelector.pbItemScripts = nil
ULAppearanceSelector.nSelectIdx = nil
ULAppearanceSelector.tbDatas = nil


local function GetListDatas(self)
    local nSlotType = self.nSlotType
    local nGender = self.nGender
    local tbCandidateIds = DefaultAppearanceDataTable:GetIdsByType(nSlotType, self.nGender)
    local tbResult = {}
    for _, nId in ipairs(tbCandidateIds) do
        table.insert(tbResult, {nId = nId, nGender = nGender})
    end
    return tbResult
end


local function CreatePrefabItemInternal(self)
    local pbItemScripts = self.pbItemScripts
    local nIdx = #pbItemScripts
    local pbScript, _ = self.PrefabHelper:CreatePrefab(self.szPrefabKey)
    pbScript:SetParentContainer(self)
    pbScript:SetIndex(nIdx + 1)
    self.pWidgetRef[self.szWidgetName]:AddChildToWrapBox(pbScript.pWidgetRef)
    pbScript.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    table.insert(pbItemScripts, pbScript)
end

local function ActivatePrefabItemByDatas(self, tbDatas)
    self.nSelectIdx = nil
    self.tbDatas = tbDatas
    local nCount = #tbDatas
    local pbItemScripts = self.pbItemScripts
    local nCurrentCount = #pbItemScripts
    if nCurrentCount < nCount then
        local nCountToCreate = nCount - nCurrentCount
        for nIdx = 1, nCountToCreate do
            CreatePrefabItemInternal(self)
        end
    end
    nCurrentCount = #pbItemScripts
    for nIdx = 1, nCurrentCount do
        local pWidgetRef = pbItemScripts[nIdx].pWidgetRef
        if nIdx <= nCount then
            pWidgetRef:SetVisibility(ESlateVisibility.Visible)
            pbItemScripts[nIdx]:OnRefresh(tbDatas[nIdx])
        else
            pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    self:SetSelectedIndex(1)
end

local function PreCreatePrefabItems(self, nCount)
    for nIdx = 1, nCount do
        CreatePrefabItemInternal(self)
    end
end


function ULAppearanceSelector:SetSelectedIndex(nIdx)
    local nLastSelectIdx = self.nSelectIdx
    self.nSelectIdx = nIdx
    if nLastSelectIdx and self.pbItemScripts[nLastSelectIdx] then
        self.pbItemScripts[nLastSelectIdx]:OnRefresh(self.tbDatas[nLastSelectIdx])
    end
    self.pbItemScripts[nIdx]:OnRefresh(self.tbDatas[nIdx])
end

function ULAppearanceSelector:GetSelectIndex()
    return self.nSelectIdx
end



function ULAppearanceSelector:OnGenderChanged(nNewGender)
    self.nGender = nNewGender
    local tbDatas = GetListDatas(self)
    ActivatePrefabItemByDatas(self, tbDatas)
end

function ULAppearanceSelector:Init(nSlotType, szListItemPrefabKey, szWidgetName, nGender)
    self.nSlotType = nSlotType
    self.szPrefabKey = szListItemPrefabKey
    self.szWidgetName = szWidgetName
    self.nGender =  nGender
end




----------life cycle----------
-- function ULAppearanceSelector:OnCreate()
-- end

-- function ULAppearanceSelector:OnDestroy()
-- end

function ULAppearanceSelector:OnLoad()
    self.pbItemScripts = {}
    PreCreatePrefabItems(self, 5)
    -- self:OnGenderChanged(GenderTypeDef.FEMALE)
end

function ULAppearanceSelector:OnUnload()
    self.pbItemScripts = nil
end

-- function ULAppearanceSelector:OnEnter()
-- end

-- function ULAppearanceSelector:OnShow()
-- end

-- function ULAppearanceSelector:OnHide()
-- end

-- function ULAppearanceSelector:OnExit()
-- end

-- function ULAppearanceSelector:OnBindEvent(EventHelper)
-- end

-- function ULAppearanceSelector:OnUnbindEvent(EventHelper)
-- end

return ULAppearanceSelector