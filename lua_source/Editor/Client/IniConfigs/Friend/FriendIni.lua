--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local FriendIni = {}
FriendIni.szFileName = "common/friend2/friend.ini"

function FriendIni:OnParse(Parser)
    local tbApplyFriend = {}
    tbApplyFriend.nMaxApplyFriend = Parser:Get("apply_friend", "max_apply_friend", -1, Parser.TypeNumber)
    tbApplyFriend.nMaxApplyFriendMessage = Parser:Get("apply_friend", "max_apply_friend_message", -1, Parser.TypeNumber)
    self.tbApplyFriend = tbApplyFriend

    local tbFriend = {}
    tbFriend.nMaxApplyFriend = Parser:Get("friend", "max_friend", -1, Parser.TypeNumber)
    self.tbFriend = tbFriend

    local tbTeam = {}
    tbTeam.nMaxApplyFriend = Parser:Get("team", "max_team", -1, Parser.TypeNumber)
    self.tbTeam = tbTeam

    local tbFFA = {}
    tbFFA.nTraningCampId = Parser:Get("ffa", "training_camp_id", -1, Parser.TypeNumber)
    tbFFA.nHumanNearDistance = Parser:Get("ffa", "human_near_distance", -1, Parser.TypeNumber)
    tbFFA.nShipNearDistance = Parser:Get("ffa", "ship_near_distance", -1, Parser.TypeNumber)
    self.tbFFA = tbFFA

    self.nCancelCoolDownDay = Parser:Get("relationship", "days_cool_down_after_cancel", 0, Parser.TypeNumber)
    self.nOrderInimacy = Parser:Get("reservation", "reservation_intimacy_points_limit", 0, Parser.TypeNumber)
end

return FriendIni
