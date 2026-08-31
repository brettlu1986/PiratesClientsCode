local SceneDataTable = require("SceneDataTable")
local DungeonDataTable = require("DungeonDataTable")
local SoundManager = require("SoundManager")

local BGMHelper = {}

function BGMHelper:PlayDungeonBGM(nDungeonId)
    local nBGMId = DungeonDataTable:GetTemplate(nDungeonId).nBGMId
    SoundManager:PlayBackgroundMusic(nBGMId)
end

function BGMHelper:PlayWildWorldBGM(nSceneId)
    local nBGMId = SceneDataTable:GetTemplate(nSceneId).nBGMId
    SoundManager:PlayBackgroundMusic(nBGMId)
end

return BGMHelper
