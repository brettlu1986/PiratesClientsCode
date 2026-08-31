-----------------------------------------------------
--File Name    : MailMiscDefine.lua
--Author       : WuJizhou
--Create Time  : 9/17/2019, 6:12:08 PM
--Description  : MailMiscDefine
-----------------------------------------------------
local Proto = require("ClientProtoNames")

local MailMiscDefine = {}

MailMiscDefine.PROTO_PARAM_KEY =
{
    PLAYER_ID           = "player_id",
    PLAYER_NAME         = "player_name",
    AVATAR_ID           = "avatar_id",
    LEVEL               = "level",
    ITEM_TEMPLATE_ID    = "item_template_id",
    ITEM_COUNT          = "item_count",
    ITEM_NAME           = "item_name",
    ADD_INTIMACY        = "add_intimacy_points",
    RELATION_RESULT     = "apply_accepted",
    RELATION_ID         = "relationship_id",
    RELATION_STATE      = "state",
    RELATION_LEVEL      = "relationship_level",
}

local PROTO_PARAM_KEY = MailMiscDefine.PROTO_PARAM_KEY

MailMiscDefine.TEMPLATE_PARAM_KEY =
{
    PLAYER_ID   = PROTO_PARAM_KEY.PLAYER_ID,
    PLAYER_NAME = PROTO_PARAM_KEY.PLAYER_NAME,
    AVATAR_ID   =  PROTO_PARAM_KEY.AVATAR_ID,
    LEVEL       = PROTO_PARAM_KEY.LEVEL,
    ITEM_DESC   = "item_desc",
    ITEM_COUNT  = PROTO_PARAM_KEY.ITEM_COUNT,
    ITEM_NAME   = PROTO_PARAM_KEY.ITEM_NAME,
    ADD_INTIMACY   = PROTO_PARAM_KEY.ADD_INTIMACY,
    RELATION_AFFIRM = "relation_affirm", 
    RELATION_RESULT = "relation_result",
    RELATION_NAME = "relation_name",
    CREATE_CANCEL = "create_cancel",
    RELATION_LEVEL = "relation_level"
}

MailMiscDefine.MailboxType = Proto.MailboxType

MailMiscDefine.MailType = Proto.MailType

MailMiscDefine.MailDisplayType =
{
    Common          = 1,
    Invite          = 2,
    ItemExpired     = 3,
    GetIntimacy     = 4,
    FriendGift      = 5,
    RelationChange  = 6,
    RelationLevelUp = 7
}

MailMiscDefine.BOX_ATTRI_KEY =
{
    LIMIT = "limit"
}

return MailMiscDefine