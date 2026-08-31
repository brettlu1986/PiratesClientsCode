local luaclass = require("luaclass")
local GameCoreSyncSystem   = luaclass("GameCoreSyncSystem")

GameCoreSyncSystem.tbOwner = nil
GameCoreSyncSystem.tbComponents = nil

function GameCoreSyncSystem:Init(tbOwner, tbRegister)
    self.tbOwner = tbOwner
    self.tbComponents = {}
    tbRegister:Register(self)
end

function GameCoreSyncSystem:Register(tbComponentName)
    local tbComponent = require(tbComponentName)()
    tbComponent:Init(self.tbOwner)
    -- tbComponent.szName = tbComponentName
    table.insert(self.tbComponents, tbComponent)
end

function GameCoreSyncSystem:Sync(tbPack)
    for i,v in ipairs(self.tbComponents) do
        v:Sync(tbPack)
    end
end

function GameCoreSyncSystem:Start()
    for i,v in ipairs(self.tbComponents) do
        v:Start()
    end
end

function GameCoreSyncSystem:Stop()
    for i,v in ipairs(self.tbComponents) do
        v:Stop()
    end
end

function GameCoreSyncSystem:Uninit()
    if self.tbComponents then
        for i,v in ipairs(self.tbComponents) do
            v:UnInit()
        end
        self.tbComponents = nil
    end
end


return GameCoreSyncSystem