--File Name    : InteractionPortrait.lua
--Author       : Lu Yue
--Create Time  : 2017-06-14
--Description  : 有半身像UI，战斗中用
-----------------------------------------------------

local luaclass = require("luaclass")
local InteractionPortrait = require("InteractionPortrait")
local InteractionBattlePortrait = luaclass("InteractionBattle", InteractionPortrait)
local InteractionDef = require("InteractionDef")

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

InteractionBattlePortrait.nInteractionType = InteractionDef.InteractionMode.UI_BATTLE_PORTRAIT

local function SetAllShipPaused(bPaused)
    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for _, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.SetPaused then
            GameObject:SetPaused(bPaused)
        end
    end
end

function InteractionBattlePortrait:StopMove()
    -- 副本中停船与否按需求各不相同，由玩法逻辑控制
end 

function InteractionBattlePortrait:DoInteraction(tbSelectedNpc, tbParams)
    InteractionBattlePortrait.super.DoInteraction(self, tbSelectedNpc, tbParams)
    SetAllShipPaused(true)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_PORTRAIT_BEGIN)
end

function InteractionBattlePortrait:OnInteractionEnd()
    SetAllShipPaused(false)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_PORTRAIT_END)
end

return InteractionBattlePortrait