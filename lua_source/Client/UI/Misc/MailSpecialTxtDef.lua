local MailSpecialTxtDef = {}

local PlayerSelfHelper = require("GamePlayerSelfHelper")

MailSpecialTxtDef.tbTextDef = nil

function MailSpecialTxtDef:Init()
    self.tbTextDef = {}
    self.SelfPlayer = PlayerSelfHelper:Get()
    local szPlayerName = self.SelfPlayer:GetName()
    self.tbTextDef.PlayerName = szPlayerName
end

function MailSpecialTxtDef:GetTextDef()
    self:Init()
    return self.tbTextDef
end

return MailSpecialTxtDef