local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattlePlayerStateRepProcessor = luaclass("BattlePlayerStateRepProcessor", NetMessageProcessorBase)


local NetworkManager = dynamic_require("NetworkManager")


-- 注册处理包
function BattlePlayerStateRepProcessor:RegisterPackets()

end

-- 初始化
function BattlePlayerStateRepProcessor:Init()
    BattlePlayerStateRepProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

return BattlePlayerStateRepProcessor