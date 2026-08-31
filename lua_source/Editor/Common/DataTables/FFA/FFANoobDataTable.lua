-----------------------------------------------------
--File Name    : FFANoobDataTable.lua
--Author       : LiHui
--Create Time  : 
--Description  : FFA 新手本相关配置，比如新手需要加一些buff
--               以及第一次捡东西需要额外给道具等
-----------------------------------------------------

local FFANoobDataTable = {}
FFANoobDataTable.szFileName = "common/ffa/noob/battle_ffa_noob.tab"

function FFANoobDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nDungeonId")
    Parser:Define("nDungeonId"     , "dungeon_id"                           , -1  , Parser.TypeInt)
    Parser:Define("tbItemIds"      , "first_getitem_item_ids"               , nil , Parser.TypeArrayInt)
    Parser:Define("tbItemCounts"   , "first_getitem_item_counts"            , nil , Parser.TypeArrayInt)
    Parser:Define("tbBuffs"        , "noob_player_add_buffs"                , nil , Parser.TypeArrayInt)
    Parser:Define("tbBuffCounts"   , "noob_player_add_buff_overlapcounts"   , nil , Parser.TypeArrayInt)
end

-- [EXPORT BEGIN]
function FFANoobDataTable:GetTemplate( nDungeonId )
    return self.tbContainer[nDungeonId]
end
-- [EXPORT END]

return FFANoobDataTable
