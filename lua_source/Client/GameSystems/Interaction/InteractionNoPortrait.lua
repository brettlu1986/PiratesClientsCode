--File Name    : InteractionNoPortrait.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-08
--Description  : 无半身像UI
-----------------------------------------------------

local luaclass = require("luaclass")
local InteractionBase = require("InteractionBase")
local InteractionNoPortrait = luaclass("InteractionNoPortrait", InteractionBase)
local InteractionDef = require("InteractionDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

InteractionNoPortrait.nInteractionType = InteractionDef.InteractionMode.UI_NO_PORTRAIT
InteractionNoPortrait.bIsShowAvatar = false 

function InteractionNoPortrait:DoInteraction(tbSelectedNpc, tbParams)
    InteractionNoPortrait.super.DoInteraction(self, tbSelectedNpc, tbParams)
    self:StopMove()
    self:CloseAllUI()
    -- UIManager:CloseWnd(UIDef.UI_MAIN)
    UIManager:OpenWnd(UIDef.UI_INTERACTION, {tbSelectedNpc = tbSelectedNpc, tbParams = tbParams, bIsShowAvatar = self.bIsShowAvatar})
    if tbSelectedNpc and tbSelectedNpc:IsHuman() and not GlobalVariableSystem:IsInDungeon() then 
        -- UEClientActorHelper:FaceToPlayer(tbSelectedNpc.pUEActor)
        tbSelectedNpc:FaceToPlayer()
    end 
end

function InteractionNoPortrait:RefreshInteractionData(tbParams)
    local tbInteractionWnd = UIManager:GetWnd(UIDef.UI_INTERACTION)
    if tbInteractionWnd then 
        tbInteractionWnd:RefreshDialog(tbParams)
    else 
        local tbSelectedNpc = self:GetSelectNpc()
        UIManager:OpenWnd(UIDef.UI_INTERACTION, {tbSelectedNpc = tbSelectedNpc, tbParams = tbParams, bIsShowAvatar = self.bIsShowAvatar})
    end 
end 

function InteractionNoPortrait:OnInteractionEnd()
--[[    if self.bNeedSendToServerOnEnd then 
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_QuestDialogComplete)
    end ]]
    -- UIManager:OpenWnd(UIDef.UI_MAIN)
    if not self.bControlUIByState then 
        UIManager:CloseWnd(UIDef.UI_INTERACTION)
    end 
    local tbSelectedNpc = self:GetSelectNpc()
    if tbSelectedNpc and tbSelectedNpc.pUEActor and not tbSelectedNpc:IsShip() and not GlobalVariableSystem:IsInDungeon() then 
        tbSelectedNpc:ResetDefaultRotator() 
    end     
end


return InteractionNoPortrait