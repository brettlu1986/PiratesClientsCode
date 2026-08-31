-----------------------------------------------------
--File Name    : GMIni.lua
--Author       : Song Fuhao
--Create Time  : 2020-03-12
--Description  : GM相关Ini配置
-----------------------------------------------------
local GMIni = {}
GMIni.szFileName = "client/ui/debug/gm.ini"

function GMIni:OnParse(Parser)
    self.nDoubleClickInterval = Parser:Get("open", "double_click_interval", 0.3, Parser.TypeNumber)
    self.nLongPressedInterval = Parser:Get("open", "long_pressed_interval", 10, Parser.TypeNumber)
end

return GMIni
