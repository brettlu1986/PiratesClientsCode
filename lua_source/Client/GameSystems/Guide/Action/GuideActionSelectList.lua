-----------------------------------------------------
--File Name    : GuideActionSelectList.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionSelectList         = luaclass("GuideActionSelectList", GuideActionFullUIControl)

local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local ClientEventDef    = require("ClientEventDef")
local L10N              = require("L10N")

GuideActionSelectList.ClickDelegate = nil
GuideActionSelectList.ListHelper = nil

local function SetListScrollEnable(self)
    if self.ListHelper then
        self.ListHelper:SetScrollEnabled(true)
    end
end

function GuideActionSelectList:Begin()
    GuideActionSelectList.super.Begin(self)
    local tbTemplate = self.tbTemplate
    local Wnd = UIManager:GetWnd(tbTemplate.szUIName)
    if Wnd == nil or not UIManager:IsWndOpen(tbTemplate.szUIName)then
        self:LogError("wnd nil,uiname="..tostring(tbTemplate.szUIName))
        self:ForceEndCurrentGroup()
        return
    end
    local ScriptRef = Wnd
    
    for k,v in ipairs(tbTemplate.tbPrefabName)do
        ScriptRef = ScriptRef[v]
        if not ScriptRef then
            self:LogError("GuideActionSelectList:Begin,not found prefab,prefab name="..v)
            self:ForceEndCurrentGroup()
            return
        end
    end

    local ListHelper = ScriptRef[tbTemplate.tbWidgetName[1]]
    --self:DebugLog("GuideActionSelectList:Begin,ListHelper="..tostring(ListHelper))
    if not ListHelper then
        self:ForceEndCurrentGroup()
        return
    end
    local nScrollIndex = nil
    local nLineCount = 1
    self.ListHelper = ListHelper
    if ListHelper.pListRef.CellInLineCount ~= nil then
        nLineCount = ListHelper.pListRef.CellInLineCount
    end

    if tbTemplate.szUIName == UIDef.UI_TRADE or tbTemplate.szUIName == UIDef.UI_PRICING_LIST then
        local tbListData = tbTemplate.tbListData
        for k, tbCargo in pairs(ListHelper.tbDataList)do
            if(tbCargo.nGenre == tbListData[1] and tbCargo.nDetailType == tbListData[2] and 
            tbCargo.nParticular == tbListData[3])then
                nScrollIndex = k
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_SHIP_CABIN or tbTemplate.szUIName == UIDef.UI_BACKPACK then
		local tbListData = tbTemplate.tbListData
        for k,tbCargo in pairs(ListHelper.tbDataList)do
            if(tbCargo.tbTemplate ~= nil and tbCargo.tbTemplate.nGenre == tbListData[1] and 
            tbCargo.tbTemplate.nDetailType == tbListData[2] and 
            tbCargo.tbTemplate.nParticular == tbListData[3])then
                nScrollIndex = k
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_ACTIVE_LIVENESS_NEW then
        for k,tbData in pairs(ListHelper.tbDataList)do
            if tbData.nId == tbTemplate.tbListData[1] then
                nScrollIndex = k
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_OWNED_SHIP_OPTION and tbTemplate.tbListData ~= nil then
        for k,tbData in pairs(ListHelper.tbDataList)do
            if tbData.nShipTemplateId == tbTemplate.tbListData[1] then
                nScrollIndex = k
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_FRIEND_MAIN and tbTemplate.tbListData ~= nil then
        for k, tbData in ipairs(ListHelper.tbDataList)do
            if not tbData.undonatable and tbData.is_online then
                nScrollIndex = k
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_SEASON_BATTLEPASS and tbTemplate.tbListData ~= nil then
        self:DebugLog("UI_SEASON_BATTLEPASS SelectList " .. "SelectId = " .. tbTemplate.tbListData[1])
        for k, tbData in ipairs(ListHelper.tbDataList)do
            self:DebugLog("UI_SEASON_BATTLEPASS SelectList nId="..tbData.nId .. "SelectId" .. tbTemplate.tbListData[1])
            if tbData.nId == tbTemplate.tbListData[1] then
                nScrollIndex = k
                self:DebugLog("UI_SEASON_BATTLEPASS nScrollIndex", nScrollIndex) 
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_LOBBY_SHIP and tbTemplate.tbListData ~= nil then
        self:DebugLog("UI_LOBBY_SHIP SelectList " .. "SelectId" .. tbTemplate.tbListData[1])
        for k, tbData in ipairs(ListHelper.tbDataList)do
            self:DebugLog("UI_LOBBY_SHIP SelectList nId="..tbData.nId .. "SelectId" .. tbTemplate.tbListData[1])
            if tbData.nId == tbTemplate.tbListData[1] then
                nScrollIndex = k
                self:DebugLog("UI_LOBBY_SHIP nScrollIndex = " .. nScrollIndex) 
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_LOBBY_SHIP_HULL and tbTemplate.tbListData ~= nil then
        self:DebugLog("UI_LOBBY_SHIP_HULL SelectList " .. "SelectId" .. tbTemplate.tbListData[1])
        for k, tbData in ipairs(ListHelper.tbDataList)do
            self:DebugLog("UI_LOBBY_SHIP_HULL SelectList nId="..tbData.nId .. "SelectId" .. tbTemplate.tbListData[1])
            if tbData.nId == tbTemplate.tbListData[1] then
                nScrollIndex = k
                self:DebugLog("UI_LOBBY_SHIP_HULL nScrollIndex = " .. nScrollIndex) 
                break
            end
        end
    else
        --logdebug("tbTemplate.szUIName, tbListData=",tbTemplate.szUIName,tbTemplate.tbListData)
        nScrollIndex = self.tbTemplate.tbListIndex[1]
    end
    if not nScrollIndex then
        ListHelper:SetScrollEnabled(true)
        self:ForceEndCurrentGroup()
        return
    end
    ListHelper:SetScrollEnabled(false)
    nScrollIndex = math.ceil(nScrollIndex / nLineCount)
    if tbTemplate.szUIName == UIDef.UI_LOBBY_SHIP or tbTemplate.szUIName == UIDef.UI_PARTNER_MAIN then
        ListHelper:ScrollToIndexTopLeft(nScrollIndex, false)
    else
        ListHelper:ScrollToIndex(nScrollIndex, false)
    end
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_SELECT, self, self.OnSelect)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_ITEM, self, self.OnItemClick)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_MAIN_TASK_VISIBLE, self, self.OnMainTaskVisible)
end

function GuideActionSelectList:End()
    GuideActionSelectList.super.End(self)
end

function GuideActionSelectList:DoAction(tbTemplate)
    GuideActionSelectList.super.DoAction(self, tbTemplate)
    local ListHelper =  self.ListHelper
    local tbWidgetName = self.tbTemplate.tbWidgetName
    local SelectWidget = nil
    if tbTemplate.szUIName == UIDef.UI_TRADE or tbTemplate.szUIName == UIDef.UI_PRICING_LIST then
        local tbListData = tbTemplate.tbListData
        for _,ItemScript in pairs(ListHelper.tbItemList)do
            local tbCargo = ItemScript.tbData
            if tbCargo ~= nil then
                if tbCargo.tbTemplate ~= nil and tbCargo.tbTemplate.nGenre == tbListData[1] and tbCargo.tbTemplate.nDetailType == tbListData[2] and tbCargo.tbTemplate.nParticular == tbListData[3] then
                    SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                    break
                elseif tbCargo.nGenre == tbListData[1] and tbCargo.nDetailType == tbListData[2] and tbCargo.nParticular == tbListData[3] then
                    SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                    break
                end
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_SHIP_CABIN or tbTemplate.szUIName == UIDef.UI_BACKPACK then
		local tbListData = tbTemplate.tbListData
        for _,ItemScript in pairs(ListHelper.tbItemList)do
            local tbCargo = ItemScript.tbData
            if tbCargo ~= nil and tbCargo.tbTemplate ~= nil and tbCargo.tbTemplate.nGenre == tbListData[1] and tbCargo.tbTemplate.nDetailType == tbListData[2] and tbCargo.tbTemplate.nParticular == tbListData[3] then
                SelectWidget = ItemScript.pWidgetRef.bdrPackItem
                break
            end  
    
        end
    elseif tbTemplate.szUIName == UIDef.UI_ACTIVE_LIVENESS_NEW then
        for _,ItemScript in pairs(ListHelper.tbItemList)do
            local tbData = ItemScript.tbData
            if tbData ~= nil and tbData.nId == tbTemplate.tbListData[1] then
                SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                if SelectWidget and SelectWidget:IsVisible() then
                    break
                end
            end  
    
        end
    elseif tbTemplate.szUIName == UIDef.UI_OWNED_SHIP_OPTION and tbTemplate.tbListData ~= nil then
        for _,ItemScript in pairs(ListHelper.tbItemList)do
            local tbData = ItemScript.tbData
            if tbData ~= nil and tbData.nShipTemplateId == tbTemplate.tbListData[1] then
                SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                break
            end  
    
        end
    elseif tbTemplate.szUIName == UIDef.UI_FRIEND_MAIN and tbTemplate.tbListData ~= nil then
        for _, ItemScript in pairs(ListHelper.tbItemList)do
            local tbData = ItemScript.tbData
            if not tbData.undonatable and tbData.is_online then
                SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_SEASON_BATTLEPASS and tbTemplate.tbListData ~= nil then
        self:DebugLog("UI_SEASON_BATTLEPASS SelectList " .. "SelectId = " .. tbTemplate.tbListData[1])
        for _, ItemScript in pairs(ListHelper.tbItemList)do
            local tbData = ItemScript.tbData
            self:DebugLog("UI_SEASON_BATTLEPASS SelectList nId="..tbData.nId .. "SelectId" .. tbTemplate.tbListData[1])
            if tbData.nId == tbTemplate.tbListData[1] then
                SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                self:DebugLog("UI_SEASON_BATTLEPASS SelectWidget=".. tostring(SelectWidget))
                break
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_LOBBY_SHIP and tbTemplate.tbListData ~= nil then
        self:DebugLog("UI_LOBBY_SHIP SelectList ".. "SelectId" .. tbTemplate.tbListData[1])
        for _, ItemScript in pairs(ListHelper.tbItemList)do
            local tbData = ItemScript.tbData
            if tbData then
                self:DebugLog("UI_LOBBY_SHIP SelectList nId="..tbData.nId .. "SelectId" .. tbTemplate.tbListData[1])
                if tbData.nId == tbTemplate.tbListData[1] then
                    SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                    self:DebugLog("UI_LOBBY_SHIP SelectWidget=".. tostring(SelectWidget))
                    break
                end
            end
        end
    elseif tbTemplate.szUIName == UIDef.UI_LOBBY_SHIP_HULL and tbTemplate.tbListData ~= nil then
        self:DebugLog("UI_LOBBY_SHIP_HULL SelectList ".. "SelectId" .. tbTemplate.tbListData[1])
        for _, ItemScript in pairs(ListHelper.tbItemList)do
            local tbData = ItemScript.tbData
            if tbData then
                self:DebugLog("UI_LOBBY_SHIP_HULL SelectList nId="..tbData.nId .. "SelectId" .. tbTemplate.tbListData[1])
                if tbData.nId == tbTemplate.tbListData[1] then
                    SelectWidget = ItemScript.pWidgetRef[tbWidgetName[2]]
                    self:DebugLog("UI_LOBBY_SHIP_HULL SelectWidget=".. tostring(SelectWidget))
                    break
                end
            end
        end
    else
        local tbListIndex = tbTemplate.tbListIndex
        local nListIndexCount = #tbListIndex
        local nParamCount = #tbWidgetName
        local ListItem = nil
        for k,v in pairs(ListHelper.tbItemList)do
            if(v.nIndex == tbListIndex[1])then
                ListItem = v
                break
            end
        end
        if not ListItem then
            self:ForceEndCurrentGroup()
            return 
        end
        SelectWidget = ListItem.pWidgetRef
        if nListIndexCount > 1 then
            local szName = tbWidgetName[2]..tbListIndex[2]
            SelectWidget = (SelectWidget[szName])[tbWidgetName[3]]
        else
            if nParamCount > 1 then
                SelectWidget = SelectWidget[tbWidgetName[2]]
            end
        end
        
    end
    if not SelectWidget then
        self:ForceEndCurrentGroup()
        return
    end
	self.SelectWidget = SelectWidget
    local pGeometry = SelectWidget:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
    --logdebug("GuideActionSelectList:OnDelayTimerFunc,Pos,size=", Pos.X, Pos.Y, Size.X, Size.Y)
    self:CallSetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self)

    if SelectWidget.OnClicked ~= nil then
        if self.ClickDelegate ~= nil then
            self.EventHelper:UnregisterCppDelegate(self.ClickDelegate)
            self.ClickDelegate = nil
        end
        self.ClickDelegate = self.EventHelper:RegisterCppDelegate(SelectWidget.OnClicked, self, self.OnSelect)
    end
end

function GuideActionSelectList:OnSelect()
    self:DebugLog("GuideActionSelectList:OnSelect")
    SetListScrollEnable(self)
    self:EndAction()
end

function GuideActionSelectList:OnItemClick()
    if self.SelectWidget and not self.SelectWidget.OnClicked then
        self:OnSelect()
    end
end

function GuideActionSelectList:OnMainTaskVisible(bHidden)
    local tbTemplate = self.tbTemplate
    if bHidden and tbTemplate.szUIName == UIDef.UI_MAIN and tbTemplate.tbPrefabName ~= nil 
    and tbTemplate.tbPrefabName[1] == "pbMainLeftPanel" then
        self:CloseGuide()
    end
end


return GuideActionSelectList
