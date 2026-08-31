-----------------------------------------------------
--File Name    : ULLobbyShipPart.lua
--Author       : chenyixin
--Description  : 舰船零件和商城零件舰船展示通用逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipPart = luaclass("ULLobbyShipPart", UILogicBase)

local ItemDataTable = require("ItemDataTable")
local LobbyShipDef = require("LobbyShipDef")

local LobbyShipWndDef = LobbyShipDef.WndDef

local CAPTAIN_CABIN_ACTOR_INDEX = 2
local SHIP_WND_KEY = "Part"

ULLobbyShipPart.OwnerSub = nil
ULLobbyShipPart.bIsDrag = false
ULLobbyShipPart.nLastPosX = 0

ULLobbyShipPart.pShipActor = nil

---------------------------------------
-- Widget事件
---------------------------------------


---------------------------------------
-- life cycle
---------------------------------------
function ULLobbyShipPart:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

---------------------------------------
-- 接口
---------------------------------------
function ULLobbyShipPart:GetShipActor()
    if not self.pShipActor then
        local szWndName = LobbyShipWndDef.tbKeyToWndName[SHIP_WND_KEY]
        local OwnerSub = self.OwnerSub
        local szTag = OwnerSub:GetActorTagByIndex(szWndName, 1)
        self.pShipActor = OwnerSub:GetSubLevelActorByTag(szWndName, szTag)
    end
    return self.pShipActor
end

function ULLobbyShipPart:DisplayPart(nId, bClearDisplay)
    local pShipActor = self:GetShipActor()
    if bClearDisplay then
        self:ClearDisplay()
    end
    local tbTemplate = ItemDataTable:GetTemplate(nId)
    if tbTemplate.szModelRes then
        local pInstanceComponent = pShipActor.ISM_Armor
        if pInstanceComponent then
            pInstanceComponent:SetStaticMesh(tbTemplate.szModelRes:load())
        end
    elseif tbTemplate.szClassRes then
        local pActor = self.OwnerSub:CreateActor(tbTemplate.szClassRes:load(), CAPTAIN_CABIN_ACTOR_INDEX)
        local pCaptainCabin = pShipActor.CaptainCabin
        pActor:K2_AttachToComponent(pCaptainCabin, "", EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget)
    end
end

function ULLobbyShipPart:ClearDisplay()
    local pShipActor = self:GetShipActor()
    local pInstanceComponent = pShipActor.ISM_Armor
    if pInstanceComponent then
        pInstanceComponent:SetStaticMesh(nil)
    end
end

return ULLobbyShipPart