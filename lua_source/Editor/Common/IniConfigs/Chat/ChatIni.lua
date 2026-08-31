--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ChatIni = {}
ChatIni.szFileName = "common/chat2/chat.ini"

function ChatIni:OnParse(Parser)
    local tbChatLength = {}
    tbChatLength.nLength = Parser:Get("chat", "content_length", -1, Parser.TypeNumber)
    self.tbChatLength = tbChatLength

    local tbCoolDown = {}
    tbCoolDown.nWorld = Parser:Get("cooldown", "world_channel", -1, Parser.TypeNumber)
    tbCoolDown.nFriend = Parser:Get("cooldown", "friend_channel", -1, Parser.TypeNumber)
    tbCoolDown.nRoom = Parser:Get("cooldown", "room_channel", -1, Parser.TypeNumber)
    tbCoolDown.nTeam = Parser:Get("cooldown", "team_channel", -1, Parser.TypeNumber)
    tbCoolDown.nCorp = Parser:Get("cooldown", "corps_channel", -1, Parser.TypeNumber)
    -- tbCoolDown.nTeam_Invite = Parser:Get("cooldown", "team_invite_channel", -1, Parser.TypeNumber)
    self.tbCoolDown = tbCoolDown

    local tbConst = {}
    tbConst.nHistoryMaxCount = Parser:Get("const", "history_max_count", -1, Parser.TypeNumber)
    tbConst.nShowTimelineInterval = Parser:Get("const", "show_timeline_interval", -1, Parser.TypeNumber)
    self.tbConst = tbConst

    local tbHorn = {}
    tbHorn.nInterval = Parser:Get("horn", "interval", 0, Parser.TypeNumber)
    self.tbHorn = tbHorn
end

return ChatIni
