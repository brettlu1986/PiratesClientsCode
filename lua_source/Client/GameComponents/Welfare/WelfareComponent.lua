local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local WelfareComponent = luaclass("WelfareComponent", GameComponentBase)

local WelfareHelper = require("WelfareHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

WelfareComponent.tbWelfareItems = nil

local function OnPlayerDataSync(self, tbPlayerData)
    WelfareHelper.RequestGetVipAwardDetails()
end

local function OnRefreshWelfareItems(self, tbItems)
    if tbItems ~= nil then   
        self:AddWelfareItems(tbItems)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SHOW_WELFARE)
end

function WelfareComponent:AddWelfareItems(tbItems)
    for _, v in pairs(tbItems) do
        self:AddWelfareItem(v)
    end
end

function WelfareComponent:AddWelfareItem(tbItem)
    self.tbWelfareItems[tbItem.type] = tbItem
end

function WelfareComponent:OnCreate(Owner, _)
    WelfareComponent.super.OnCreate(self, Owner, _)
    self.tbWelfareItems = {}

    EventManager:BindEventMethod(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    EventManager:BindEventMethod(ClientEventDef.EV_REFRESH_WELFARE_DATA, self, OnRefreshWelfareItems)
    
    return true
end

function WelfareComponent:OnDestroy()
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    EventManager:UnBindEventMethod(ClientEventDef.EV_REFRESH_WELFARE_DATA, self, OnRefreshWelfareItems)
    self.tbWelfareItems = nil
end

function WelfareComponent:GetWelfareItem(nType)
    return self.tbWelfareItems[nType]
end

function WelfareComponent:GetWelfareItems()
    return self.tbWelfareItems
end

return WelfareComponent