local HumanArmorPropertyDescKeyParser = {}

local LobbyArmorMiscDataTable           = require("LobbyArmorMiscDataTable")
local BattleItemDataTable               = require("BattleItemDataTable")
local DescKeyParserMiscDef              = require("DescKeyParserMiscDef")

local NAME_SPACE_HUMAN_ARMOR = DescKeyParserMiscDef.NAME_SPACE_HUMAN_ARMOR


local function GetLobbyGeneralDesc(tbInputData)
    local nArmorType = tbInputData.nArmorType
    local tbTemplate = LobbyArmorMiscDataTable:GetTemplate(nArmorType)
    local tbOutData = {}
    tbOutData.bList = false
    tbOutData.l10nData = tbTemplate.l10nGeneralDesc
    return tbOutData
end

local function GetLobbySpecialDesc(tbInputData)
    local nArmorType = tbInputData.nArmorType
    local tbTemplate = LobbyArmorMiscDataTable:GetTemplate(nArmorType)

    local tbOutData = {}
    tbOutData.bList = true
    tbOutData.tbDatas = tbTemplate.tbSpecialDesc
    return tbOutData
end

local function GetLobbyReduceDesc(tbInputData)
    local nArmorType = tbInputData.nArmorType
    local tbTemplate = LobbyArmorMiscDataTable:GetTemplate(nArmorType)
    
    local tbOutData = {}
    tbOutData.bList = true
    tbOutData.tbDatas = tbTemplate.tbReduceDamageDesc
    return tbOutData
end


local function GetDungeonGeneralDesc(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local tbOutData = {}
    tbOutData.bList = false
    tbOutData.l10nData = tbItemTemplate.l10nGeneralDesc
    return tbOutData
end

local function GetDungeonSpecialDesc(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)

    local tbOutData = {}
    tbOutData.bList = true
    tbOutData.tbDatas = tbItemTemplate.tbSpecialDesc
    return tbOutData
end

local function GetDungeonReduceDesc(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local tbOutData = {}
    tbOutData.bList = true
    tbOutData.tbDatas = tbItemTemplate.tbReduceDamageDesc
    return tbOutData
end

function HumanArmorPropertyDescKeyParser.Init(fnDefine)
    --副本外总体概述
    fnDefine(NAME_SPACE_HUMAN_ARMOR,   "lobby_general_desc",                GetLobbyGeneralDesc)
    --副本外特性描述
    fnDefine(NAME_SPACE_HUMAN_ARMOR,   "lobby_special_desc",                GetLobbySpecialDesc)
    --副本外减伤描述
    fnDefine(NAME_SPACE_HUMAN_ARMOR,   "lobby_reduce_desc",                 GetLobbyReduceDesc)

    --副本外总体概述
    fnDefine(NAME_SPACE_HUMAN_ARMOR,   "dungeon_general_desc",              GetDungeonGeneralDesc)
    --副本内特性描述
    fnDefine(NAME_SPACE_HUMAN_ARMOR,   "dungeon_special_desc",              GetDungeonSpecialDesc)
    --副本内减伤描述
    fnDefine(NAME_SPACE_HUMAN_ARMOR,   "dungeon_reduce_desc",               GetDungeonReduceDesc)
end

return HumanArmorPropertyDescKeyParser