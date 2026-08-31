-----------------------------------------------------
--File Name    : UILobbyTeamOrder.lua
--Description  : 大厅组队预约
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local ClientEventDef = require("ClientEventDef")
local UILobbyTeamOrder = luaclass("UILobbyTeamOrder", WndBase)

UILobbyTeamOrder.tbCachePrefab = nil
UILobbyTeamOrder.tbActiveQuickTips = nil

local ANCHORS = Anchors{Minimum=Vector2D{X=0, Y=0.5}, Maximum=Vector2D{X=0, Y=0.5}}
local Alignment = Vector2D{X = 0, Y = 0.5}
local Position = Vector2D{X = -10, Y = 121}
local Size = Vector2D{X = 500, Y = 220}
local CACHE_COUNT = 3

local function CreateTeamOrderPrefab(self, szUPName)
    local pTargetPrefab = nil
    if self.tbCachePrefab == nil then  
        self.tbCachePrefab = {}
    end

    local tbUPCache = self.tbCachePrefab[szUPName]
    if tbUPCache == nil then tbUPCache = {} end 
    if #tbUPCache == 0 then  
        for i = 1, CACHE_COUNT do  
            local Prefab = self.PrefabHelper:CreatePrefab(szUPName)
            table.insert(tbUPCache, Prefab)
        end
    end
    local nCount = #tbUPCache
    pTargetPrefab = tbUPCache[nCount]
    table.remove(tbUPCache, nCount)

    local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pTargetPrefab.pWidgetRef)
    self.tbCachePrefab[nUniqueId] = tbUPCache
    return pTargetPrefab
end

local function RecycleTeamOrderPrefab(self, pPrefabScript)
    if self.tbCachePrefab == nil then return end

    local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pPrefabScript.pWidgetRef)
    local tbUPCache = self.tbCachePrefab[nUniqueId]

    if(tbUPCache) then
        table.insert(tbUPCache, pPrefabScript)
        self.tbCachePrefab[nUniqueId] = nil
    end
end

local function CheckActiveQuickTips(self, pPrefabScript)
    for i, v in ipairs(self.tbActiveQuickTips) do 
        if pPrefabScript == v then  
            table.remove(self.tbActiveQuickTips, i)
            break
        end
    end

    if #self.tbActiveQuickTips == 0 then 
        self:CloseSelf()
    end
end

function UILobbyTeamOrder:CreateQuickResult(szUIName, tbParam)
    if self.tbActiveQuickTips == nil then self.tbActiveQuickTips = {} end
    local pPrefab = CreateTeamOrderPrefab(self, szUIName)
    local pWidgetRef = pPrefab.pWidgetRef
    self.pWidgetRef.cpTeamOrder:AddChildToCanvas(pWidgetRef)
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.Slot:SetAnchors(ANCHORS)
    pWidgetRef.Slot:SetAlignment(Alignment)
    pWidgetRef.Slot:SetPosition(Position)
    pWidgetRef.Slot:SetSize(Size)

    local fnDeactivate = function(pPrefabScript)
        if pPrefabScript.pWidgetRef then
            pPrefabScript.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
        RecycleTeamOrderPrefab(self, pPrefabScript)
        CheckActiveQuickTips(self, pPrefabScript)
    end
    tbParam.fnDeactivate = fnDeactivate
    pPrefab:Activate(tbParam)
    table.insert(self.tbActiveQuickTips , pPrefab)
end

function UILobbyTeamOrder:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    
end

function UILobbyTeamOrder:OnUnload()
    self.tbCachePrefab = nil
    self.tbActiveQuickTips = nil
end

function UILobbyTeamOrder:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_ORDER_RESULT, self, self.CreateQuickResult) 
end

function UILobbyTeamOrder:OnShow()
end

function UILobbyTeamOrder:OnExit()
    
end

return UILobbyTeamOrder