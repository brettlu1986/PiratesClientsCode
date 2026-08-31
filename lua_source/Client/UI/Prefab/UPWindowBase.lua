local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPWindowBase = luaclass("UPWindowBase", PrefabBase)

local UIManager =require("UIManager")
local LuaDelegateClass = require("LuaDelegate")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

UPWindowBase.bCloseEnabled = true
UPWindowBase.bExitAnim = false
UPWindowBase.szOuterWnd = nil
UPWindowBase.OnBtnReturnClickedDelegate = nil
UPWindowBase.OnExitAnimFinishedDelegate = nil

local function OnBtnReturnClicked( self )
    if self.bCloseEnabled then
        self:PlayExitAnim()
        
    end
    if self.OnBtnReturnClickedDelegate then
        self.OnBtnReturnClickedDelegate:Fire() 
    end
end

local function OnAnimEnterFinished( self )
    if self.bExitAnim then
        if self.OnExitAnimFinishedDelegate ~= nil then
            self.OnExitAnimFinishedDelegate:Fire()
        end
        if self.szOuterWnd then
            UIManager:CloseWnd(self.szOuterWnd)
        end
    end
end

function UPWindowBase:OnCreate()
    self.OnBtnReturnClickedDelegate = LuaDelegateClass()
    self.OnExitAnimFinishedDelegate = LuaDelegateClass()
end

function UPWindowBase:OnShow()
    self:PlayEnterAnim()
end

function UPWindowBase:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animComeIn, OnAnimEnterFinished, self))
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked                , self, OnBtnReturnClicked)
end

function UPWindowBase:SetTitleData(tbTitleData)
    self:SetOuterWnd(tbTitleData.szOuterWnd)
    self:SetTitleName(tbTitleData.l10nTitleName)
end

function UPWindowBase:SetOuterWnd(szOuterWnd)
    self.szOuterWnd = szOuterWnd
end

function UPWindowBase:SetTitleName(l10nTitleName)
    self.pWidgetRef.txtTitleName:SetText(l10nTitleName)
end

function UPWindowBase:PlayEnterAnim()
    local szInfo
    if(GEnableNewLua) then
        szInfo = getdebuginfo_l()
    end
    self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Forward, 1, nil, szInfo)
    self.bExitAnim = false
end

function UPWindowBase:PlayExitAnim()
    if self.bExitAnim == false then
        local szInfo
        if(GEnableNewLua) then
            szInfo = getdebuginfo_l()
        end
        self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Reverse, 1, nil, szInfo)
        self.bExitAnim = true
    end
end

function UPWindowBase:SetCloseEnabled(bEnabled)
    self.bCloseEnabled = bEnabled
end

return UPWindowBase

