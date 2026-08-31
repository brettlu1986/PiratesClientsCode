local GameWorldSystem = {}

local GameWorldClass = dynamic_require("GameWorld")
local FactionDataTable = require("FactionDataTable")

GameWorldSystem.CurrentWorld = nil

function GameWorldSystem:Init()

end

function GameWorldSystem:Uninit()
    self:DestroyWorld()
end

function GameWorldSystem:GetWorld()
    return self.CurrentWorld
end

function GameWorldSystem:CreateWorld(tbCreateData)
    log("GameWorldSystem:CreateWorld ")
    self:DestroyWorld()

    local World = GameWorldClass()
    self.CurrentWorld = World   -- 怕Create里会扔Event，其他人接到后可能会去GetWorld，所以这里先设进去了
    if(not World:Create(tbCreateData)) then
        self.CurrentWorld = nil
        logerror("GameWorldSystem:Create faild")
    end
    return self.CurrentWorld
end

function GameWorldSystem:DestroyWorld()
    if(self.CurrentWorld) then
        self.CurrentWorld:Destroy()
        self.CurrentWorld = nil
    else
        log("GameWorldSystem:DestroyWorld not world")
    end
end

function GameWorldSystem:GetBigPortSceneIDByFaction(nFactionID)
    local tbTemplate = FactionDataTable:GetTemplate(nFactionID)
    if tbTemplate then
        return tbTemplate.nTownPortalScene
    else
        logwarning("GetBigPortSceneIDByFaction failed, FactionID is not valid, FactionID =", nFactionID)
        return -1
    end
end

return GameWorldSystem
