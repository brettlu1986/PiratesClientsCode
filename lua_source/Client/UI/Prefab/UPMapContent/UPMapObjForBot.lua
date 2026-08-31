-----------------------------------------------------
--File Name    : UPMapObjForBot.lua
--Author       : Chen Jing
--Create Time  : 2019-05-06
--Description  : 用于在地图上标识Bot
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForBot = luaclass("UPMapObjForBot", UPMapObj)
--local UISetUtils    = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")

local BotStateDef = require("MinimapBotStateDef")
local pDimension = Vector2D{X=16,Y=16}
local szHumamIcon = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_CommonIconBg_04.Spr_CommonIconBg_04'"
local szShipIcon  = "PaperSprite'/Game/UI/Textures/UI_Main/Frames/Spr_distance.Spr_distance'"
local tbStateColor = {
    [BotStateDef.DEAD]      = UIResourceDef.COLOR.BLACK.SLATE_COLOR,
    [BotStateDef.FIGHTING]  = UIResourceDef.COLOR.RED.SLATE_COLOR,
    [BotStateDef.ESCAPING]  = UIResourceDef.COLOR.BLUE3.SLATE_COLOR,
    [BotStateDef.RUNNING]   = UIResourceDef.COLOR.GREEN1.SLATE_COLOR,
    [BotStateDef.DHL]       = UIResourceDef.COLOR.YELLOW.SLATE_COLOR,
    [BotStateDef.BUILDING]  = UIResourceDef.COLOR.ORANGE.SLATE_COLOR,
    [BotStateDef.KEEPGROUP] = UIResourceDef.COLOR.GREEN.SLATE_COLOR,
    [BotStateDef.DYING] = UIResourceDef.COLOR.GREY.SLATE_COLOR,
    [BotStateDef.FALLDEAD]  = UIResourceDef.COLOR.PURPLE.SLATE_COLOR,
    [BotStateDef.POISONDEAD]= UIResourceDef.COLOR.YELLOW.SLATE_COLOR,
    [BotStateDef.DROWNDEAD] = UIResourceDef.COLOR.BLUE3.SLATE_COLOR,
}

UPMapObjForBot.tbData = nil

function UPMapObjForBot:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData.tbBotInfo
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szIcon = ""
    if self.tbData.bIsHuman then
        szIcon = szHumamIcon
    else
        szIcon = szShipIcon
    end
    local pSlateColor = tbStateColor[self.tbData.nState]
    self:SetIcon(szIcon, pDimension, pSlateColor)
    self:SetName(tostring(self.tbData.nBotIndex))
    self.pWidgetRef.Slot:SetPosition(Vector2D{X = tbData.nX, Y = tbData.nY})
    self:SetTeamId(self.tbData.nTeamId)
    self:SetCaptain(self.tbData.bCaptain)
end


function UPMapObjForBot:SetIcon(szIcon, pIconDimension, pSlateColor, bMatchSize)
    if szIcon and szIcon ~= "" then
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UISetUtils.SetAsyncImageBrushFromSprite(self.pWidgetRef.imgIcon, szIcon, pIconDimension, bMatchSize)
        if pSlateColor then
            UISetUtils.SetImageBrushTint(self.pWidgetRef.imgIcon, pSlateColor)
        end
    else
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPMapObjForBot:SetName(szName)
    if szName and szName ~= "" then
        self.pWidgetRef.txtObjName:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.txtObjName:SetText(szName)
    else
        self.pWidgetRef.txtObjName:SetVisibility(ESlateVisibility.Collapsed)
    end
end


function UPMapObjForBot:SetTeamId(nTeamId)
    if nTeamId and nTeamId > 0 then
        self.pWidgetRef.txtTeam:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.txtTeam:SetText(tostring(nTeamId - 1000))
    else
        self.pWidgetRef.txtTeam:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPMapObjForBot:SetCaptain(bCaptain)
    if bCaptain then
        self.pWidgetRef.txtTeam:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
    else
        self.pWidgetRef.txtTeam:SetColorAndOpacity(UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
    end
end

return UPMapObjForBot

