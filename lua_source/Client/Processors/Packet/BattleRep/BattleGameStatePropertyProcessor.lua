local luaclass = require("luaclass")
local MessageProcessorBaseClass = require("MessageProcessorBase")
local BattleGameStatePropertyProcessor = luaclass("BattleGameStatePropertyProcessor", MessageProcessorBaseClass)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")

BattleGameStatePropertyProcessor.tbGameStatePropertyBinder = nil
BattleGameStatePropertyProcessor.tbPacketMethods = nil
BattleGameStatePropertyProcessor.EventHelper = nil
BattleGameStatePropertyProcessor.tbCompositeEventHandle = nil

local function OnGameStateReadyAndUIBindedHandle(self)
    self:SetBinder(BattleGameModeSystem:GetGameStatePropertyBinder())
    self:RegisterPackets()
end

-- 注册处理包
function BattleGameStatePropertyProcessor:RegisterPackets()
end

function BattleGameStatePropertyProcessor:SetBinder(Binder)
    self.tbGameStatePropertyBinder = Binder
end

function BattleGameStatePropertyProcessor:OnBindEvent()
    --绑定EV_UI_BATTLE_STATE_ENTERED的好处是所有进场景内的初始UI都是在这里BindEvent以及Open的，在该事件后触发RegisterPackets
    --的好处就是UI相关的不用在Open时再判断GameState相关属性是否有值了，仅仅BindEvent时绑定相应Event就可以了（bTriggerIfPropertyValid 设置为true）
    self.tbCompositeEventHandle = self.EventHelper:BeginCompositeAndEvent(self, OnGameStateReadyAndUIBindedHandle)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_ACTOR_CHANNEL_OPEN, self, nil)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_BATTLE_STATE_ENTERED, self, nil)
    self.EventHelper:EndCompositeEvent()
end

function BattleGameStatePropertyProcessor:OnUnbindEvent()
    if self.EventHelper ~= nil then
        if self.tbCompositeEventHandle then
            self.EventHelper:UnRegisterComposite(self.tbCompositeEventHandle)
            self.tbCompositeEventHandle = nil
        end

        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

function BattleGameStatePropertyProcessor:Init()
    self.tbPacketMethods = {}
    self.EventHelper = SelfEventHelper()

    self:OnBindEvent()

    return true
end

function BattleGameStatePropertyProcessor:Uninit()
    self:UnbindAll()
    self:OnUnbindEvent()
end

function BattleGameStatePropertyProcessor:Bind(Key, Class, Method, bTriggerIfPropertyValid)
    if(self.tbPacketMethods[Key]) then
        error("Bind failed, duplicated packet id " .. Key)
        return
    end
    self.tbGameStatePropertyBinder:Bind(Key, Class, Method, bTriggerIfPropertyValid)
    self.tbPacketMethods[Key] = true
end

function BattleGameStatePropertyProcessor:UnbindAll()
    if self.tbGameStatePropertyBinder then
        self.tbGameStatePropertyBinder:RemoveAllMethodByOwner(self)    
    end

    self.tbPacketMethods = {}
end

return BattleGameStatePropertyProcessor
