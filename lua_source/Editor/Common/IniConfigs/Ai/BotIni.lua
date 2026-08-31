--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BotIni = {}
BotIni.szFileName = "common/ffa/ai/bot/bot.ini"

function BotIni:OnParse(Parser)
    local tbAttack = {}
    tbAttack.nAttackMinHpHuman =  Parser:Get("attack", "attack_min_hp_human", -1, Parser.TypeNumber)
    tbAttack.nAttackMinHpShip =  Parser:Get("attack", "attack_min_hp_ship", -1, Parser.TypeNumber)
    self.tbAttack = tbAttack

    local tbSearchResource = {}
    tbSearchResource.nHumanSearchRadius = Parser:Get("searchresource", "human_search_radius", -1, Parser.TypeNumber)
    tbSearchResource.nShipSearchRadius = Parser:Get("searchresource", "ship_search_radius", -1, Parser.TypeNumber)
    tbSearchResource.nGroupedHumanSearchRadius = Parser:Get("searchresource", "grouped_human_search_radius", -1, Parser.TypeNumber)
    tbSearchResource.nGroupedShipSearchRadius = Parser:Get("searchresource", "grouped_ship_search_radius", -1, Parser.TypeNumber)
    self.tbInventory = tbSearchResource

    local tbSpawnInfo = {}
    tbSpawnInfo.nInterval   = Parser:Get("spawn", "spawn_interval", -1, Parser.TypeNumber)
    tbSpawnInfo.nBatchCount = Parser:Get("spawn", "spawn_count_perbatch", -1, Parser.TypeNumber)
    self.tbSpawnInfo = tbSpawnInfo

    local tbSearchEnemyInfo = {}
    tbSearchEnemyInfo.nHumanRadius   = Parser:Get("searchenemy", "human_radius", -1, Parser.TypeNumber)
    tbSearchEnemyInfo.nShipRadius   = Parser:Get("searchenemy", "ship_radius", -1, Parser.TypeNumber)
    self.tbSearchEnemyInfo = tbSearchEnemyInfo


    local tbGroupedInfo = {}
    tbGroupedInfo.nHumanGroupDistance =  Parser:Get("group", "human_distance", -1, Parser.TypeNumber)
    tbGroupedInfo.nShipGroupDistance =  Parser:Get("group", "ship_distance", -1, Parser.TypeNumber)
    self.tbGrouped = tbGroupedInfo

    self.nInitAttackIntention = Parser:Get("attackintention", "init_intention", -1, Parser.TypeNumber)
    local tbAttackIntention = {}
    for i=1,15 do
        local nIntention = Parser:Get("attackintention", "intention_" .. i, -1, Parser.TypeNumber)
        if nIntention < 0 then
            break
        else
            tbAttackIntention[i] = nIntention
        end
    end
    self.tbAttackIntention = tbAttackIntention

end

return BotIni
