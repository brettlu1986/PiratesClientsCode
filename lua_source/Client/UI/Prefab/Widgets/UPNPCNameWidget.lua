-----------------------------------------------------
--File Name    : UPNPCNameWidget.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPNPCNameWidget = luaclass("UPNPCNameWidget", UPWidgetBase)

local UIResourceDef = require("UIResourceDef")

local INIT_STATE_ACTIVE = 2

function UPNPCNameWidget:ResteHeadColor()
    local tbTemplateData = self.OwnerGameObject:GetTemplateData()
    local nInitState = tbTemplateData.nInitState
    local szHeadNameColor = tbTemplateData.szHeadNameColor
    local pHeadNameColor = nil
    if szHeadNameColor then
        pHeadNameColor = KMUMGLibrary.GetSlateColorFromHex(szHeadNameColor)
    else
        pHeadNameColor = UIResourceDef.NPC_HEAD_NAME_COLOR[nInitState]
        if not pHeadNameColor then
            logerror("npc head name color is nil, init state=", nInitState)
            pHeadNameColor = UIResourceDef.NPC_HEAD_NAME_COLOR[1]
        end
    end
    local pTextNameWidget = self.pWidgetRef.txtName
    pTextNameWidget:SetColorAndOpacity(pHeadNameColor)
end

function UPNPCNameWidget:OnWidgetCreated()
    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    if  self.OwnerGameObject.szName ==  "unknown" then
        self.pWidgetRef.txtName:SetText("")
        self.pWidgetRef:SetVisibility(Collapsed)
    else
        self.pWidgetRef:SetVisibility(Visible)
        self.pWidgetRef.txtName:SetText(self.OwnerGameObject.szName)
    end
    local tbTemplateData = self.OwnerGameObject:GetTemplateData()
    local nHeadNameFontSize = tbTemplateData.nHeadNameFontSize
    self:ResteHeadColor()
    local pTextNameWidget = self.pWidgetRef.txtName
    if nHeadNameFontSize then
        local pFontInfo = pTextNameWidget.Font
        pFontInfo.Size = nHeadNameFontSize
        pTextNameWidget:SetFont(pFontInfo)
    end
    --logdebug("SetNameFontSize,pFontInfo.Size=",pFontInfo.Size)

    -- if self.OwnerGameObject.ti ==  GameObjectTypeDef.PlayerSelf then
    --     self.pWidgetRef.txtName:SetColorAndOpacity(UserNameColor)
    -- elseif  self.OwnerGameObject.ObjectType ==  GameObjectTypeDef.Npc then
    --     self.pWidgetRef.txtName:SetColorAndOpacity(NpcNameColor)
    -- elseif  self.OwnerGameObject.ObjectType ==  GameObjectTypeDef.PlayerOther then
    --     self.pWidgetRef.txtName:SetColorAndOpacity(OtherNameColor)
    -- end

    self:RefreshWidget()
end


function UPNPCNameWidget:RefreshWidget(tbParams)
    local pbAlert = self.pWidgetRef.pbAlert
    if tbParams and tbParams.nAlertLevel then
        local nAlertLevel = tbParams.nAlertLevel
        pbAlert:SetVisibility(nAlertLevel > 0 and ESlateVisibility.SelfHitTestInvisible or
            ESlateVisibility.Collapsed)
        if nAlertLevel > 0 then
            pbAlert:SetPercent(nAlertLevel / 100, 1)
        else
            pbAlert:SetPercent(0)
        end
    end

    if tbParams and tbParams.bBattleState ~= nil then
        if tbParams.bBattleState then
            local pHeadNameColor = UIResourceDef.NPC_HEAD_NAME_COLOR[INIT_STATE_ACTIVE]
            self.pWidgetRef.txtName:SetColorAndOpacity(pHeadNameColor)
            pbAlert:SetVisibility(ESlateVisibility.Collapsed)
        else
            self:ResteHeadColor()
        end
    end
end


return UPNPCNameWidget