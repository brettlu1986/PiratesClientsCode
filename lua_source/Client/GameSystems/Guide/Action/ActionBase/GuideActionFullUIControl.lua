-----------------------------------------------------
--File Name    : GuideActionFullUIControl.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionBase           = require("GuideActionBase")
local GuideActionFullUIControl  = luaclass("GuideActionFullUIControl", GuideActionBase)

local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local ClientEventDef        = require("ClientEventDef")
local SoundEffectHelper     = require("SoundEffectHelper")
local DelayTimer            = require("DelayTimer")
-----------------------------------------------------
--member veriable
GuideActionFullUIControl.bStackBack                  = false
-----------------------------------------------------

function GuideActionFullUIControl:Begin()
    GuideActionFullUIControl.super.Begin(self)
    self:IsShowTopUI()
end

function GuideActionFullUIControl:End()
    GuideActionFullUIControl.super.End(self)
    self:StopEffectSound()
end

function GuideActionFullUIControl:BindEvent()
    GuideActionFullUIControl.super.BindEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_SELECT_TAB, self, self.OnSelectTab)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_MANAGER_CLOSE_UI_FINISH, self, self.OnCloseUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_MANAGER_OPEN_UI_FINISH, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_GUIDE_ON_INVITE, self, self.OnLobbyInviteClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, self, self.OnLobbyInviteClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, self, self.OnLobbySystemActivate)
end

function GuideActionFullUIControl:DoAction(tbTemplate)
    GuideActionFullUIControl.super.DoAction(self, tbTemplate)
    self:CallShowSpaceScreen(false)
end

function GuideActionFullUIControl:OnDelayTimerFunc(tbTemplate)
    GuideActionFullUIControl.super.OnDelayTimerFunc(self, tbTemplate)
    self:PlayEffectSound()
end

function GuideActionFullUIControl:RefreshOnGuideWnd()
    self:DebugLog("RefreshOnGuideWnd")
    self:OnDelayTimerFunc(self.tbTemplate)
end

function GuideActionFullUIControl:OnClickAnywhere()
    self:DebugLog("OnClickAnywhere")
    self:ForceEndCurrentStep()
end

function GuideActionFullUIControl:OnTimerFunc()
    self:DebugLog("OnTimerFunc")
    self:ForceEndCurrentStep()
end

function GuideActionFullUIControl:EndAction()
    self:DebugLog("EndAction")
    self:ForceEndCurrentStep()
end

function GuideActionFullUIControl:IsShowTopUI()
    self:DebugLog("IsShowTopUI template ui name " .. self.tbTemplate.szUIName)
    local szUIName = self.tbTemplate.szUIName
    if not szUIName or szUIName == "" then
        return  
    end
    --self:DebugLog(" UIDef.UI_LOBBY_MAIN is top .. " .. tostring(UIManager:IsShowTopUI(UIDef.UI_LOBBY_MAIN)))
    --为了大厅的新逻辑而添加，大厅中有底部菜单按钮这一概念，此按钮会一直保持在最高层级。
    --而引导的需求是，当打开别的任何非大厅界面时，都需要指引底部按钮的引导进行隐藏，所以
    --为了此功能，而单独特殊化处理此界面逻辑
    if szUIName == UIDef.UI_LOBBY_BOTTOM_MENU and UIManager:IsShowTopUI(UIDef.UI_LOBBY_MAIN) then
        self:ActiveGuideWnd(true)
        return
    end
    local bIsTop = UIManager:IsShowTopUI(szUIName)
    self:DebugLog("IsShowTopUI" .. " template ui name " .. self.tbTemplate.szUIName .. " is top = " .. tostring(bIsTop))
    if not bIsTop then
        self:DebugLog("not bIsTop")
        self.bStackBack = true
        self:ActiveGuideWnd(false)
    else
        self:DebugLog("bIsTop")
        self.bStackBack = false
        self:ActiveGuideWnd(true)
    end
end

function GuideActionFullUIControl:ActiveGuideWnd(bActive)
    self:DebugLog("ActiveGuideWnd, bActive = " .. tostring(bActive))
    local GuideWnd = self:GetGuideWnd()
    if not GuideWnd then
        return
    end
    local EventHelper = self.EventHelper
    if bActive then
        self:DebugLog("ActiveGuideWnd GuideWnd.bActivate = " .. tostring(GuideWnd.bActivate))
        if not GuideWnd.bActivate then
            if self.tbTemplate.nDelayTime > 0 then
                self:CloseDelayTimer()
                self.DelayTimerHandle = DelayTimer:DelayRun(function() 
                    EventHelper:FireEvent(ClientEventDef.EV_GUIDE_UI_ACTIVATE, true)
                    self:RefreshOnGuideWnd() end, 
                self.tbTemplate.nDelayTime)
            end
        end
    else
        self:DebugLog("Deactivate")
        self:CloseDelayTimer()
        EventHelper:FireEvent(ClientEventDef.EV_GUIDE_UI_ACTIVATE, false)
        self:StopEffectSound()
    end
end

function GuideActionFullUIControl:PlayEffectSound()
    self:DebugLog("PlayEffectSound")
    local GuideWnd = UIManager:GetWnd(UIDef.UI_GUIDE)
    if not GuideWnd then
        return
    end
    local bActivate = GuideWnd.bActivate
    local nSoundEffectId = self.tbTemplate.nSoundEffectId
    if nSoundEffectId ~= nil and bActivate then
        SoundEffectHelper:PlayGuideSoundEffect(nSoundEffectId)
    end
end

function GuideActionFullUIControl:StopEffectSound()
    self:DebugLog("StopEffectSound")
    SoundEffectHelper:StopCurrentGuideSoundEffect()
end

function GuideActionFullUIControl:OnSelectTab(szWndName, nSelectedTabIndex)
    self:DebugLog("OnSelectTab,szWndName = "..szWndName.." self.UIName = "..self.tbTemplate.szUIName.." self.tbTemplate.nRelatedTabIndex = "..tostring(self.tbTemplate.nRelatedTabIndex).." nSelectedTabIndex = "..tostring(nSelectedTabIndex))
    if self.tbTemplate.szUIName == szWndName and self.tbTemplate.nRelatedTabIndex ~= nil and self.tbTemplate.nRelatedTabIndex ~= nSelectedTabIndex then
        self:End() 
    end
end

function GuideActionFullUIControl:OnCloseUI(szWndName)
    self:DebugLog("OnCloseUI, szWndName = ".. szWndName .." self.tbTemplate.szUIName = "..self.tbTemplate.szUIName)
    if szWndName == UIDef.UI_GUIDE then
        self:DebugLog(" szWndName = UI_GUIDE")
        self:StopEffectSound()
        return
    end
    if self.tbTemplate.szUIName == szWndName then
        self:CloseGuide() 
    else
        self:IsShowTopUI()
    end
end

function GuideActionFullUIControl:OnOpenUI(szWndName)
    self:DebugLog("OnOpenUI,szWndName ="..szWndName.." self.tbTemplate.szUIName = "..self.tbTemplate.szUIName)
    if szWndName == UIDef.UI_GUIDE then
        return
    end
    self:IsShowTopUI()
end

function GuideActionFullUIControl:OnLobbyInviteClicked(bOpen)
    self:DebugLog("OnLobbyInviteClicked")
    if bOpen then
        self:ActiveGuideWnd(false)
    else
        self:ActiveGuideWnd(true)
    end
end

function GuideActionFullUIControl:OnLobbySystemActivate(nSubType)
    local nLobbySubSystem = self.tbTemplate.nLobbySubSystem
    self:DebugLog("OnLobbySystemActivate, szWndName = ".. self.tbTemplate.szUIName .. " nSubType = " .. nSubType  .. " nCurrentSubType = " .. nLobbySubSystem)
    if nLobbySubSystem == -1 then
        return
    end
    if nLobbySubSystem == nSubType then
        self:ActiveGuideWnd(true)
    else
        self:ActiveGuideWnd(false)
    end
end

function GuideActionFullUIControl:CallSetBornSelectArea(Pos, Size, ClickPos, ClickSize, szGuideText, szGuideIcon, nGuidePos, GuideActionRef, bRotation)
    self:DebugLog("CallSetBornSelectArea")
    local tbParams = {}
    self:AddValue(tbParams, "Pos", Pos)
    self:AddValue(tbParams, "Size", Size)
    self:AddValue(tbParams, "ClickPos", ClickPos)
    self:AddValue(tbParams, "ClickSize", ClickSize)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    self:AddValue(tbParams, "bRotation", bRotation)
    self:CallUIFunc("SetBornSelectArea", tbParams)
end

function GuideActionFullUIControl:CallSetSimpleSelectInfo(Pos, Size, szSelectImgWidget, szGuideText, szGuideIcon, nGuidePos, GuideActionRef, bRotation)
    self:DebugLog("CallSetSimpleSelectInfo")
    local tbParams = {}
    self:AddValue(tbParams, "Pos", Pos)
    self:AddValue(tbParams, "Size", Size)
    self:AddValue(tbParams, "szSelectImgWidget", szSelectImgWidget)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    self:AddValue(tbParams, "bRotation", bRotation)
    self:CallUIFunc("SetSimpleSelectInfo", tbParams)
end

function GuideActionFullUIControl:CallSetSelectInfo(Pos, Size, szSelectImgWidget, szGuideText, szGuideIcon, bModal, bClickAnywhere, nGuidePos, GuideActionRef, bRotation, bMultiple, bEffectAnima)
    self:DebugLog("CallSetSelectInfo")
    local tbParams = {}
    self:AddValue(tbParams, "Pos", Pos)
    self:AddValue(tbParams, "Size", Size)
    self:AddValue(tbParams, "szSelectImgWidget", szSelectImgWidget)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "bModal", bModal)
    self:AddValue(tbParams, "bClickAnywhere", bClickAnywhere)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    self:AddValue(tbParams, "bRotation", bRotation)
    self:AddValue(tbParams, "bMultiple", bMultiple)
    self:AddValue(tbParams, "bEffectAnima", bEffectAnima)
    
    self:CallUIFunc("SetSelectInfo", tbParams)
end

function GuideActionFullUIControl:CallSetDragInfo(nDirection, nAngle, szGuideText, szGuideIcon, bModal, nGuidePos, GuideActionRef)
    self:DebugLog("CallSetDragInfo")
    local tbParams = {}
    self:AddValue(tbParams, "nDirection", nDirection)
    self:AddValue(tbParams, "nAngle", nAngle)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "bModal", bModal)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    
    self:CallUIFunc("SetDragInfo", tbParams)
end

function GuideActionFullUIControl:CallSetDragInfoNew(nDirection, nAngle, szGuideText, szGuideIcon, bModal, nGuidePos, GuideActionRef)
    self:DebugLog("CallSetDragInfo")
    local tbParams = {}
    self:AddValue(tbParams, "nDirection", nDirection)
    self:AddValue(tbParams, "nAngle", nAngle)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "bModal", bModal)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    
    self:CallUIFunc("SetDragInfo", tbParams)
end

function GuideActionFullUIControl:CallSetPicGuide(szPicPath, szGuideText, bClickAnywhere)
    self:DebugLog("CallSetPicGuide")
    local tbParams = {}
    self:AddValue(tbParams, "szPicPath", szPicPath)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "bClickAnywhere", bClickAnywhere)
    
    self:CallUIFunc("SetPicGuide", tbParams)
end

function GuideActionFullUIControl:CallShowMediaPlayer(szGuideText, bClickAnywhere)
    self:DebugLog("CallShowMediaPlayer")
    local tbParams = {}
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "bClickAnywheree", bClickAnywhere)
    
    self:CallUIFunc("ShowMediaPlayer", tbParams)
end

function GuideActionFullUIControl:CallSetCentralGuide(szGuideText, bModal, bClickAnywhere, GuideActionRef)
    self:DebugLog("CallSetCentralGuide")
    local tbParams = {}
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "bModal", bModal)
    self:AddValue(tbParams, "bClickAnywheree", bClickAnywhere)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    
    self:CallUIFunc("SetCentralGuide", tbParams)
end

return GuideActionFullUIControl
