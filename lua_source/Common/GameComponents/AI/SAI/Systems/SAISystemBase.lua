
local luaclass = require("luaclass")
local SAISystemBase = luaclass("SAISystemBase")

SAISystemBase.tbOwner  = nil
SAISystemBase.bEnabled = true

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAISystemBase:", ...)
end
-- luacheck: pop

function SAISystemBase:OnConfig(tbConfig)

end


function SAISystemBase:Config(tbConfig)
    self:OnConfig(tbConfig)
end

function SAISystemBase:OnInit()

end

function SAISystemBase:Init(Owner)
    self.tbOwner = Owner
    self:OnInit()
end

function SAISystemBase:OnStart()

end


function SAISystemBase:OnStop()

end

function SAISystemBase:OnUninit()

end


function SAISystemBase:Start()
    if self.bEnabled then
        self:OnStart()
    end
end


function SAISystemBase:Stop()
    if self.bEnabled then
        self:OnStop()
    end
end

function SAISystemBase:Uninit()
    self:OnUninit()
end



return SAISystemBase
