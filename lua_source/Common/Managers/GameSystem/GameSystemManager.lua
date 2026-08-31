
local GameSystemManager = {}

GameSystemManager.tbSystems = nil

local Binder = require("ManagerGroupChangeBinder")

function GameSystemManager:Init()
    self.tbSystems = {}
    local GameSystemRegister = dynamic_require("GameSystemRegister")
    GameSystemRegister:RegisterSubSystems(self)

    -- 让binder处理
    -- local tbSystems = self.tbSystems
    -- for k, v in pairs(tbSystems) do       
    --     if(v.Init and v:Init() == false) then
    --         return false;
    --     end
    -- end
    return true;
end

function GameSystemManager:Uninit()
    -- local tbSystems = self.tbSystems
    -- if(tbSystems) then
    --     for _, v in pairs(tbSystems) do
    --         if(v.Uninit) then
    --             v:Uninit()
    --         end
    --     end
    -- end
    self.tbSystems = nil
end

function GameSystemManager:Register(nGroupId, SubSystem)
    local tbSystems = self.tbSystems
    for _, v in pairs(tbSystems) do
        if(v == SubSystem) then
            return SubSystem;
        end
    end
    table.insert(tbSystems, SubSystem)
    Binder:Bind(nGroupId, SubSystem)
    return SubSystem
end

function GameSystemManager:Unregister(SubSystem)
    local tbSystems = self.tbWorlds
    for k, v in pairs(tbSystems) do
        if(v == SubSystem) then
            table.remove(tbSystems, k)
        end
    end
end

return GameSystemManager
