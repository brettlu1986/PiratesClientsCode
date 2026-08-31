--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanConcealIni = {}
HumanConcealIni.szFileName = "common/ffa/human/human_conceal.ini"

function HumanConcealIni:OnParse(Parser)
    self.tbConcealData = {}

    for i=1,3 do
        local tbConcealDataLevel = {}
        tbConcealDataLevel.nUpRightToConceal    = Parser:Get("human_conceal", "upright_to_conceal_lv" .. i,    0, Parser.TypeNumber)
        tbConcealDataLevel.nUpRightStartConceal = Parser:Get("human_conceal", "upright_start_conceal_lv" .. i, 0, Parser.TypeNumber)
        tbConcealDataLevel.nCrouchToConceal     = Parser:Get("human_conceal", "crouch_to_conceal_lv" .. i,     0, Parser.TypeNumber)
        tbConcealDataLevel.nCrouchStartConceal  = Parser:Get("human_conceal", "crouch_start_conceal_lv" .. i,  0, Parser.TypeNumber)
        tbConcealDataLevel.nCrawlToConceal      = Parser:Get("human_conceal", "crawl_to_conceal_lv" .. i,      0, Parser.TypeNumber)
        tbConcealDataLevel.nCrawlStartConceal   = Parser:Get("human_conceal", "crawl_start_conceal_lv" .. i,   0, Parser.TypeNumber)
        self.tbConcealData[i] = tbConcealDataLevel
    end

    self.nPunishmentTime = Parser:Get("human_conceal", "punishment_time", -1, Parser.TypeNumber)

    self.nAttackPunishmentFactor = Parser:Get("human_conceal", "attack_punishment_factor", -1, Parser.TypeNumber)
    self.nHitPunishmentFactor = Parser:Get("human_conceal", "hit_punishment_factor", -1, Parser.TypeNumber)
    self.nMovePunishmentFactor = Parser:Get("human_conceal", "move_punishment_factor", -1, Parser.TypeNumber)
    self.nProgressPunishmentFactor = Parser:Get("human_conceal", "progress_punishment_factor", -1, Parser.TypeNumber)
    self.nReloadPunishmentFactor = Parser:Get("human_conceal", "reload_punishment_factor", -1, Parser.TypeNumber)

    self.nMaxPunishment = Parser:Get("human_conceal", "max_punishment", -1, Parser.TypeNumber)

    self.nUpRightDelayConceal = Parser:Get("human_conceal", "upright_delay_conceal", -1, Parser.TypeNumber)
    self.nCrouchDelayConceal = Parser:Get("human_conceal", "crouch_delay_conceal", -1, Parser.TypeNumber)
    self.nCrawlDelayConceal = Parser:Get("human_conceal", "crawl_delay_conceal", -1, Parser.TypeNumber)

    self.nCastShadowConceal = Parser:Get("human_conceal", "cast_shadow_conceal", -1, Parser.TypeNumber)
end

return HumanConcealIni
