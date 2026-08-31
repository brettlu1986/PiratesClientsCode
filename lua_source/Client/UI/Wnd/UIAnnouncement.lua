-----------------------------------------------------
--File Name    : UIAnnouncement.lua
--Description  : 登录公告界面
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIAnnouncement = luaclass("UIAnnouncement", WndBase)

local LuaDelegate = require("LuaDelegate")

UIAnnouncement.tbBtnClose = nil

function UIAnnouncement:OnLoad()
    self.tbBtnClose = LuaDelegate()
end

function UIAnnouncement:OnUnload()
    if self.tbBtnClose then
        self.tbBtnClose:UnbindAll()
    end
end

function UIAnnouncement:OnShow()
    local pWidgetRef = self.pWidgetRef
    local tbOpenArgs = self.tbOpenArgs
    local szTitle = tbOpenArgs.szTitle
    if szTitle ~= nil then
        pWidgetRef.txtTitle:SetText(szTitle)
    end
    local szContent = tbOpenArgs.szContent
    if szContent ~= nil then
        pWidgetRef.txtMessage:SetText(szContent)
    end
    local nLineHeightPercentage = tbOpenArgs.nLineHeightPercentage
    if nLineHeightPercentage == nil then
        nLineHeightPercentage = 1.5
    end
    pWidgetRef.txtMessage:SetLineHeightPercentage(nLineHeightPercentage)
end

function UIAnnouncement:OnHide()
    
end

function UIAnnouncement:BindStartDelegate(Func, Obj)
    self.tbBtnClose:Bind(Func, Obj)
end

function UIAnnouncement:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked,self,self.OnClickClose)
end

function UIAnnouncement:OnClickClose()
    if self.tbBtnClose then
        self.tbBtnClose:Fire()
    end
    self:Close()
end

return UIAnnouncement
