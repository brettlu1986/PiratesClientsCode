--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local DisplayAwardItemIni = {}
DisplayAwardItemIni.szFileName = "client/ui/display_award_item.ini"

function DisplayAwardItemIni:OnParse(Parser)
    local tbHumanDisplay = {}
    tbHumanDisplay.szActorTag   = Parser:Get("human_display",   "actor_tag",    "",     Parser.TypeString)
    tbHumanDisplay.szCameraTag  = Parser:Get("human_display",   "camera_tag",   "",     Parser.TypeString)
    tbHumanDisplay.szLevelRes   = Parser:Get("human_display",   "level_res",    "",     Parser.TypeString)
    tbHumanDisplay.szEnvCtrlTag = Parser:Get("human_display",   "env_ctrl_tag", "",     Parser.TypeString)
    self.tbHumanDisplay = tbHumanDisplay

    local tbShipDisplay = {}
    tbShipDisplay.szShipAvatarComponent     = Parser:Get("ship_display",    "ship_avatar_component",    "",     Parser.TypeString)
    tbShipDisplay.szLevelRes                = Parser:Get("ship_display",    "level_res",                "",     Parser.TypeString)
    tbShipDisplay.szActorTag                = Parser:Get("ship_display",    "actor_tag",                "",     Parser.TypeString)
    tbShipDisplay.szCameraTag               = Parser:Get("ship_display",    "camera_tag",               "",     Parser.TypeString)
    tbShipDisplay.szEnvCtrlTag              = Parser:Get("ship_display",    "env_ctrl_tag",             "",     Parser.TypeString)
    tbShipDisplay.tbShipFoamsTags           = Parser:Get("ship_display",    "ship_foams_tags",          {},     Parser.TypeArrayString)
    tbShipDisplay.tbShipFoamsRes            = Parser:Get("ship_display",    "ship_foams_res",           {},     Parser.TypeArrayString)
    tbShipDisplay.szShipAnim                = Parser:Get("ship_display",    "ship_anim",                "",     Parser.TypeString)
    tbShipDisplay.szSeaFoamRes              = Parser:Get("ship_display",    "sea_foam_res",             "",     Parser.TypeString)
    tbShipDisplay.szWateringEffect          = Parser:Get("ship_display",    "ship_watering_effect",     "",     Parser.TypeString)
    self.tbShipDisplay = tbShipDisplay
end

return DisplayAwardItemIni
