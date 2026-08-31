local UIDialogQuitDungeonHelper = {}

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local UITextDef = require("UITextDef")

local tbMap = {
    [DungeonQuitDialogType.Escort]              = { UITextDef.ESCORT_QUIT_DUNGEON_TITLE, UITextDef.ESCORT_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.ArenaDead]           = { UITextDef.ARENA_QUIT_DUNGEON_TITLE, UITextDef.ARENA_DEAD_QUIT_DUNGEON_MESSAGE, UITextDef.ARENA_TUTORIAL_FORBID_QUIT },
    [DungeonQuitDialogType.ArenaAlive]          = { UITextDef.ARENA_QUIT_DUNGEON_TITLE, UITextDef.ARENA_ALIVE_QUIT_DUNGEON_MESSAGE, UITextDef.ARENA_TUTORIAL_FORBID_QUIT },
    [DungeonQuitDialogType.PVE01]               = { UITextDef.PVE01_QUIT_DUNGEON_TITLE, UITextDef.PVE01_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.PVE02]               = { UITextDef.PVE02_QUIT_DUNGEON_TITLE, UITextDef.PVE02_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.Smuggle]             = { UITextDef.SMUGGLE_QUIT_DUNGEON_TITLE, UITextDef.SMUGGLE_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.SocietyExplorer]     = { UITextDef.SOCIETY_EXPLORER_QUIT_DUNGEON_TITLE, UITextDef.SOCIETY_EXPLORER_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.SocietyPrivateer]    = { UITextDef.SOCIETY_PRIVATEER_QUIT_DUNGEON_TITLE, UITextDef.SOCIETY_PRIVATEER_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.SocietyGuard]        = { UITextDef.SOCIETY_GUARD_QUIT_DUNGEON_TITLE, UITextDef.SOCIETY_GUARD_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.SideQuest01]         = { UITextDef.SIDE_QUEST_01_QUIT_DUNGEON_TITLE, UITextDef.SIDE_QUEST_01_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.JsonPVE]             = { UITextDef.JSONPVE_QUIT_DUNGEON_TITLE, UITextDef.JSONPVE_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.Faction]             = { UITextDef.FACTION_QUIT_DUNGEON_TITLE, UITextDef.FACTION_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.Provocative]         = { UITextDef.PROVOCATIVE_QUIT_DUNGEON_TITLE, UITextDef.PROVOCATIVE_QUIT_DUNGEON_MESSAGE, UITextDef.PROVOCATIVE_QUIT_DUNGEON_LIMIT_MESSAGE },
    [DungeonQuitDialogType.DungeonPVE]          = { UITextDef.DUNGEONPVE_QUIT_DUNGEON_TITLE, UITextDef.DUNGEONPVE_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.CaptureFlag]         = { UITextDef.CAPTUREFLAG_QUIT_DUNGEON_TITLE, UITextDef.CAPTUREFLAG_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.Conquest]            = { UITextDef.CONQUEST_QUIT_DUNGEON_TITLE, UITextDef.CONQUEST_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.Association]         = { UITextDef.ASSOCIATION_QUIT_DUNGEON_TITLE, UITextDef.ASSOCIATION_QUIT_DUNGEON_MESSAGE }, 
    [DungeonQuitDialogType.WorldBoss]           = { UITextDef.WORLDBOSS_QUIT_DUNGEON_TITLE, UITextDef.WORLDBOSS_QUIT_DUNGEON_MESSAGE }, 
    [DungeonQuitDialogType.GuildBoss]           = { UITextDef.GUILDBOSS_QUIT_DUNGEON_TITLE, UITextDef.GUILDBOSS_QUIT_DUNGEON_MESSAGE }, 
    [DungeonQuitDialogType.ActivityPVE]         = { UITextDef.ACTIVITYPVE_QUIT_DUNGEON_TITLE, UITextDef.ACTIVITYPVE_QUIT_DUNGEON_MESSAGE }, 
    [DungeonQuitDialogType.FFA]                 = { UITextDef.FFA_QUIT_DUNGEON_TITLE, UITextDef.FFA_QUIT_DUNGEON_MESSAGE },
    [DungeonQuitDialogType.TrainingCamp]        = { UITextDef.FFA_QUIT_DUNGEON_TITLE, UITextDef.FFA_QUIT_TRAININGCAMP_DUNGEON_MESSAGE },
}

function UIDialogQuitDungeonHelper:GetDungeonQuitDialogTitle(nDungeonQuitDialogType)
    local tbQuitDialogTexts = tbMap[nDungeonQuitDialogType]
    if tbQuitDialogTexts == nil then
        return nil
    end
    return tbQuitDialogTexts[1]
end

function UIDialogQuitDungeonHelper:GetDungeonQuitDialogMessage(nDungeonQuitDialogType)
    local tbQuitDialogTexts = tbMap[nDungeonQuitDialogType]
    if tbQuitDialogTexts == nil then
        return nil
    end
    return tbQuitDialogTexts[2]
end

function UIDialogQuitDungeonHelper:GetDungeonQuitDialogLimitMessage(nDungeonQuitDialogType)
    local tbQuitDialogTexts = tbMap[nDungeonQuitDialogType]
    if tbQuitDialogTexts == nil then
        return nil
    end
    return tbQuitDialogTexts[3]
end

return UIDialogQuitDungeonHelper