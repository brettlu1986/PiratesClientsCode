--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local WorldBossIni = {}
WorldBossIni.szFileName = "common/worldboss/worldboss.ini"

function WorldBossIni:OnParse(Parser)
    local tbDungeon = {}
    tbDungeon.nEnterNums    = Parser:Get("dungeon", "enter_nums", -1, Parser.TypeNumber)
    self.tbDungeon = tbDungeon
    local tbWorldboss = {}
    tbWorldboss.nDuration = Parser:Get("worldboss", "enter_past_time", -1, Parser.TypeNumber)
    self.tbWorldboss = tbWorldboss
end


return WorldBossIni