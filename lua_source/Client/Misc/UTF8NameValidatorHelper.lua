
-----------------------------------------------------
--File Name    : UTF8NameValidatorHelper.lua
--Author       : Zuo Kun
--Create Time  : 2017-10-25
--Description  :
-----------------------------------------------------
local UTF8NameValidator = require("UTF8NameValidator")
local PlayerNameIni = require("PlayerNameIni")
local CodePointData = require("CodePointData")
local MessageCodePointData = require("MessageCodePointData")
local FriendIni     = require("FriendIni")
-- local GuildNameIni  = require("GuildNameIni")
-- local AnnouncementCodePointData = require("GuildAnnouncementCodePointDataTable")

local UTF8NameValidatorHelper = {}

function UTF8NameValidatorHelper:CreatePlayerNameValidator()
    local tbNameValidator = UTF8NameValidator()
    tbNameValidator:SetLengthConstraint(PlayerNameIni.nMinCodePoint, PlayerNameIni.nMaxCodePoint,
        PlayerNameIni.nMinDisplayWidth, PlayerNameIni.nMaxDisplayWidth)

    local tbCodePoints = CodePointData:GetTemplate()
    tbNameValidator:AddBlocks(tbCodePoints)
    return tbNameValidator
end

function UTF8NameValidatorHelper:ApplyFriendMessageValidator()
    local tbNameValidator = UTF8NameValidator()
    local tbApplyFriend = FriendIni.tbApplyFriend
    tbNameValidator:SetLengthConstraint(0, tbApplyFriend.nMaxApplyFriendMessage,
        0, tbApplyFriend.nMaxApplyFriendMessage)

    local tbCodePoints = MessageCodePointData:GetTemplate()
    tbNameValidator:AddBlocks(tbCodePoints)
    return tbNameValidator
end

-- function UTF8NameValidatorHelper:CreateGuildNameValidator()
--     local tbNameValidator = UTF8NameValidator()
--     local tbName = GuildNameIni.tbName
--     tbNameValidator:SetLengthConstraint(tbName.nMinCodePoint, tbName.nMaxCodePoint,
--         tbName.nMinDisplayWidth, tbName.nMaxDisplayWidth)

--     local tbCodePoints = CodePointData:GetTemplate()
--     tbNameValidator:AddBlocks(tbCodePoints)
--     return tbNameValidator
-- end

-- function UTF8NameValidatorHelper:CreateGuildAnnouncementValidator()
--     local tbNameValidator = UTF8NameValidator()
--     local tbAnnouncement = GuildNameIni.tbAnnouncement
--     tbNameValidator:SetLengthConstraint(tbAnnouncement.nMinCodePoint, tbAnnouncement.nMaxCodePoint,
--         tbAnnouncement.nMinDisplayWidth, tbAnnouncement.nMaxDisplayWidth)

--     local tbCodePoints = AnnouncementCodePointData:GetTemplate()
--     tbNameValidator:AddBlocks(tbCodePoints)
--     return tbNameValidator
-- end

return UTF8NameValidatorHelper