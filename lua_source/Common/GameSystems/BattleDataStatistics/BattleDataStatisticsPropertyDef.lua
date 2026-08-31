-----------------------------------------------------
--File Name    : BattleDataStatisticsPropertyDef.lua
--Author       : Chen Jing
--Create Time  : 2018-02-06
--Description  : 战斗内玩家数据统计
-----------------------------------------------------

local BattleDataStatisticsEnum = require("BattleDataStatisticsEnum")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")

local BattleDataStatisticsPropertyDef = {}
BattleDataStatisticsPropertyDef.tbPlayerPropertyDef = {}
BattleDataStatisticsPropertyDef.tbCombatPropertyDef = {}
BattleDataStatisticsPropertyDef.tbTeamPropertyDef   = {}

local function DefinePlayerProperty(szName, nPropertySource, varDefaultValue)
    local tbPlayerProperty = {
        Name = szName,
        PropertySource = nPropertySource,
        DefaultValue = varDefaultValue and varDefaultValue or 0,
    }
    table.insert(BattleDataStatisticsPropertyDef.tbPlayerPropertyDef, tbPlayerProperty)
end

local function DefineCombatProperty(szName, nPropertySource, varDefaultValue)
    local tbCombatProperty = {
        Name = szName,
        PropertySource = nPropertySource,
        DefaultValue = varDefaultValue and varDefaultValue or 0,
    }
    table.insert(BattleDataStatisticsPropertyDef.tbCombatPropertyDef, tbCombatProperty)
end

local function DefineTeamProperty(szName, nPropertySource, varDefaultValue)
    local tbTeamProperty = {
        Name = szName,
        PropertySource = nPropertySource,
        DefaultValue = varDefaultValue and varDefaultValue or 0,
    }
    table.insert(BattleDataStatisticsPropertyDef.tbTeamPropertyDef, tbTeamProperty)
end

-- define player propertry

DefinePlayerProperty(PropertyDef.KILL,                  BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.DEATH,                 BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SHIPKILLSHIP,          BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HUMANKILLHUMAN,        BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.APPLYDAMAGETOSHIP,     BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.APPLYDAMAGETOHUMAN,    BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.APPLYCURETOSHIP,       BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.APPLYCURETOHUMAN,      BattleDataStatisticsEnum.LuaScript)
-- DefinePlayerProperty(PropertyDef.APPLIEDDAMAGE,         BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SHIPAPPLIEDDAMAGE,     BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HUMANAPPLIEDDAMAGE,    BattleDataStatisticsEnum.LuaScript)

DefinePlayerProperty(PropertyDef.SURVIVALTIME,          BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.GAMETIME,              BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SHIPMOVEDISTANCE,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HUMANMOVEDISTANCE,     BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SHIPLAUNCHCOUNT,       BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SHIPHITCOUNT,          BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HUMANLAUNCHCOUNT,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HUMANHITCOUNT,         BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HITSHIPCORECOUNT,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.HITHUMANCORECOUNT,     BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SAVETEAMATECOUNT,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.RESCUINGCOUNT,         BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.MELEEATTACKCOUNT,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.GAMEOVERUSESHIP,       BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.PLAYERRANK,            BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.GRADESCORE,            BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.BATTLESCORE,           BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SURVIVALSCORE,         BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.KILLSCORE,             BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.PAIDREVIVE,            BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.POISONCIRCLELEAVETIME, BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.POISONCIRCLETIME,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.ASSISTCOUNT,           BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.KILLNPC,               BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.SHIPKILLHUMAN,         BattleDataStatisticsEnum.LuaScript)

DefinePlayerProperty(PropertyDef.DIMENSIIONALSURVIVAL,  BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.DIMENSIIONALDAMAGE,    BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.DIMENSIIONALKILL,      BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.DIMENSIIONALASSIST,    BattleDataStatisticsEnum.LuaScript)
DefinePlayerProperty(PropertyDef.DIMENSIIONALITEM,      BattleDataStatisticsEnum.LuaScript)

-- define combat propertry
DefineCombatProperty(PropertyDef.DUNGEONBEGINTIME,      BattleDataStatisticsEnum.LuaScript)
DefineCombatProperty(PropertyDef.DUNGEONELAPSEDTIME,    BattleDataStatisticsEnum.LuaScript)
DefineCombatProperty(PropertyDef.FIRSTAIRDROP,          BattleDataStatisticsEnum.LuaScript)
DefineCombatProperty(PropertyDef.TOTALGRADE,            BattleDataStatisticsEnum.LuaScript)
DefineCombatProperty(PropertyDef.PLAYERCOUNT,           BattleDataStatisticsEnum.LuaScript)

-- define team property
DefineTeamProperty(PropertyDef.TEAMRANK,                BattleDataStatisticsEnum.LuaScript)


return BattleDataStatisticsPropertyDef
