--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanWeaponAttachmentMiscIni = {}

HumanWeaponAttachmentMiscIni.szFileName = "common/ffa/item/human_weaponattachment/attachment_misc.ini"

function HumanWeaponAttachmentMiscIni:OnParse(Parser)
    self.tbSilencerIds = Parser:Get("sight", "silencer_ids", {}, Parser.TypeArrayNumber)
end

return HumanWeaponAttachmentMiscIni
