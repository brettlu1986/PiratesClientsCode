-----------------------------------------------------
--File Name    : FashionItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-03-19
--Description  : 时装的配置表读取helper
-----------------------------------------------------
local FashionItemDataTableHelper = {}

function FashionItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nFashionId        = Parser:Get("fashion_id",            -1,     Parser.TypeInt)
    NewTemplate.nFashionType      = Parser:Get("fashion_type",       false,     Parser.TypeInt)
    NewTemplate.nSourceType       = Parser:Get("source_type",           -1,     Parser.TypeInt)
    NewTemplate.bShowLevel        = Parser:Get("show_level",          true,     Parser.TypeBool)
    NewTemplate.tbOverlaySlots    = Parser:Get("overlay_slots",         {},     Parser.TypeArrayInt)
    NewTemplate.tbEffects         = Parser:Get("effect",                {},     Parser.TypeArrayInt)
    NewTemplate.nSuitId           = nil -- 在PostProcessBlackboardData设置
end

function FashionItemDataTableHelper.PostProcessBlackboardData(tbSelfCategoryTemplates, tbOutBlackboardData)
    local tbFashionToSuit = tbOutBlackboardData.tbFashionToSuit
    for nFashionItemTemplateId, nSuitId in pairs(tbFashionToSuit) do
        local tbFashionItemTemplate = tbSelfCategoryTemplates[nFashionItemTemplateId]
        tbFashionItemTemplate.nSuitId = nSuitId
    end
end


return FashionItemDataTableHelper