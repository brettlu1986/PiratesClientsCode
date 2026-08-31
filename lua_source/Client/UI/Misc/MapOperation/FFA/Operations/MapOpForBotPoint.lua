-----------------------------------------------------
--File Name    : MapOpForBotPoint.lua
--Author       : Chen Jing
--Create Time  : 2019-05-06
--Description  : 机器人
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForBotPoint = luaclass("MapOpForBotPoint",MapOpBase)
local MapObjType = require("MapObjType")
local BotDistributionSystem = dynamic_require("BotDistributionSystem")
--local SelfEventHelperClass = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local BotStateDef = require("MinimapBotStateDef")

MapOpForBotPoint.SelfEventHelper = nil

local function RefreshBotPoint(self)
    self:ResetObjPool(MapObjType.BOT_POINT)
    for k, v in pairs(BotDistributionSystem.tbBotInfos) do
        if v.nState == BotStateDef.ESCAPING or BotStateDef.DHL == v.nState then
            local tbMapObj = self:GetOneObj(MapObjType.BOT_POINT)
            local tbContentData = { }
            local UIPosX, UIPosY = self:CalculateUIMapLocation({X = v.nDestX, Y = v.nDestY })
            tbContentData.szTag = tostring(v.nBotIndex)
            tbContentData.nX = UIPosX
            tbContentData.nY = UIPosY
            tbMapObj:ShowContent(tbContentData)
        end
    end
end


function MapOpForBotPoint:Init(Parent)
    MapOpForBotPoint.super.Init(self, Parent)
    -- local SelfEventHelper = SelfEventHelperClass()
    -- self.SelfEventHelper = SelfEventHelper
    -- SelfEventHelper:RegisterEvent(ClientEventDef.EV_BOT_INFO_UPDATED, self, RefreshBotPoint)
    RefreshBotPoint(self)
end

function MapOpForBotPoint:Uninit()
    MapOpForBotPoint.super.Uninit(self)
    --self.SelfEventHelper:UnregisterAll()
end

function MapOpForBotPoint:Reinit()
    MapOpForBotPoint.super.Reinit(self)
end


function MapOpForBotPoint:BindEvent()
    MapOpForBotPoint.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_BOT_INFO_UPDATED, self, RefreshBotPoint)
end

return MapOpForBotPoint