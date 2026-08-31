-----------------------------------------------------
--File Name    : ULMailBoxBase.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 2:43:34 PM
--Description  : ULMailBoxBase
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULMailBoxBase = luaclass("ULMailBoxBase", UILogicBase)

local MailSystem = require("MailSystem")

ULMailBoxBase.bActivate = false
ULMailBoxBase.ULMailCommon = nil


function ULMailBoxBase:RefreshMailBasicInfo(nCount)
    self.pWidgetRef.txtMailCount:SetText(string.format( "%d / %d",nCount, MailSystem:GetMailBoxCapacity(self:GetMailBoxType())))
end

-- must be override in child class
function ULMailBoxBase:GetMailBoxType()
    return nil
end

function ULMailBoxBase:GetUnreadMailCount()
    local nType = self:GetMailBoxType()
    return self.ULMailCommon:GetUnreadMailCount(nType)
end

function ULMailBoxBase:GetMails()
    local nType = self:GetMailBoxType()
    local tbMails = self.ULMailCommon:GetMails(nType)
    table.sort(tbMails, self.ULMailCommon:GetMailCompareFn())
    return tbMails
end

function ULMailBoxBase:HasUngotAttachment()
    local nType = self:GetMailBoxType()
    return self.ULMailCommon:HasUngotAttachment(nType)
end

function ULMailBoxBase:Init()
    self.ULMailCommon = self.Owner.ULMailCommon
end

function ULMailBoxBase:Activate()
    if self.bActivate then
        return
    end
    self.ULMailCommon.nCurrentMailBoxCategory = self:GetMailBoxType()
    local tbMails = self:GetMails()
    local pWidgetRef = self.pWidgetRef
    local nCount = #tbMails
    if nCount > 0 then
        self.Owner.ListHelper:SetData(tbMails)
        pWidgetRef.bdrFriend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.bdrNoting:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxOperate:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.bdrNoting:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.bdrFriend:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxOperate:SetVisibility(ESlateVisibility.Collapsed)
    end
    self:RefreshMailBasicInfo(nCount)
    if self:HasUngotAttachment() then
        pWidgetRef.kmbtnGetAll:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.kmbtnGetAll:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.bActivate = true
end

function ULMailBoxBase:Deactivate()
    if not self.bActivate then
        return
    end
    self.Owner.ListHelper:SetData(nil)
    self.bActivate = false
end

function ULMailBoxBase:Uninit()
    self:Deactivate()
end


----------life cycle----------

-- function ULMailBoxBase:OnCreate()
-- end

function ULMailBoxBase:OnBindEvent(EventHelper)

end

return ULMailBoxBase