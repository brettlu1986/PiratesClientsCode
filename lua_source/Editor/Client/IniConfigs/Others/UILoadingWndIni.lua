--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local UILoadingWndIni = {}
UILoadingWndIni.szFileName = "client/ui/loading_wnd.ini"

function UILoadingWndIni:OnParse(Parser)
    local tbLoadingWnd = {}
    tbLoadingWnd.nLoadingTime = Parser:Get("loading_wnd", "min_loading_time", -1, Parser.TypeNumber)
    tbLoadingWnd.nDefaultTipDuration = Parser:Get("loading_wnd", "default_tip_duration", 1, Parser.TypeNumber)
    self.tbLoadingWnd = tbLoadingWnd
end

return UILoadingWndIni
