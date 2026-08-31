--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local PointTipsIni = {}
PointTipsIni.szFileName = "client/battlechat/PointTips.Ini"

function PointTipsIni:OnParse(Parser)
    local tbConfig = {}
    local tbShipData = {}  
    tbShipData.nItemPointDistance       = Parser:Get("SHIP", "item_point_distance",     1, Parser.TypeNumber)
    tbShipData.nBoxTriggerLen           = Parser:Get("SHIP", "box_trigger_length",      1, Parser.TypeNumber)
    tbShipData.nLocationPointDistance   = Parser:Get("SHIP", "location_point_distance", 1, Parser.TypeNumber)
    tbConfig.tbShip = tbShipData

    local tbHumanData = {}  
    tbHumanData.nItemPointDistance       = Parser:Get("HUMAN", "item_point_distance",     1, Parser.TypeNumber)
    tbHumanData.nBoxTriggerLen           = Parser:Get("HUMAN", "box_trigger_length",      1, Parser.TypeNumber)
    tbHumanData.nLocationPointDistance   = Parser:Get("HUMAN", "location_point_distance", 1, Parser.TypeNumber)
    tbConfig.tbHuman = tbHumanData

    tbConfig.nPointTipsCount     = Parser:Get("COMMAN", "point_tip_count",           1, Parser.TypeNumber)
    tbConfig.nItemPointTipsCount = Parser:Get("COMMAN", "item_point_tip_count",      1, Parser.TypeNumber)

    tbConfig.nPointTipsShowTime     = Parser:Get("COMMAN", "point_tip_show_time",           1, Parser.TypeNumber)
    tbConfig.nItemPointTipsShowTime = Parser:Get("COMMAN", "item_point_tip_show_time",      1, Parser.TypeNumber)

    self.tbConfig = tbConfig
end

return PointTipsIni
