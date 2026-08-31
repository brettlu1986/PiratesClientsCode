-----------------------------------------------------
--File Name    : UPHumanName.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPNameWidget = luaclass("UPNameWidget", UPWidgetBase)
--local GameObjectTypeDef = require("GameObjectTypeDef")
local FactionDef = require("FactionDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DungeonDataTable = require("DungeonDataTable")
local DungeonTypeDefine = require("DungeonTypeDefine")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")

-- local UserNameColor = SlateColor {SpecifiedColor = LinearColor {R = 0.391573, G = 0.863157, B = 0.124772, A = 1}}
-- local NpcNameColor = SlateColor {SpecifiedColor = LinearColor {R = 0.814847, G = 0.439657, B = 0.141263, A = 1}}
-- local OtherNameColor = SlateColor {SpecifiedColor = LinearColor {R = 1, G = 1, B = 1, A = 1}}

function UPNameWidget:OnWidgetCreated()
    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    if  self.OwnerGameObject.szName ==  "unknown" then 
        self.pWidgetRef.txtName:SetText("")
        self.pWidgetRef:SetVisibility(Collapsed)
    else 
        self.pWidgetRef:SetVisibility(Visible)
        self.pWidgetRef.txtName:SetText(self.OwnerGameObject.szName)
    end 

    -- if self.OwnerGameObject.ObjectType ==  GameObjectTypeDef.PlayerSelf then 
    --     self.pWidgetRef.txtName:SetColorAndOpacity(UserNameColor)
    -- elseif  self.OwnerGameObject.ObjectType ==  GameObjectTypeDef.Npc then 
    --     self.pWidgetRef.txtName:SetColorAndOpacity(NpcNameColor)
    -- elseif  self.OwnerGameObject.ObjectType ==  GameObjectTypeDef.PlayerOther then 
    --     self.pWidgetRef.txtName:SetColorAndOpacity(OtherNameColor)
    -- end 

    -- self:RefreshWidget()
end 


function UPNameWidget:RefreshWidget(tbParams)
    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    local szGuildName = self.OwnerGameObject.GuildComponent and self.OwnerGameObject.GuildComponent:GetGuildName()
    if szGuildName == nil or szGuildName == "" then
        self.pWidgetRef.txtGuildName:SetVisibility(Collapsed)
    else
        self.pWidgetRef.txtGuildName:SetVisibility(Visible)
        self.pWidgetRef.txtGuildName:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("GUILD_NAME"), szGuildName))
    end

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
        self.pWidgetRef.imgFaction:SetVisibility(Collapsed)
        return 
    end 
    
    local nFactionID = FactionComponent:GetCurrentFactionID()
    if nFactionID == FactionDef.Type.FACTION_NONE then 
        self.pWidgetRef.imgFaction:SetVisibility(Collapsed)
    else 
        self:SetIcon(UIResourceDef.tbFactionIcons[nFactionID])
    end 
end 



function UPNameWidget:SetIcon(szRes)
    if not szRes then
        return 
    end 
    local pRes = szRes:load()
    if not pRes then
        self.pWidgetRef.imgFaction:SetVisibility(ESlateVisibility.Collapsed)
        logerror("Error HeadIcon Path  " .. szRes)
        return
    end
    self.pWidgetRef.imgFaction:SetVisibility(ESlateVisibility.Visible)			
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgFaction,pRes)
end 

return UPNameWidget