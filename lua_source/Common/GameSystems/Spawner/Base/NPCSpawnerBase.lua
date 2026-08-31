local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local NPCSpawnerBase = luaclass("NPCSpawnerBase", SpawnerBaseClass)


NPCSpawnerBase.nTemplateId = nil
NPCSpawnerBase.nDifficultyId = nil
NPCSpawnerBase.nCampType = nil
NPCSpawnerBase.nDialogBoardId = nil

function NPCSpawnerBase:OnCreate(tbParams)
    if(not NPCSpawnerBase.super.OnCreate(self, tbParams)) then
        return false
    end

    self.nTemplateId = tbParams.TemplateId
    self.nCampType = tbParams.CampType
    self.nDialogBoardId = tbParams.DialogBoardId or 0
    self.nDifficultyId = tbParams.DifficultyId
    return true
end

return NPCSpawnerBase
