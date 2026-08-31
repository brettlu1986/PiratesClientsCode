-----------------------------------------------------
--File Name    : BattleShipSkinComponent.lua
--Author       : Song Fuhao
--Create Time  : 2019-02-12
--Description  : 舰船时装系统
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local BattleShipSkinComponent = luaclass("BattleShipSkinComponent", GameComponentBase)

local ItemDataTable = require("ItemDataTable")
local ShipResDataTable = require("ShipResDataTable")
local BattleItemDataTable = require("BattleItemDataTable")

BattleShipSkinComponent.tbShipResIdMap = nil

local function Init(self, tbShipSkinIds)
    local tbShipResIdMap = {}
    if tbShipSkinIds then
        for _,nShipSkinId in ipairs(tbShipSkinIds) do
            local tbSkinTemplate = ItemDataTable:GetTemplate(nShipSkinId)
            if tbSkinTemplate then
                local tbShipItemTemplate = ItemDataTable:GetTemplate(tbSkinTemplate.nShipItemId)
                if tbShipItemTemplate then
                    local tbShipBattleItemTemplate = BattleItemDataTable:GetTemplate(tbShipItemTemplate.nBattleItemId)
                    if tbShipBattleItemTemplate then
                        local nShipId = tbShipBattleItemTemplate.nShipId
                        if tbSkinTemplate.nShipResId ~= -1 then
                            tbShipResIdMap[nShipId] = tbSkinTemplate.nShipResId
                        end
                    else
                        logerror("[BattleShipSkinComponent] Cannot find ship battle item template, nShipBattleItemId=" .. tbShipItemTemplate.nBattleItemId)
                    end
                else
                    logerror("[BattleShipSkinComponent] Cannot find ship item template, nShipItemId=" .. tbSkinTemplate.nShipItemId)
                end
            else
                logerror("[BattleShipSkinComponent] Cannot find skin template, nShipSkinId=" .. nShipSkinId)
            end
        end
    end
    self.tbShipResIdMap = tbShipResIdMap
end

function BattleShipSkinComponent:OnCreate(Owner, tbShipSkinIds)
    BattleShipSkinComponent.super.OnCreate(self, Owner, tbShipSkinIds)
    Init(self, tbShipSkinIds)
end

function BattleShipSkinComponent:InitWhenShipPreparationOnClient(tbShipSkinIds)
    Init(self, tbShipSkinIds)
end

function BattleShipSkinComponent:GetShipResId(nShipTemplateId)
    for k,v in pairs(self.tbShipResIdMap) do
        if k == nShipTemplateId then
            return v
        end
    end
    return -1
end

function BattleShipSkinComponent:GetShipResTemplate(nShipTemplateId)
    local nShipResId = self:GetShipResId(nShipTemplateId)
    return ShipResDataTable:GetTemplate(nShipResId)
end

return BattleShipSkinComponent
