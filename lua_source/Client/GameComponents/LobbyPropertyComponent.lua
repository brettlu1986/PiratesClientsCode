local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local LobbyPropertyComponent = luaclass("LobbyPropertyComponent", GameComponentBase)

local AvatarDataTable = require("AvatarDataTable")
local HumanDataTable = require("HumanDataTable")

LobbyPropertyComponent.nAvatarTemplateId = 0
LobbyPropertyComponent.nHumanTemplateId = 0
LobbyPropertyComponent.szName = nil
LobbyPropertyComponent.nLevel = 0
LobbyPropertyComponent.nExp = 0
LobbyPropertyComponent.nFirstBattleTime = 0
LobbyPropertyComponent.nBattleCount = 0

function LobbyPropertyComponent:OnCreate(Owner, tbParams)
    LobbyPropertyComponent.super.OnCreate(self, Owner, tbParams)
    self.nAvatarTemplateId = tbParams.avatar_id
    self.nHumanTemplateId = AvatarDataTable:GetHumanId(tbParams.avatar_id)
    self.szName = tbParams.name
    self.nLevel = tbParams.level
    self.nExp = tbParams.exp
    -- self.nRank = tbParams.rank
    self.nFirstBattleTime = tbParams.battle.first_battle_time
    self.nBattleCount = tbParams.battle.battle_count
    return true
end

function LobbyPropertyComponent:GetHumanGender()
    return HumanDataTable:GetTemplate(self.nHumanTemplateId).nGender
end

function LobbyPropertyComponent:GetHumanRace()
    return HumanDataTable:GetTemplate(self.nHumanTemplateId).nRace
end

function LobbyPropertyComponent:GetHumanHeadIconId()
    local tbTemplate = AvatarDataTable:GetTemplate(self.nAvatarTemplateId)
    if tbTemplate == nil then
        return nil
    else
        return tbTemplate.nHeadIconId
    end
end

function LobbyPropertyComponent:GetAvatarId()
    return self.nAvatarTemplateId
end

function LobbyPropertyComponent:GetHumanTemplateId()
    return self.nHumanTemplateId
end

function LobbyPropertyComponent:GetPlayerLevel()
    return self.nLevel
end

function LobbyPropertyComponent:GetPlayerExp()
    return self.nExp
end

function LobbyPropertyComponent:GetPlayerName()
    return self.szName
end


function LobbyPropertyComponent:GetFirstBattleTime()
    return self.nFirstBattleTime
end

function LobbyPropertyComponent:SetFirstBattleTime(nBattleTime)
    self.nFirstBattleTime = nBattleTime
end


function LobbyPropertyComponent:SetExp(nExp)
    self.nExp = nExp
end

function LobbyPropertyComponent:SetLevel(nLevel)
    self.nLevel = nLevel
end

function LobbyPropertyComponent:SetName(szName)
    self.szName = szName
end

return LobbyPropertyComponent
