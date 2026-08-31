local luaclass = require("luaclass")
local AIPresstestSystem   = luaclass("AIPresstestSystem")

AIPresstestSystem.bEnabled = false
AIPresstestSystem.nNumAgnet = 0

function AIPresstestSystem:Init()

end

function AIPresstestSystem:Enabled()
    return self.bEnabled
end

function AIPresstestSystem:GetNumAgent()
    return self.nNumAgnet
end

function AIPresstestSystem:Uninit()

end

return AIPresstestSystem()