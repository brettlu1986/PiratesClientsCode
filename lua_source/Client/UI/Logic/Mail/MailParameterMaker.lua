-----------------------------------------------------
--File Name    : MailParameterMaker.lua
--Author       : WuJizhou
--Create Time  : 9/12/2019, 4:38:10 PM
--Description  : MailParameterMaker
-----------------------------------------------------
local MailParameterMaker = {}

local MailSystem     = require("MailSystem")
local MailMiscDefine = require("MailMiscDefine")
local ItemDataTable  = require("ItemDataTable")
local Proto          = require("ClientProtoNames")
local UISetUtils = require("UISetUtils")
local FriendRelationShipDataTable = require("FriendRelationShipDataTable")

local MailType = MailMiscDefine.MailType

local PROTO_PARAM_KEY    = MailMiscDefine.PROTO_PARAM_KEY
local TEMPLATE_PARAM_KEY = MailMiscDefine.TEMPLATE_PARAM_KEY

-- 用于那种不需要额外加工，可以直接将服务器的参数用于客户端模板字段的，要求参数名和模板字段名一致
local function MakeCommonTwoListParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}

    for k, v in pairs(tbRawParams) do
        table.insert(tbNames, k)
        table.insert(tbArgs, v)
    end
    return tbNames, tbArgs
end

local function MakeCommonTableParams(tbRawParams)
    local tbParams = {}
    for k, v in pairs(tbRawParams) do
        tbParams[k] = v
    end
    return tbParams
end

local function MakeTeamInvitationTwoListParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}

    table.insert(tbNames, TEMPLATE_PARAM_KEY.PLAYER_ID)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.PLAYER_ID])

    table.insert(tbNames, TEMPLATE_PARAM_KEY.PLAYER_NAME)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.PLAYER_NAME])

    table.insert(tbNames, TEMPLATE_PARAM_KEY.AVATAR_ID)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.AVATAR_ID])

    table.insert(tbNames, TEMPLATE_PARAM_KEY.LEVEL)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.LEVEL])
    return tbNames, tbArgs
end

local function MakeTeamInvitationTableParams(tbRawParams)
    local tbParams = {}
    tbParams[TEMPLATE_PARAM_KEY.PLAYER_ID] = tbRawParams[PROTO_PARAM_KEY.PLAYER_ID]
    tbParams[TEMPLATE_PARAM_KEY.PLAYER_NAME] = tbRawParams[PROTO_PARAM_KEY.PLAYER_NAME]
    tbParams[TEMPLATE_PARAM_KEY.AVATAR_ID] = tbRawParams[PROTO_PARAM_KEY.AVATAR_ID]
    tbParams[TEMPLATE_PARAM_KEY.LEVEL] = tbRawParams[PROTO_PARAM_KEY.LEVEL]
    return tbParams
end


local function MakeItemExpiredTwoListParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}
    local nItemTemplateId = tbRawParams[PROTO_PARAM_KEY.ITEM_TEMPLATE_ID]
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)

    table.insert(tbNames, TEMPLATE_PARAM_KEY.ITEM_DESC)
    table.insert(tbArgs, tbItemTemplate.l10nName)

    table.insert(tbNames, TEMPLATE_PARAM_KEY.ITEM_COUNT)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.ITEM_COUNT])

    return tbNames, tbArgs
end

local function MakeItemExpiredTableParams(tbRawParams)
    local tbParams = {}

    local nItemTemplateId = tbRawParams[PROTO_PARAM_KEY.ITEM_TEMPLATE_ID]
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    tbParams[TEMPLATE_PARAM_KEY.ITEM_DESC] = tbItemTemplate.l10nName
    tbParams[TEMPLATE_PARAM_KEY.ITEM_COUNT] = tbRawParams[PROTO_PARAM_KEY.ITEM_COUNT]

    return tbParams
end

-- tbRawParams {player_name, item_template_id, item_count, add_intimacy_points}
local function MakeUseFriendShipCardListParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}
   
    table.insert(tbNames, TEMPLATE_PARAM_KEY.PLAYER_NAME)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.PLAYER_NAME])
    
    table.insert(tbNames, TEMPLATE_PARAM_KEY.ITEM_COUNT)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.ITEM_COUNT])

    local nItemTemplateId = tbRawParams[PROTO_PARAM_KEY.ITEM_TEMPLATE_ID]
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    table.insert(tbNames, TEMPLATE_PARAM_KEY.ITEM_NAME)
    table.insert(tbArgs, tbItemTemplate.l10nName)

    table.insert(tbNames, TEMPLATE_PARAM_KEY.ADD_INTIMACY)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.ADD_INTIMACY])

    return tbNames, tbArgs
end

local function MakeSendFriendGiftListParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}
    table.insert(tbNames, TEMPLATE_PARAM_KEY.PLAYER_NAME)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.PLAYER_NAME])

    table.insert(tbNames, TEMPLATE_PARAM_KEY.ADD_INTIMACY)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.ADD_INTIMACY])

    return tbNames, tbArgs
end

local function MakeRelationShipChangedParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}
   
    table.insert(tbNames, TEMPLATE_PARAM_KEY.PLAYER_NAME)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.PLAYER_NAME])
    
    table.insert(tbNames, TEMPLATE_PARAM_KEY.RELATION_AFFIRM)
    local bAccepted = tbRawParams[PROTO_PARAM_KEY.RELATION_RESULT]
    if bAccepted then 
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_AGREE"))
    else  
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_STATIC_FRIEND_REFUSE"))
    end

    local nRelationState = tbRawParams[PROTO_PARAM_KEY.RELATION_STATE]
    table.insert(tbNames, TEMPLATE_PARAM_KEY.CREATE_CANCEL)
    if nRelationState == Proto.RelationshipState.APPLYING then  
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_RELATION_CREATE"))
    else
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_RELATION_CANCEL"))
    end

    table.insert(tbNames, TEMPLATE_PARAM_KEY.RELATION_NAME)
    local nRelationid = tbRawParams[PROTO_PARAM_KEY.RELATION_ID]
    local l10nName = FriendRelationShipDataTable:GetTemplate(nRelationid).l10nName
    table.insert(tbArgs, l10nName)

    table.insert(tbNames, TEMPLATE_PARAM_KEY.CREATE_CANCEL)
    if nRelationState  == Proto.RelationshipState.APPLYING then  
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_RELATION_CREATE"))
    else
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_RELATION_CANCEL"))
    end

    table.insert(tbNames, TEMPLATE_PARAM_KEY.RELATION_RESULT)
    if bAccepted then 
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_SUCCESS"))
    else  
        table.insert(tbArgs, UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_FAIL"))
    end

    return tbNames, tbArgs
end

local function MakeRelationShipLevelUpParams(tbRawParams)
    local tbNames = {}
    local tbArgs = {}
   
    table.insert(tbNames, TEMPLATE_PARAM_KEY.PLAYER_NAME)
    table.insert(tbArgs, tbRawParams[PROTO_PARAM_KEY.PLAYER_NAME])

    table.insert(tbNames, TEMPLATE_PARAM_KEY.RELATION_NAME)
    local nRelationid = tbRawParams[PROTO_PARAM_KEY.RELATION_ID]
    local l10nName = FriendRelationShipDataTable:GetTemplate(nRelationid).l10nName
    table.insert(tbArgs, l10nName)

    table.insert(tbNames, TEMPLATE_PARAM_KEY.RELATION_LEVEL)
    local nRelationLv = tbRawParams[PROTO_PARAM_KEY.RELATION_LEVEL]
    table.insert(tbArgs, nRelationLv)
    return tbNames, tbArgs
end

local tbMakeTwoListParamsFunctions = {}

tbMakeTwoListParamsFunctions[MailType.TYPE_TEAM_INVITATION] = MakeTeamInvitationTwoListParams               -- 组队邀请
tbMakeTwoListParamsFunctions[MailType.TYPE_ITEM_EXPIRED] = MakeItemExpiredTwoListParams                  -- 道具过期
tbMakeTwoListParamsFunctions[MailType.TYPE_CUSTOM] = MakeCommonTwoListParams
tbMakeTwoListParamsFunctions[MailType.TYPE_USE_FRIENDSHIP_CARD] = MakeUseFriendShipCardListParams
tbMakeTwoListParamsFunctions[MailType.TYPE_SEND_FRIEND_GIFT] = MakeSendFriendGiftListParams
tbMakeTwoListParamsFunctions[MailType.TYPE_FRIEND_RELATIONSHIP] = MakeRelationShipChangedParams
tbMakeTwoListParamsFunctions[MailType.TYPE_FRIEND_RELATIONSHIP_LEVEL] = MakeRelationShipLevelUpParams


local tbMakeTableParamsFunctions = {}

tbMakeTableParamsFunctions[MailType.TYPE_TEAM_INVITATION] = MakeTeamInvitationTableParams               -- 组队邀请
tbMakeTableParamsFunctions[MailType.TYPE_ITEM_EXPIRED] = MakeItemExpiredTableParams                  -- 道具过期
tbMakeTableParamsFunctions[MailType.TYPE_CUSTOM] = MakeCommonTableParams



-- return two lists, the first one is the list of keys, the second one is the list of values
function MailParameterMaker:MakeTwoListParams(tbMail)
    local nType = tbMail.type
    local fnFunc = tbMakeTwoListParamsFunctions[nType]
    local tbNames = nil
    local tbArgs  = nil
    if not fnFunc then
        logerror("MailParameterMaker:MakeTwoListParams error, has no func defined, mail type is ", nType)
    else
        local tbRawParams = MailSystem:GetMailParams(tbMail)
        tbNames, tbArgs = fnFunc(tbRawParams)
    end
    return tbNames, tbArgs
end

function MailParameterMaker:MakeTableParams(tbMail)
    local nType = tbMail.type
    local fnFunc = tbMakeTableParamsFunctions[nType]
    local tbParams = nil
    if not fnFunc then
        logerror("MailParameterMaker:MakeTableParams error, has no func defined, mail type is ", nType)
    else
        local tbRawParams = MailSystem:GetMailParams(tbMail)
        tbParams = fnFunc(tbRawParams)
    end
    return tbParams
end

function MailParameterMaker:GetMailParamsByKey(tbMail, szKey)
    local tbRawParams = MailSystem:GetMailParams(tbMail)
    return tbRawParams[szKey]
end

return MailParameterMaker