-----------------------------------------------------
--File Name    : SceneItemPackageDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-10-24
--Description  : 场景中箱子的配置表读取helper
-----------------------------------------------------
local SceneItemPackageDataTableHelper = {}

function SceneItemPackageDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.bRemoveWhenEmpty = Parser:Get("remove_when_empty", false, Parser.TypeBool)
    NewTemplate.bRemoveHighLight = Parser:Get("remove_high_light", false, Parser.TypeBool)
    NewTemplate.bDeadBox = Parser:Get("is_dead_box", false, Parser.TypeBool)
end

return SceneItemPackageDataTableHelper