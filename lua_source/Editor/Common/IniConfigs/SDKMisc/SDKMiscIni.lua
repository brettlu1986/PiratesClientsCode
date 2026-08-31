--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local SDKMiscIni = {}
SDKMiscIni.szFileName = "common/channelSdk/SDKMisc.ini"

function SDKMiscIni:OnParse(Parser)
    local tbEGSDK = {}
    tbEGSDK.szfacebookUrl = Parser:Get("EGSDK", "facebook_url", -1, Parser.TypeString)
    tbEGSDK.szchannelName = Parser:Get("EGSDK", "channel_name", -1, Parser.TypeString)
    self.tbEGSDK = tbEGSDK
end

return SDKMiscIni
