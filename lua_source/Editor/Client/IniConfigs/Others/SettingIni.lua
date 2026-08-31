--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local SettingIni = {}

local StringUtil = require("StringUtil")

SettingIni.szFileName = "client/setting/setting.ini"

function SettingIni:OnParse(Parser)
    --布局
    local tbLayout = {}
    tbLayout.nScaleDefault          = Parser:Get("layout", "scale_default",             1, Parser.TypeNumber)
    tbLayout.nScaleMin              = Parser:Get("layout", "scale_min",                 1, Parser.TypeNumber)
    tbLayout.nScaleMax              = Parser:Get("layout", "scale_max",                 1, Parser.TypeNumber)
    tbLayout.nAlphaDefault          = Parser:Get("layout", "alpha_default",             1, Parser.TypeNumber)
    tbLayout.nAlphaMin              = Parser:Get("layout", "alpha_min",                 1, Parser.TypeNumber)
    tbLayout.nAlphaMax              = Parser:Get("layout", "alpha_max",                 1, Parser.TypeNumber)
    tbLayout.szBottomMarginWidgets  = Parser:Get("layout", "bottom_margin_widgets",    "", Parser.TypeString)
    tbLayout.tbBottomMarginWidgets  = StringUtil.Split(tbLayout.szBottomMarginWidgets, ",")
    self.tbLayout = tbLayout

    local tbChat = {}
    tbChat.nMaxCount   = Parser:Get("chat", "max_count",    1, Parser.TypeNumber)
    self.tbChat = tbChat

    local tbSense = {}
    tbSense.nMini  = Parser:Get("sensitivity", "mini",    1, Parser.TypeNumber)
    tbSense.nMax   = Parser:Get("sensitivity", "max",    1, Parser.TypeNumber)
    tbSense.nGyroMini  = Parser:Get("sensitivity", "gyro_mini",    1, Parser.TypeNumber)
    tbSense.nGyroMax   = Parser:Get("sensitivity", "gyro_max",    1, Parser.TypeNumber)
    self.tbSense = tbSense

    local tbBrightness = {}
    tbBrightness.nMin              = Parser:Get("brightness", "min",                 1, Parser.TypeNumber)
    tbBrightness.nMax              = Parser:Get("brightness", "max",                 1, Parser.TypeNumber)
    self.tbBrightness = tbBrightness

    local tbMedicineRecommend = {}
    tbMedicineRecommend.nMedicineMin           = Parser:Get("medicine_recommend", "medicine_min",            0.5,  Parser.TypeNumber)
    tbMedicineRecommend.nMedicineMax           = Parser:Get("medicine_recommend", "medicine_max",            0.75, Parser.TypeNumber)
    tbMedicineRecommend.nDrinkMin              = Parser:Get("medicine_recommend", "drink_min",               0.9,  Parser.TypeNumber)
    tbMedicineRecommend.nRecommendDelayTime    = Parser:Get("medicine_recommend", "recomend_delay_time",     60,   Parser.TypeNumber)
    self.tbMedicineRecommend = tbMedicineRecommend

    local tbSailOpacity = {}
    tbSailOpacity.nStepSize         = Parser:Get("sail_opacity", "step_size",       10  ,  Parser.TypeNumber)
    tbSailOpacity.nNormalDefault    = Parser:Get("sail_opacity", "normal_default",  100 ,  Parser.TypeNumber)
    tbSailOpacity.nNormalMax        = Parser:Get("sail_opacity", "normal_max",      90  ,  Parser.TypeNumber)
    tbSailOpacity.nNormalMin        = Parser:Get("sail_opacity", "normal_min",      50  ,  Parser.TypeNumber)
    tbSailOpacity.nFiringDefault    = Parser:Get("sail_opacity", "firing_default",  50  ,  Parser.TypeNumber)
    tbSailOpacity.nFiringMax        = Parser:Get("sail_opacity", "firing_max",      40  ,  Parser.TypeNumber)
    tbSailOpacity.nFiringMin        = Parser:Get("sail_opacity", "firing_min",      0   ,  Parser.TypeNumber)
    self.tbSailOpacity = tbSailOpacity
end

return SettingIni
