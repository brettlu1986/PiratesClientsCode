-----------------------------------------------------
--File Name    : UPCommonViewButton.lua
--Author       : Edward J
--Create Time  : 2018-03-13
--Description  : UPCommonViewButton
-----------------------------------------------------
local luaclass               = require("luaclass")
local UPCommonViewButtonBase = require("UPCommonViewButtonBase")
local UPCommonViewButton     = luaclass("UPCommonViewButton", UPCommonViewButtonBase)

local UISetUtils             = require("UISetUtils")
-----------------------------------------------------
local Visible             = ESlateVisibility.Visible
local Collapsed           = ESlateVisibility.Collapsed

UPCommonViewButton.szName = ""
UPCommonViewButton.pIcon  = nil
UPCommonViewButton.pFunc  = nil
-----------------------------------------------------

local function Init(self, tbBtnsArg)
    local tbtempArg = self.tbBtnsArg
    local szName = (tbtempArg.szName == nil) and "" or tbtempArg.szName
    local pIcon = tbtempArg.pIcon
    local pFunc = tbtempArg.pFunc
    self.szName = szName
    self:SetFunc(pFunc)
    self:SetText(szName) 
    self:SetIcon(pIcon)
end

function UPCommonViewButton:SetText(szName)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        log("[UI] UPCommonViewButton SetText pWidgetRef is nil!")
        return
    end
    pWidgetRef.TxtName:SetText(szName)
end

function UPCommonViewButton:SetIcon(pIcon)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        log("[UI] UPCommonViewButton SetIcon pWidgetRef is nil!")
        return
    end
    local imgIcon = pWidgetRef.imgIcon
    if (pIcon ~= nil) then
        UISetUtils.SetImageBrushRes(imgIcon, pIcon)
        imgIcon:SetVisibility(Visible)
        pIcon = pIcon
    else
        imgIcon:SetVisibility(Collapsed)
    end
end

function UPCommonViewButton:SetFunc(pFunc)
    self.pFunc = pFunc
end

function UPCommonViewButton:SetVisible(bIsVisible)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        log("[UI] UPCommonViewButton SetVisible pWidgetRef is nil!")
        return
    end
    pWidgetRef:SetVisibility(bIsVisible and Visible or Collapsed)
end

function UPCommonViewButton:OnSetData(tbBtnsArg)
    self.super.OnSetData(self, tbBtnsArg)
    Init(self)
end

function UPCommonViewButton:OnLoad()
    self.super:OnLoad()
end

function UPCommonViewButton:OnShow()
end

function UPCommonViewButton:OnHide() 
end

local function OnButtonClick(self)
    local btnFunc = self.pFunc
    if (btnFunc ~= nil) then
        btnFunc()
    end
    local pCloseFunc = self.tbBtnsArg.CloseFunc
    if (pCloseFunc ~= nil) then
        pCloseFunc()
    end
end

function UPCommonViewButton:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.kmbtnUse.OnClicked, self, OnButtonClick)
end

return UPCommonViewButton
