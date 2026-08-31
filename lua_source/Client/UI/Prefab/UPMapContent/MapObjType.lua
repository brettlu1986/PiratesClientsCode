-----------------------------------------------------
--File Name    : MapObjType.lua
--Author       : Ran Jie
--Create Time  : 2017-8-10
--Description  : MapObjType
-----------------------------------------------------
local UIDef = require("UIDef")

local MapObjType =
{
    PLAYER = 1,
    NPC = 2,
    QUEST_NPC = 3,
    GATHER_NPC = 4,
    STATIC = 5,
    AI_NPC = 6,
    STATIC_TRANSFER_POINT = 7,
    GO_PATH = 8,
    SPECIAL_GO = 9,
    FFA_TEAM_MEMBER = 10,
    FFA_FLAG_INFO = 11,
    FFA_FLAG_POINT = 12,
    GAME_OBJECT_POINT = 13,
    OTHER = 20,
    AIR_DROP = 21,
    BORN_POINT = 22,
    BOT = 23,
    BOT_POINT = 24,
    CORE_AREA = 25,
    SELF_BORN_POINT = 26,
    PORT_MARK = 27,
}

local MapObjPrefabName =
{
    [MapObjType.PLAYER] = UIDef.UP_MAP_OBJ_PLAYER,
    [MapObjType.AI_NPC] = UIDef.UP_MAP_OBJ_AI_NPC,
    [MapObjType.GO_PATH] = UIDef.UP_MAP_OBJ_FOR_GO_PATH,
    [MapObjType.SPECIAL_GO] = UIDef.UP_MAP_OBJ_FOR_SPECIAL_GO,
    [MapObjType.STATIC] = UIDef.UP_MAP_OBJ_FOR_FFA_STATIC_POINT,
    [MapObjType.FFA_TEAM_MEMBER] = UIDef.UP_MAP_OBJ_FOR_FFA_TEAM_MEMBER,
    [MapObjType.FFA_FLAG_INFO] = UIDef.UP_MAP_OBJ_FOR_FFA_FLAG_INFO,
    [MapObjType.FFA_FLAG_POINT] = UIDef.UP_MAP_OBJ_FOR_FFA_FLAG_POINT,
    [MapObjType.AIR_DROP] = UIDef.UP_MAP_OBJ,
    [MapObjType.BORN_POINT] = UIDef.UP_MAP_OBJ_FOR_BORN_POINT,
    [MapObjType.BOT] = UIDef.UP_MAP_OBJ_FOR_BOT,
    [MapObjType.BOT_POINT] = UIDef.UP_MAP_OBJ_FOR_BOT_POINT,
    [MapObjType.CORE_AREA] = UIDef.UP_MAP_OBJ_FOR_CORE_AREA,
    [MapObjType.SELF_BORN_POINT] = UIDef.UP_MAP_OBJ_FOR_SELF_BORN_POINT,
    [MapObjType.GAME_OBJECT_POINT] = UIDef.UP_MAP_OBJ,
    [MapObjType.PORT_MARK] = UIDef.UP_MAP_OBJ_PORT_MARK,
}


function MapObjType:GetPrefabByType(nObjType, bMMap)
    local szPrefabName = MapObjPrefabName[nObjType]

    if not szPrefabName then
        -- if bMMap then
        --     szPrefabName = UIDef.UP_WORLD_MAP_OBJ
        -- else
            szPrefabName = UIDef.UP_MAP_OBJ
        --end
    end
    return  szPrefabName
end


return MapObjType



