-----------------------------------------------------
--File Name    : ULMailBoxFriend.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 2:43:34 PM
--Description  : ULMailBoxFriend
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMailBoxBase = require("ULMailBoxBase")
local ULMailBoxFriend = luaclass("ULMailBoxFriend", ULMailBoxBase)

local MailMiscDefine = require("MailMiscDefine")
local MailboxType = MailMiscDefine.MailboxType


function ULMailBoxFriend:GetMailBoxType()
    return MailboxType.MAIL_FRIEND
end


return ULMailBoxFriend