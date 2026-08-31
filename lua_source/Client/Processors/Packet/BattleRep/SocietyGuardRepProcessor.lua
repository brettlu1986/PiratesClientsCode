local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local SocietyGuardRepProcessor = luaclass("SocietyGuardRepProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonRepProtoNames")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")

-- 注册处理包
function SocietyGuardRepProcessor:RegisterPackets()
    self:BindMethod(Proto.rSocietyGuardCountdownTipInfo, self, self.OnSocietyGuardCountdownTipInfo)
end

-- 初始化
function SocietyGuardRepProcessor:Init()
    SocietyGuardRepProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

function SocietyGuardRepProcessor:OnSocietyGuardCountdownTipInfo(tbPacket)
    UIUtils.ShowToast(L10N:Format(UITextDef.NEXT_STAGE_COUNT_DOWN , tbPacket.nNextStageSecond))

end

return SocietyGuardRepProcessor
