-----------------------------------------------------
--File Name    : HeadInfoComponent.lua
--Author       : zuo kun
--Create Time  : 2017-03-02
--Description  : NPC头顶信息UI
-----------------------------------------------------

local luaclass = require("luaclass")
local WidgetComponentBase = require("WidgetComponentBase")
local HeadInfoComponentBase = luaclass("HeadInfoComponentBase", WidgetComponentBase)
local SelfPrefabHelper = require("SelfPrefabHelper")
local SelfEventHelper = require("SelfEventHelper")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GameWorldSystem = dynamic_require("GameWorldSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local PlayerCullDistanceIni = require("PlayerCullDistanceIni")
local HeadWidgetLevelDefine =require("HeadWidgetLevelDefine")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local DungeonDataTable = require("DungeonDataTable")

HeadInfoComponentBase.szUEComponentName = "HeadInfo"
HeadInfoComponentBase.szWidgetName = UIDef.UW_HEAD_INFO
HeadInfoComponentBase.PrefabHelper = nil
HeadInfoComponentBase.EventHelper = nil 
HeadInfoComponentBase.tbHeadInfo = nil
HeadInfoComponentBase.tbGirdSolts = {}
HeadInfoComponentBase.tbWidgets = {}

function HeadInfoComponentBase:OnActorCreated(pUEActor)
    HeadInfoComponentBase.super.OnActorCreated(self, pUEActor)
end 

local function CompareGirdSolt(a,b) 
    return a.nPriority > b.nPriority 
end 

function HeadInfoComponentBase:CreateWidgetPrefab( szPrefabName)
    if self.tbWidgets[szPrefabName] or not self.pWidgetRef then 
        return 
    end 

    local pbNewPrefab,_ = self.PrefabHelper:CreatePrefab( szPrefabName )
    local pGirdSolt = self.pWidgetRef.GridPanel_0:AddChildToGrid(pbNewPrefab.pWidgetRef, 0, 0)
    local nInPriority = HeadWidgetLevelDefine[szPrefabName]
    -- pGirdSolt.Row = 0
    pbNewPrefab:WidgetCreated(self)
    self.tbWidgets[szPrefabName] = pbNewPrefab
    table.insert(self.tbGirdSolts, {nPriority = nInPriority, pSlot = pGirdSolt})
    if #self.tbGirdSolts > 1 then 
        table.sort( self.tbGirdSolts, CompareGirdSolt )
        for i,v in ipairs(self.tbGirdSolts) do
            v.pSlot:SetRow(i - 1)
        end
    end 
    
    return pbNewPrefab
end 

function HeadInfoComponentBase:OnWidgetCreated( pWidgetRef )
    if not pWidgetRef then 
        return 
    end 
    if not self.Owner.bVisible then 
        self:SetVisibility(false)
    else 
        self:SetVisibility(true)
    end     
    -- self:SetName(self.Owner.szName)
    -- if self.Owner.ObjectType ~= GameObjectTypeDef.PlayerSelf then 
    --     self:SetSelected(false)
    -- end 

    -- if self.Owner.bIsShip then 
    --     pWidgetRef:K2_AddLocalOffset(Vector{X=0,Y=0,Z=200}, false, nil, false)
    -- end 
    self.pWidgetRef.GridPanel_0:ClearChildren()
    if not self.PrefabHelper then 
        self.PrefabHelper = SelfPrefabHelper()
        self.PrefabHelper:SetWndCreator(UIManager)
        -- self:CreateWidgetPrefab(UIDef.UP_NPC_HEAD_INFO, 0)
        -- self.tbHeadInfo = self[UIDef.UP_NPC_HEAD_INFO]  
        -- self.tbHeadInfo = self.PrefabHelper:BindPrefab(pWidgetRef.pbHeadInfo)
    end 
    if not self.EventHelper then 
        self.EventHelper = SelfEventHelper()
        -- self.EventHelper:RegisterLuaDelegate(self.tbHeadInfo.OnTipsHide, self.OnTipsHide, self)
    end 
    
    local CurrentWorld =  GameWorldSystem:GetWorld()
    if not CurrentWorld then 
        log("HeadInfoComponent CurrentWorld Is Nil")
    end 
    if self.Owner.ObjectType ~= GameObjectTypeDef.PlayerSelf then 
        local pWidgetComponent = self.Owner.pUEActor[self.szUEComponentName]
        if GlobalVariableSystem:IsInDungeon() then 
            pWidgetComponent.ScaleRate = 0
        elseif CurrentWorld and CurrentWorld:IsOcean() then 
            pWidgetComponent.MinDistance = 8000
            pWidgetComponent.MaxDistance = PlayerCullDistanceIni.nDistanceShip
            pWidgetComponent.ScaleRate = PlayerCullDistanceIni.nDistanceShip + 5000
        else 
            pWidgetComponent.MinDistance = 100
            pWidgetComponent.MaxDistance = PlayerCullDistanceIni.nDistanceHuman 
            -- pWidgetComponent.ScaleRate = 8
            pWidgetComponent.ScaleRate = PlayerCullDistanceIni.nDistanceHuman + 2000
        end 

        -- pWidgetComponent.WidgetPanel = pWidgetRef.CanvasPanel_0
    end     

    if GlobalVariableSystem:IsInDungeon() and not GlobalVariableSystem.bShowHeadInfo then
        local nDungeonId = BattleGameModeSystem.nDungeonId 
        if nDungeonId ~= nil then
            local tbDungeonDataTemplate = DungeonDataTable:GetTemplate(nDungeonId)
            if tbDungeonDataTemplate.bControlHeadInfo then 
                self:SetVisibility(false)
            end 
        end 
    end 
end

function HeadInfoComponentBase:SetVisibility(bVisible)
    local CurrentWorld =  GameWorldSystem:GetWorld()
    if not CurrentWorld then 
        log("HeadInfoComponent CurrentWorld Is Nil")
    end     
    local pWidgetComponent = self.Owner.pUEActor[self.szUEComponentName]
    -- if bVisible then 
    --     if CurrentWorld:IsOcean() or self.Owner.pUEActor.RootComponent:IsVisible()then 
    --         pWidgetComponent:SetVisibility(bVisible, false)
    --     end 
    -- else 
    if pWidgetComponent ~= nil then
        pWidgetComponent:SetVisibility(bVisible, false)
        -- end 
        pWidgetComponent:SetComponentTickEnabled(bVisible)
    end
    if self.pWidgetRef then 
        self.pWidgetRef.GridPanel_0:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end 
end 

function HeadInfoComponentBase:GetWidgetPrefab(szWidgetName, bAutoCreate)
    local tbWidgetPrefab = self.tbWidgets[szWidgetName]  
    if not tbWidgetPrefab and bAutoCreate then 
        tbWidgetPrefab = self:CreateWidgetPrefab(szWidgetName)    
        return tbWidgetPrefab 
    end 
    return tbWidgetPrefab 
end 

function HeadInfoComponentBase:SetWidgetVisibility(szWidgetName, bVisible)
    local tbWidgetPrefab = self:GetWidgetPrefab(szWidgetName, bVisible)
    if not tbWidgetPrefab then 
        logerror("Error Widget Name On SetWidgetVisibility " .. szWidgetName)
        return 
    end 
    if not isvalidhandle(self.Owner.pUEActor) then
        return
    end
    local pWidgetComponent = self.Owner.pUEActor[self.szUEComponentName]
    pWidgetComponent:RequestRedraw()
    tbWidgetPrefab.pWidgetRef:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end 

function HeadInfoComponentBase:RequestRedraw()
    local pWidgetComponent = self.Owner.pUEActor[self.szUEComponentName]
    pWidgetComponent:RequestRedraw()
end 

function HeadInfoComponentBase:RefreshWidget(szWidgetName, tbParams)
    local tbWidgetPrefab = self:GetWidgetPrefab(szWidgetName, true)
    if not tbWidgetPrefab then 
        -- logdebug("Error Widget Name On RefreshWidget " .. szWidgetName)
        return 
    end 
    if not isvalidhandle(self.Owner.pUEActor) then
        return
    end
    local pWidgetComponent = self.Owner.pUEActor[self.szUEComponentName]
    pWidgetComponent:RequestRedraw()
    tbWidgetPrefab:RefreshWidget(tbParams)
end 

function HeadInfoComponentBase:OnActorDestroyed(pUEActor)
    for _,v in pairs(self.tbWidgets) do
        v:OnActorDestroyed(pUEActor)
    end
    self.tbWidgets = nil  
    if self.PrefabHelper then 
        self.PrefabHelper:UnbindAllPrefab()
        self.PrefabHelper = nil
    end 
    if self.EventHelper then 
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil   
    end  
    HeadInfoComponentBase.super.OnActorDestroyed(self, pUEActor)
end

function HeadInfoComponentBase:SetSelected( bSelected )
    self.pWidgetRef:SetVisibility(bSelected and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    self.tbHeadInfo.pWidgetRef:SetVisibility(bSelected and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

function HeadInfoComponentBase:SetTipText( szText , szPortraitPath)
    -- self.pWidgetRef.txtName:SetVisibility(ESlateVisibility.Collapsed)
    self.tbHeadInfo:SetTipText(szText, szPortraitPath)
end

function HeadInfoComponentBase:SetHeadInfo(nQuestType)
    self.tbHeadInfo:SetHeadInfo(nQuestType)
end

function HeadInfoComponentBase:OnTipsHide()
    -- self.pWidgetRef.txtName:SetVisibility(ESlateVisibility.Visible)
end 

return HeadInfoComponentBase
