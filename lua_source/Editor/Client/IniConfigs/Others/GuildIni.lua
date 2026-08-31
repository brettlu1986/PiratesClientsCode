--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local GuildIni = {}

GuildIni.szFileName = "common/guild/guild.ini"

function GuildIni:OnParse(Parser)
    local tbDefault = {}
    tbDefault.nEnable = Parser:Get("default", "enable", 1, Parser.TypeNumber)
    self.tbDefault = tbDefault
    
    local tbGuildList = {}
    tbGuildList.nRefreshInterval = Parser:Get("guild_list", "refresh_interval", 1, Parser.TypeNumber)
    self.tbGuildList = tbGuildList

    local tbInitGuild = {}
    tbInitGuild.nInitRequestLevel = Parser:Get("init_guild", "init_request_level", 1, Parser.TypeNumber) 
    tbInitGuild.nRequestLevelInterval = Parser:Get("init_guild", "request_level_interval", 1, Parser.TypeNumber) 
    self.tbInitGuild = tbInitGuild

    local tbCreateGuild = {}
    tbCreateGuild.nCurrencyType = Parser:Get("create_guild", "currency_type", -1, Parser.TypeNumber)
    tbCreateGuild.nCurrencyCount= Parser:Get("create_guild", "currency_count", -1, Parser.TypeNumber)
    tbCreateGuild.nNameMin      = Parser:Get("create_guild", "guild_name_min", -1, Parser.TypeNumber)
    tbCreateGuild.nNameMax      = Parser:Get("create_guild", "guild_name_max", -1, Parser.TypeNumber)
    self.tbCreateGuild = tbCreateGuild

    local tbRequestGuild = {}
    tbRequestGuild.nRequestMax  = Parser:Get("request_guild", "request_max", -1, Parser.TypeNumber)
    tbRequestGuild.nJoinCdTime  = Parser:Get("request_guild", "join_cd_time", -1, Parser.TypeNumber)
    self.tbRequestGuild = tbRequestGuild

    local tbInvite = {}
    tbInvite.nInviteListMaxCount = Parser:Get("invite", "invite_list_max_count", -1, Parser.TypeNumber)
    tbInvite.nInviteTime = Parser:Get("invite", "invite_time", -1, Parser.TypeNumber)
    self.tbInvite = tbInvite

    local tbGuild = {}
    tbGuild.nForbidChatTime     = Parser:Get("guild", "forbid_chat_time", -1, Parser.TypeNumber)
    tbGuild.nChangePresidentTime= Parser:Get("guild", "change_president_time", -1, Parser.TypeNumber)
    tbGuild.nDissolveGuildTime  = Parser:Get("guild", "dissolve_guild_time", -1, Parser.TypeNumber)
    tbGuild.nKickMemberCount    = Parser:Get("guild", "kick_member_count", -1, Parser.TypeNumber)
    tbGuild.nAnnouncementMax    = Parser:Get("guild", "announcement_max", -1, Parser.TypeNumber)
    tbGuild.nMaxActiveness      = Parser:Get("guild", "max_guild_activeness", -1, Parser.TypeNumber)
    self.tbGuild = tbGuild
    
    local tbPlayerGuild = {}
    tbPlayerGuild.nMaxActiveness        = Parser:Get("player_guild", "max_guild_activeness", -1, Parser.TypeNumber)
    tbPlayerGuild.nDailyMaxActiveness   = Parser:Get("player_guild", "max_daily_guild_activeness", -1, Parser.TypeNumber)
    self.tbPlayerGuild = tbPlayerGuild
end

return GuildIni
