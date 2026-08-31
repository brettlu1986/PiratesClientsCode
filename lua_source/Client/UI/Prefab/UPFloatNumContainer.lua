-----------------------------------------------------
--File Name    : UPFloatNumContainer.lua
--Author       : lzheng
--Create Time  : 2019-09-25
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFloatNumContainer = luaclass("UPFloatNumContainer", UPFFABase)

local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")

UPFloatNumContainer.tbFloatNums = nil

function UPFloatNumContainer:OnCreate()
    self.tbFloatNums = {}
end

function UPFloatNumContainer:OnDestroy()
end

function UPFloatNumContainer:OnLoad()
end

function UPFloatNumContainer:OnFloatAnimationFinished( tbFinishedFloatNum )
    local nFindIdx = -1
    for i, v in ipairs(self.tbFloatNums) do  
        if v == tbFinishedFloatNum then  
            nFindIdx = i
            break
        end
    end

    if nFindIdx > 0 then  
        tbFinishedFloatNum.pWidgetRef:RemoveFromParent()
        table.remove(self.tbFloatNums, nFindIdx)
    end
end

local function OnCreateFloatNum( self, pWorldLoc, nTextNum, bDestroyPre, szColor, nFontSize )
    local tbFloatNum = self.PrefabHelper:CreatePrefab(UIDef.UP_FLOAT_NUM)
    local tbFloatNums = self.tbFloatNums
    if bDestroyPre then  
        if #tbFloatNums > 0 then  
            local tbPreFloatNum = tbFloatNums[#tbFloatNums]
            tbPreFloatNum.pWidgetRef:RemoveFromParent()
            table.remove(self.tbFloatNums, #tbFloatNums)
        end
    end
    local pObjWidget = tbFloatNum.pWidgetRef
    self.pWidgetRef.cvsPanel:AddChildToCanvas(pObjWidget)
    tbFloatNum:SetOwner(self)
    tbFloatNum:SetFloatNumAndStartLoc(nTextNum, pWorldLoc)
    tbFloatNum:SetFloatNumColor(szColor)
    if nFontSize then  
        tbFloatNum:SetFontSize(nFontSize)
    end
    table.insert(self.tbFloatNums, tbFloatNum)
end

local function OnCreateFloatDamageInfo(self, pWorldLoc, nTextNum, szColor, nFontSize, nHurtTag)
    local tbFloatDamageInfo = self.PrefabHelper:CreatePrefab(UIDef.UP_FLOAT_DAMAGE_INFO)
    local pObjWidget = tbFloatDamageInfo.pWidgetRef
    self.pWidgetRef.cvsPanel:AddChildToCanvas(pObjWidget)
    tbFloatDamageInfo:SetOwner(self)
    tbFloatDamageInfo:SetFloatNumAndStartLoc(nTextNum, pWorldLoc)
    tbFloatDamageInfo:SetFloatNumColor(szColor)
    tbFloatDamageInfo:SetFontSize(nFontSize)
    tbFloatDamageInfo:SetDamageTagIconVisible(nHurtTag)
    table.insert(self.tbFloatNums, tbFloatDamageInfo)
end

function UPFloatNumContainer:OnBindEvent( EventHelper )
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_FLOAT_NUM, self, OnCreateFloatNum)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_FLOAT_DAMAGE_INFO, self, OnCreateFloatDamageInfo)
end

return UPFloatNumContainer
