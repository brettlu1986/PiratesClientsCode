-----------------------------------------------------
--File Name    : MapOpForBot.lua
--Author       : Chen Jing
--Create Time  : 2019-05-06
--Description  : 机器人
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForBot = luaclass("MapOpForBot",MapOpBase)
local MapObjType = require("MapObjType")
local BotDistributionSystem = dynamic_require("BotDistributionSystem")
--local SelfEventHelperClass = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")

MapOpForBot.SelfEventHelper = nil

local function RefreshBotInfo(self)
    self:ResetObjPool(MapObjType.BOT)
    for k, v in pairs(BotDistributionSystem.tbBotInfos) do
        local tbMapObj = self:GetOneObj(MapObjType.BOT)
        local tbContentData = { }
        local UIPosX, UIPosY = self:CalculateUIMapLocation({X = v.nX, Y = v.nY })
        tbContentData.tbBotInfo = v
        tbContentData.nX = UIPosX
        tbContentData.nY = UIPosY
        tbMapObj:ShowContent(tbContentData)
    end
end


function MapOpForBot:Init(Parent)
    MapOpForBot.super.Init(self, Parent)
    --local SelfEventHelper = SelfEventHelperClass()
    -- self.SelfEventHelper = SelfEventHelper
    -- SelfEventHelper:RegisterEvent(ClientEventDef.EV_BOT_INFO_UPDATED, self, RefreshBotInfo)
    RefreshBotInfo(self)
end

function MapOpForBot:Uninit()
    MapOpForBot.super.Uninit(self)
    --self.SelfEventHelper:UnregisterAll()
end

function MapOpForBot:Reinit()
    MapOpForBot.super.Reinit(self)
end

function MapOpForBot:BindEvent()
    MapOpForBot.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_BOT_INFO_UPDATED, self, RefreshBotInfo)
end


return MapOpForBot