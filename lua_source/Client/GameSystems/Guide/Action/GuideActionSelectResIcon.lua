-----------------------------------------------------
--File Name    : GuideActionSelectResIcon.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFullUIControl  = require("GuideActionFullUIControl")
local GuideActionSelectResIcon  = luaclass("GuideActionSelectResIcon",GuideActionFullUIControl)

local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local L10N              = require("L10N")
----------------------------------------------------------
local GetLocalSize = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute = SlateBlueprintLibrary.LocalToAbsolute
----------------------------------------------------------

function GuideActionSelectResIcon:End()
    self:DebugLog("GuideActionSelectWidget:End ")
    GuideActionSelectResIcon.super.End(self)
end

function GuideActionSelectResIcon:DoAction(tbTemplate)
    GuideActionSelectResIcon.super.DoAction(self, tbTemplate)
    local bRotation = false
    local tbParam = tbTemplate.tbParam
    if not tbParam then
        return
    end
    local szPointKey = tbParam[1]
    local BornPointWnd = UIManager:GetWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    if not BornPointWnd then
        self:LogError("GuideActionSelectResIcon:DoAction BornSelectWnd is nil")
        return
    end
    local tbPointMap = BornPointWnd.pbMap.tbMapOpFFAStaticPoint:GetAllPointObjs()
    local Size = {}
    local Pos = {}
    for k, obj in pairs(tbPointMap) do
        if obj.tbData then
            if obj.tbData.szPointKey == szPointKey then
                local pWidgetRef = obj.pWidgetRef.imgSmallIcon
                local pGeometry = pWidgetRef:GetCachedGeometry()
                Size = GetLocalSize(pGeometry)
                Pos = LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
                self:DebugLog("GuideActionSelectResIcon:DoAction szPointKey = " .. szPointKey .. " Pos.X = " .. Pos.X .. " Pos.Y = " .. Pos.Y .. " Size.X = " .. Size.X .. " Size.Y = " .. Size.Y)
                break
            end
        end
    end
    self:DebugLog(" GuideActionSelectResIcon:OnDelayTimerFunc bIsModal = ".. tostring(self.tbGuideTemplate.bIsModal))
    self:CallSetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, bRotation, false, tbTemplate.bMaskEffect)

    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if((tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") )then
        self:EndAction()
    end
end

return GuideActionSelectResIcon
