--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local InitItemIni = {}
InitItemIni.szFileName = "common/ffa/initdata/initdata.ini"

function InitItemIni:OnParse(Parser)
    local tbPrepareScene = {}
    tbPrepareScene.nInitItemGroupId = Parser:Get("prepare_scene", "init_item_group_id", -1, Parser.TypeNumber)
    self.tbPrepareScene = tbPrepareScene

    local tbFormalScene = {}
    tbFormalScene.nInitItemGroupId = Parser:Get("formal_scene", "init_item_group_id", -1, Parser.TypeNumber)
    self.tbFormalScene = tbFormalScene

    local tbDeepLearning = {}
    tbDeepLearning.nInitItemGroupId = Parser:Get("deep_learning", "init_item_group_id", -1, Parser.TypeNumber)
    self.tbDeepLearning = tbDeepLearning
end

return InitItemIni
