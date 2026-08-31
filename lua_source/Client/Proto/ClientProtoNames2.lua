local Proto = {}

---------------------------------------------
-- export from src\client2.proto begin

-- Message definitions for network packets for the game
-- Note: Follow the style guide when writing message definitions:
-- https://developers.google.com/protocol-buffers/docs/style






-- export from src\client2.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\currency.proto begin






-- ============================================================================

Proto.Currency = "Currency"

-- 同步货币堆叠数量
Proto.s2c_SyncCurrencyCount = "s2c_SyncCurrencyCount"

-- export from src\client2\currency.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\dungeon.proto begin





-- ========================================================================================================
-- Dungeon

-- 客户端准备进入副本，服务器已将玩家从世界移除，客户端需要显示loading，并将除自己外的其余场景内对象删除，以防进入失败时，服务器重新把玩家加回到场景中，
-- 让客户端重新添加相同的场景内对象报重复创建对象错误
Proto.s2c_WaitingDungeon = "s2c_WaitingDungeon"

Proto.s2c_EnterDungeon = "s2c_EnterDungeon"

Proto.Transform = "Transform"

-- TODO need to rename to s2c_ExitDungeon to keep aligned with defination in ../dungeon.proto
Proto.s2c_LeaveDungeon = "s2c_LeaveDungeon"
Proto.s2c_LeaveDungeon_LeaveReason = {
        NO_REASON = 0,
        DUNGEON_DROPPED_FROM_HUB = 1,
        CLIENT_LOGOUT_FROM_DUNGEON = 2, -- 副本服务器检测到客户端离开，对应 ../dungeon.proto 中 d2s_PlayerExit 协议，若 d2s_PlayerExit 为副本服务器向 hub 发送的第一个关于玩家离开的协议（非 d2s_MatchEnd, d2s_QuitDungeon 或 d2s_LeaveDungeon 等，则通常认为玩家与副本服务器掉线，Hub 发送此 reason 给 client）
}

-- 客户端进副本超时后发给服务器，此包在进入Procedure_Battle后如果长时间未收到controller的beginplay会触发
Proto.c2s_TravelDungeonFailed = "c2s_TravelDungeonFailed"

-- 进入副本失败，在 s2c_WaitingDungeon 协议后真正进入副本之前（Dungeon 认为的真正进入副本之前）任何时候发送
Proto.s2c_DungeonEnterFailed = "s2c_DungeonEnterFailed"
Proto.s2c_DungeonEnterFailed_FailReason = {
        DUNGEON_APPLY_FAILED    = 0, -- 副本申请失败
        CLIENT_TRAVEL_FAILED    = 1, -- 客户端发送 c2s_TravelDungeonFailed
        DUNGEON_DROPPED         = 2, -- 副本服务器和 hub 间掉线
        MATCH_END               = 3, -- 战斗结束
        UNKNOWN_REASON          = 4, -- 未知错误
}

-- ================================================================================================================

Proto.c2s_StartMatchmaking = "c2s_StartMatchmaking"

Proto.s2c_StartMatchmaking = "s2c_StartMatchmaking"
Proto.s2c_StartMatchmaking_Reason = {
        SUCCESS = 0, -- 请求成功
        TIMEOUT = 1, -- 请求超时
        CONNECT_ERROR = 2, -- 连接错误
        UNKNOWN_REASON = 3, -- 未知错误
}

-- export from src\client2\dungeon.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\friend.proto begin






-- ============================================================================
-- Friend System

-- 申请好友信息数据
Proto.ApplyFriendInfo = "ApplyFriendInfo"

-- 玩家简略信息
Proto.PlayerInfo = "PlayerInfo"

-- 添加好友返回结果
Proto.AddFriendResult = "AddFriendResult"

-- 精确查找
Proto.c2s_PreciseSearch = "c2s_PreciseSearch"

Proto.s2c_PreciseSearch = "s2c_PreciseSearch"

-- 申请好友
Proto.c2s_ApplyFriend = "c2s_ApplyFriend"

Proto.s2c_ApplyFriend = "s2c_ApplyFriend"

-- 主动推送好友申请
Proto.s2c_NotifyApplyFriend = "s2c_NotifyApplyFriend"

-- 删除申请好友
Proto.c2s_DeleteApplyFriend = "c2s_DeleteApplyFriend"

Proto.s2c_DeleteApplyFriend = "s2c_DeleteApplyFriend"

-- 获得好友申请列表
Proto.c2s_GetApplyFriends = "c2s_GetApplyFriends"

Proto.s2c_GetApplyFriends = "s2c_GetApplyFriends"

-- 获得申请好友列表数量
Proto.c2s_GetApplyFriendCount = "c2s_GetApplyFriendCount"

Proto.s2c_GetApplyFriendCount = "s2c_GetApplyFriendCount"

-- 删除所有好友申请
Proto.c2s_DeleteAllApplyFriend = "c2s_DeleteAllApplyFriend"

Proto.s2c_DeleteAllApplyFriend = "s2c_DeleteAllApplyFriend"

-- 同意所有好友申请
Proto.c2s_AddAllApplyFriend = "c2s_AddAllApplyFriend"

Proto.s2c_AddAllApplyFriend = "s2c_AddAllApplyFriend"

-- 获得好友列表
Proto.c2s_GetFriends = "c2s_GetFriends"

Proto.s2c_GetFriends = "s2c_GetFriends"

-- 添加好友
Proto.c2s_AddFriend = "c2s_AddFriend"

Proto.s2c_AddFriend = "s2c_AddFriend"

-- 主动推送好友添加成功通知
Proto.s2c_NotifyAddFriend = "s2c_NotifyAddFriend"

-- 删除好友
Proto.c2s_DeleteFriend = "c2s_DeleteFriend"

Proto.s2c_DeleteFriend = "s2c_DeleteFriend"

-- 主动推送删除好友通知
Proto.s2c_NotifyDeleteFriend = "s2c_NotifyDeleteFriend"


-- export from src\client2\friend.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\item.proto begin






-- ============================================================================

Proto.Item = "Item"

-- 获取新道具
Proto.s2c_AddItem = "s2c_AddItem"

-- 同步Item堆叠数量
Proto.s2c_SyncItemStackCount = "s2c_SyncItemStackCount"

Proto.AddedItem = "AddedItem"

-- 添加新的道具客户端弹出奖励窗口
Proto.s2c_AddItemNotification = "s2c_AddItemNotification"

-- 出售道具
Proto.c2s_SellItem = "c2s_SellItem"

Proto.s2c_SellItem = "s2c_SellItem"

-- 使用道具
Proto.c2s_UseItem = "c2s_UseItem"

Proto.s2c_UseItem = "s2c_UseItem"

-- export from src\client2\item.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\login.proto begin






Proto.c2s_Login = "c2s_Login"

Proto.s2c_LoginError = "s2c_LoginError"

Proto.s2c_NewPlayer = "s2c_NewPlayer"

Proto.c2s_CreatePlayer = "c2s_CreatePlayer"

Proto.s2c_CreatePlayerError = "s2c_CreatePlayerError"

Proto.s2c_PlayerData = "s2c_PlayerData"

Proto.s2c_Disconnect = "s2c_Disconnect"
Proto.s2c_Disconnect_Reason = {
        UNKNOWN             = 0,
        KICK_OUT            = 1,
        DOUBLE_LOGIN        = 2,
        SERVER_FULL         = 3,
        SERVER_MAINTENANCE  = 4,
        PING_MISSING        = 5,    -- Server doesn't receive c2s_Ping for a long time.
}


-- export from src\client2\login.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\mail.proto begin





-- ========================================================================================================
-- Mail System


--附件
Proto.MailAttachment = "MailAttachment"

-- 邮件
Proto.Mail = "Mail"


Proto.MailBoxType = {
    INVALID = 0,
    SYSTEM = 1,           -- 系统邮件
    FRIEND = 2,           -- 好友邮件
    MESSAGE_CENTER = 3,   -- 消息中心
}

-- 同步所有邮
Proto.c2s_PlayerMails = "c2s_PlayerMails"

Proto.s2c_PlayerMails = "s2c_PlayerMails"

-- 新邮件通知
Proto.s2c_NewMailNotify = "s2c_NewMailNotify"

-- 已读
Proto.c2s_MarkMailAsRead = "c2s_MarkMailAsRead"

Proto.s2c_MarkMailAsRead = "s2c_MarkMailAsRead"

-- 领取
Proto.c2s_ClaimMailAttachments = "c2s_ClaimMailAttachments"

Proto.s2c_ClaimMailAttachments = "s2c_ClaimMailAttachments"

-- 删除
Proto.c2s_DeleteMail = "c2s_DeleteMail"

Proto.s2c_DeleteMail = "s2c_DeleteMail"

-- export from src\client2\mail.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\misc.proto begin





-- ============================================================================

-- See: GmSystem
Proto.c2s_GmCmd = "c2s_GmCmd"

-- export from src\client2\misc.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\player.proto begin






-- ============================================================================

Proto.Player = "Player"

-- export from src\client2\player.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\rc.proto begin





Proto.ReturnCode = {
    -- Each module is assigned 100 digits

    -- General 0~99
    OK                     = 0, -- The request sent by client was successfully processed by server
    INVALID_REQUEST        = 1, -- The request sent by client was invalid
    SERVER_ERROR           = 2, -- Server internal error
    LOGIN_FAIL             = 3, -- Login failed (invalid token, internal error, etc.)
    NAME_UNAVAILABLE       = 4, -- Player name already taken
    DATA_ERROR             = 5, -- invalid data (null pointer)
    PLAYER_COUNT_LIMIT     = 6, -- 角色数量达到上限，无法创建角色
    PLAYER_NAME_LENGTH     = 7, -- 角色名字长度不符合要求
    PLAYER_NAME_CHAR       = 8, -- 角色名字包含非法字符


    -- Team 100~199
    PLAYER_ALREADY_IN_TEAM       = 100, -- 玩家已经加入了队伍
    INVITEE_ALREADY_IN_TEAM      = 101, -- 被邀请人已经加入了队伍
    PLAYER_NOT_IN_TEAM           = 102, -- 玩家所在队伍已解散
    PLAYER_NOT_IN_INVITE_LIST    = 103, -- 玩家不在邀请列表
    NOT_TEAM_LEADER              = 104, -- 不是队长
    REFUSE_INVITE                = 105, -- 拒绝邀请
    REFUSE_JOIN                  = 106, -- 拒绝加入队伍
    NOT_IN_APPLY_LIST            = 107, -- 玩家不在申请列表
    INVITATION_OUT_DATE          = 108, -- 邀请已经过期
    APPLICATION_OUT_DATE         = 109, -- 申请已经过期
    NOT_TEAM_MEMBER              = 110, -- 不是队伍成员
    TEAM_DISMISSED               = 111, -- 队伍已解散
    TEAM_FULL                    = 112, -- 队伍满员


    -- Item 200~299
    ITEM_CANNOT_USE              = 200, -- 道具不可使用
    ITEM_NOT_FOUND               = 201, -- 未找到这个物品
    ITEM_CANNOT_SELL             = 202, -- 物品不能出售
    ITEM_NOT_IN_BACKPACK         = 203, -- 物品不在背包里
    ITEM_NOT_ENOUGH              = 204, -- 物品数量不足
    ITEM_EXPIRED                 = 205, -- 商品过期无法使用
    ITEM_LEVEL_LIMITED           = 206, -- 玩家等级不足
    ITEM_GENDER_NOT_MATCH        = 207, -- 玩家性别不对



    -- Friend 300~399
    APPLY_FRIEND_LIMIT               = 300, -- 好友申请人数上限
    FRIEND_COUNT_LIMIT               = 301, -- 好友人数已达上限
    OTHER_APPLY_FRIEND_LIMIT         = 302, -- 对方申请列表上限
    OTHER_FRIEND_COUNT_LIMIT         = 303, -- 对方好友人数上限
    FRIEND_NOT_FOUND                 = 304, -- 未发现好友数据
    CANNOT_ADD_SELF                  = 305, -- 不能添加自己
    ALREADY_IN_APPLY_FRIEND          = 306, -- 已经在申请好友列表中
    ALREADY_IN_FRIEND                = 307, -- 已经在好友列表中
    OTHER_NOT_IN_APPLY_LIST          = 308, -- 对方不在申请列表
    APPLY_FRIEND_MSG_EMPTY           = 309, -- 申请好友消息为空
    FRIEND_DB_ERROR                  = 310, -- 数据库错误

    -- Mail 400~499
    MAIL_NOT_EXIST                   = 401, -- 邮件不存在
    MAIL_NOT_CLAIMED                 = 402, -- 邮件未领取
    MAIL_NOT_READ                    = 403, -- 邮件未读
    MAIL_OUT_OF_DATE                 = 404, -- 邮件过期
    MAIL_CLAIMED                     = 405, -- 邮件已领取
    MAIL_READ                        = 406, -- 邮件已读
    MAIL_NOT_HAS_ATTACHMENT          = 407, -- 邮件没附件
}

-- export from src\client2\rc.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\team.proto begin






-- ============================================================================
-- 客户端需要处理的队伍同步协议

-- 队伍数据
Proto.TeamMember = "TeamMember"

-- 玩家登陆游戏、加入队伍、创建队伍 同步给玩家完整的队伍信息
Proto.s2c_SyncTeam = "s2c_SyncTeam"

-- ==============================================
-- 组建队伍，添加成员

-- 邀请玩家加入队伍
Proto.c2s_InviteJoinTeam = "c2s_InviteJoinTeam"
Proto.s2c_InviteJoinTeam = "s2c_InviteJoinTeam"

-- 申请加入队伍
Proto.c2s_ApplyJoinTeam = "c2s_ApplyJoinTeam"
Proto.s2c_ApplyJoinTeam = "s2c_ApplyJoinTeam"

-- 应答加入队伍
Proto.c2s_ReplyJoinTeam = "c2s_ReplyJoinTeam"
Proto.s2c_ReplyJoinTeam = "s2c_ReplyJoinTeam"

-- 通知玩家有申请和邀请
Proto.s2c_NotifyInviteApply = "s2c_NotifyInviteApply"

-- 通知玩家申请和邀请结果
Proto.s2c_NotifyReplyInviteApply = "s2c_NotifyReplyInviteApply"

-- ==============================================
-- 队伍其他操作

-- 玩家主动离开队伍
Proto.c2s_LeaveTeam = "c2s_LeaveTeam"

-- 踢出队伍
Proto.c2s_KickOutTeamMember = "c2s_KickOutTeamMember"

-- 转移队长
Proto.c2s_TransferTeamLeader = "c2s_TransferTeamLeader"

-- 邀请申请类型
Proto.INVITE_APPLY_TYPE = {
    INVITE_CREATE_TEAM               = 0,    -- 邀请组建队伍
    INVITE_JOIN_TEAM                 = 1,    -- 邀请加入队伍
    APPLY_JOIN_TEAM                  = 2,    -- 申请加入队伍
}

-- export from src\client2\team.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\ui.proto begin





Proto.s2c_ShowToast = "s2c_ShowToast"


-- export from src\client2\ui.proto end
---------------------------------------------

return Proto