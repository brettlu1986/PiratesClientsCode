-----------------------------------------------------
--File Name    : UPNpcHeadIconWidget.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPFactionWidget = luaclass("UPFactionWidget", UPWidgetBase)
local UISetUtils = require("UISetUtils")
local FactionDef = require("FactionDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DungeonDataTable = require("DungeonDataTable")
local DungeonTypeDefine = require("DungeonTypeDefine")
local UIResourceDef = require("UIResourceDef")

function UPFactionWidget:OnWidgetCreated()
    self:RefreshWidget()
end

function UPFactionWidget:RefreshWidget(tbParams)
    local bShow = true
    if GlobalVariableSystem:IsInDungeon() then 
        bShow = false
        -- local nDungeonID = BattleGameModeSystem:GetGameState().rGameStateBaseInfo.nDungeonId
        local nDungeonID = BattleGameModeSystem.nDungeonId
        local tbDungeon = DungeonDataTable:GetTemplate(nDungeonID)
        if tbDungeon and tbDungeon.nType == DungeonTypeDefine.PVE then 
            bShow = true 
        end 
    end 
    local FactionComponent = self.OwnerGameObject.FactionComponent

    if not bShow or not FactionComponent then 
        self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
        return 
    end 
    
    local nFactionID = FactionComponent:GetCurrentFactionID()
    if nFactionID == FactionDef.Type.FACTION_NONE then 
        self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
    else 
        self:SetIcon(UIResourceDef.tbFactionIcons[nFactionID])
    end 
end 


function UPFactionWidget:SetIcon(szRes)
    local pRes = szRes:load()
    if not pRes then
        self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
        logerror("Error HeadIcon Path  " .. szRes)
        return
    end
    self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Visible)			
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon,pRes)
end 


return UPFactionWidget 