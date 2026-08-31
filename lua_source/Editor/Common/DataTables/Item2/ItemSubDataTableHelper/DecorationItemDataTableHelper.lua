-----------------------------------------------------
--File Name    : DecorationItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-03-19
--Description  : 饰品的配置表读取helper
-----------------------------------------------------
local DecorationItemDataTableHelper = {}

local L10N = require("L10N")

function DecorationItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.l10nBgIntro = Parser:Get("bg_intro", L10N.NullString, Parser.TypeL10N)
    NewTemplate.l10nDescAppend = Parser:Get("desc_append", L10N.NullString, Parser.TypeL10N)
    NewTemplate.nBuffId = Parser:Get("buff_id", -1, Parser.TypeInt)
    NewTemplate.nGroupId  = Parser:Get("group_id",  -1, Parser.TypeInt)
    -- NewTemplate.nPropertyComboId  = Parser:Get("property_combo_id",  -1, Parser.TypeInt)
    NewTemplate.nLevel = Parser:Get("upgrade_level",  -1, Parser.TypeInt)
    NewTemplate.nConsumeId = Parser:Get("upgrade_consume_currency_id",  -1, Parser.TypeInt)
    NewTemplate.nConsumeCount = Parser:Get("upgrade_consume_currency_count",  -1, Parser.TypeInt)
    NewTemplate.nNextLevelId = Parser:Get("next_level_decoration_id",  -1, Parser.TypeInt)
    NewTemplate.nSourceType = Parser:Get("source_type", -1, Parser.TypeInt)
end

return DecorationItemDataTableHelper