-----------------------------------------------------
--File Name    : UPBtnImgGrid.lua
--Author       : WuJizhou
--Create Time  : 9/20/2018, 3:57:37 PM
--Description  : UPBtnImgGrid
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPBtnImgGrid = luaclass("UPBtnImgGrid", PrefabBase)
local UISetUtils = require("UISetUtils")

UPBtnImgGrid.bSelected = false

local function OnClicked(self)
    if self.fnBtnOnClicked ~= nil then
        self.tbBtnOnClickedParams.bSelected = self.bSelected -- 返回的是点击前的状态
        self.fnBtnOnClicked(self.tbBtnOnClickedParams)
    end
end

function UPBtnImgGrid:SetSelected(bSelected)
    self.bSelected = bSelected
    local pWidgetRef = self.pWidgetRef
    if bSelected then
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    end

end

function UPBtnImgGrid:ShowContent(szImgRes, szColorGradeImg, fnBtnOnClicked, tbBtnOnClickedParams, nCount)
    self.EventHelper:UnregisterAll()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, szImgRes:load())

    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    self.fnBtnOnClicked = fnBtnOnClicked
    self.tbBtnOnClickedParams = tbBtnOnClickedParams
    self.EventHelper:RegisterCppDelegate(pWidgetRef.btnItem.OnClicked, self, OnClicked)
    self:SetSelected(false)
    local szCount
    if nCount == nil or nCount == 0 then
        szCount = ""
    else
        szCount = tostring(nCount)
    end
    pWidgetRef.txtCount:SetText(szCount)
end

function UPBtnImgGrid:HideContent()
    self.EventHelper:UnregisterAll()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

----------life cycle----------
-- function UPBtnImgGrid:OnCreate()
-- end

-- function UPBtnImgGrid:OnDestroy()
-- end

-- function UPBtnImgGrid:OnLoad()
-- end

-- function UPBtnImgGrid:OnUnload()
-- end

-- function UPBtnImgGrid:OnEnter()
-- end

-- function UPBtnImgGrid:OnShow()
-- end

-- function UPBtnImgGrid:OnHide()
-- end

-- function UPBtnImgGrid:OnExit()
-- end

-- function UPBtnImgGrid:OnBindEvent( EventHelper )
-- end

-- function UPBtnImgGrid:OnUnbindEvent( EventHelper )
-- end

return UPBtnImgGrid