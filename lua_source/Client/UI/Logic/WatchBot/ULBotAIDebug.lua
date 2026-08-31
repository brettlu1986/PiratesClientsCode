-----------------------------------------------------
--File Name    : ULBotAIDebug.lua
--Description  : 战斗组队列表
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBotAIDebug = luaclass("ULBotAIDebug", UILogicBase)
local StringUtil = require("StringUtil")
local ClientEventDef = require("ClientEventDef")

local VISIBLE = ESlateVisibility.Visible
local COLLAPSED = ESlateVisibility.Collapsed
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible

ULBotAIDebug.pTxtMessage = nil
ULBotAIDebug.pScroll = nil
ULBotAIDebug.bShow = false
ULBotAIDebug.tbDebugParam = nil

local function ConvertTableToJsonString(tbToPrint)
    local json = require("dkjson")
    return json.encode(tbToPrint, { indent = true })
end

function ULBotAIDebug:RefreshInfo(tbPacket)
    if self.bShow then
        local tbInfoToShow = tbPacket
        if self.tbDebugParam then
            for i,v in ipairs(self.tbDebugParam) do
                tbInfoToShow = tbInfoToShow[v]
                if not tbInfoToShow then
                    break
                end
            end
        end
        if tbInfoToShow then
            self.pTxtMessage:SetText(ConvertTableToJsonString(tbInfoToShow))
        end
    end
end

function ULBotAIDebug:OnLoad()
    local pbAIDebug = self.pWidgetRef.pbAIDebug
    pbAIDebug:SetVisibility(SELF_HIT_TEST_INVISIBLE)
    self.pTxtMessage = pbAIDebug.txtMessage
    self.pTxtMessage:SetText("")
    self.pScroll = pbAIDebug.scrollBox
    self.pScroll:SetVisibility(COLLAPSED)
end

local function OnClickedBtnShow(self)
    self.bShow = not self.bShow
    self.pScroll:SetVisibility(self.bShow and VISIBLE or COLLAPSED)
end

function ULBotAIDebug:OnDebugParamChange(szParam)
    if not szParam or szParam == "" then
        self.tbDebugParam = nil
    else
        self.tbDebugParam = StringUtil.Split(szParam, '.')
    end

end

function ULBotAIDebug:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.pbAIDebug.btnShow.OnClicked, self, OnClickedBtnShow)
    EventHelper:RegisterEvent(ClientEventDef.EV_AIDBUEG_PARAM, self, self.OnDebugParamChange)
end

function ULBotAIDebug:OnUnbindEvent(EventHelper)

end

return ULBotAIDebug