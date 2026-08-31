local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ItemBuffComponent = luaclass("ItemBuffComponent", GameComponentBase)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

ItemBuffComponent.tbItemBuffs = nil

local function OnPlayerDataSync(self, tbPlayerData)
    if tbPlayerData == nil then   
        return 
    end
    local tbData = tbPlayerData.data
    if tbData and tbData.buffs then  
        self:SetItemBuffs(tbData.buffs.buff)
    end
end

function ItemBuffComponent:SetItemBuffs(tbBuffs)
    for _, v in ipairs(tbBuffs) do
        -- logdebug("buff info ", v.id, v.unit)
        self.tbItemBuffs[v.id] = v
    end
end

function ItemBuffComponent:OnCreate(Owner, _)
    ItemBuffComponent.super.OnCreate(self, Owner, _)
    self.tbItemBuffs = {}

    EventManager:BindEventMethod(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    return true
end

function ItemBuffComponent:OnDestroy()
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    self.tbItemBuffs = nil
end

function ItemBuffComponent:ClearItemBuffs()
    self.tbItemBuffs = {}
end

function ItemBuffComponent:GetItemBuffs()
    return self.tbItemBuffs
end

function ItemBuffComponent:GetItemBuff(nId)
    return self.tbItemBuffs[nId]
end


return ItemBuffComponent