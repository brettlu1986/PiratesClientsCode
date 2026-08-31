-----------------------------------------------------
--File Name    : ULMailBoxSystem.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 2:43:34 PM
--Description  : ULMailBoxSystem
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMailBoxBase = require("ULMailBoxBase")
local ULMailBoxSystem = luaclass("ULMailBoxSystem", ULMailBoxBase)

local MailMiscDefine = require("MailMiscDefine")
local MailboxType = MailMiscDefine.MailboxType

function ULMailBoxSystem:GetMailBoxType()
    return MailboxType.MAIL_SYSTEM
end

return ULMailBoxSystem