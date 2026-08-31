--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local MainMenuIni = {}
MainMenuIni.szFileName = "client/ui/main_menu.ini"

function MainMenuIni:OnParse(Parser)
    local tbMainmenu = {}
    tbMainmenu.nBtnActivityLevel = Parser:Get("main_menu", "open_activity_btn_level", -1, Parser.TypeNumber)
    tbMainmenu.nBtnSatifactionLevel = Parser:Get("main_menu", "open_satifaction_btn_level", -1, Parser.TypeNumber)
    tbMainmenu.szSatfactionUrl  = Parser:Get("main_menu", "satifaction_url", nil, Parser.TypeString)
    tbMainmenu.szCompletionUrl  = Parser:Get("main_menu", "completion_url", nil, Parser.TypeString)
    tbMainmenu.nBtnAssociationLevel = Parser:Get("main_menu", "open_association_btn_level", -1, Parser.TypeNumber)
    self.tbMainmenu = tbMainmenu
end

return MainMenuIni
