-----------------------------------------------------
--File Name    : GuideActionSelectResIcon.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectResIcon      = require("GuideActionSelectResIcon")
local GuideActionSelectAllResIcon   = luaclass("GuideActionSelectAllResIcon", GuideActionSelectResIcon)

local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local L10N              = require("L10N")
----------------------------------------------------------
local GetLocalSize = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute = SlateBlueprintLibrary.LocalToAbsolute

function GuideActionSelectAllResIcon:DoAction(tbTemplate)
    GuideActionSelectAllResIcon.super.DoAction(self, tbTemplate)
    local tbRotation = {}
    local BornPointWnd = UIManager:GetWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    if not BornPointWnd then
        return
    end
    local tbPointMap = BornPointWnd.pbMap.tbMapOpFFAStaticPoint:GetAllPointObjs()
    local tbPos = {}
    local tbSize = {}
    local tbParam = tbTemplate.tbParam
    local szSelectWidgetName = "imgSmallIcon"
    if tbParam then
        szSelectWidgetName = tbParam[1]
    end
    local DefaultVec = Vector2D{X=0,Y=0}
    for k, obj in pairs(tbPointMap) do
        local pWidgetRef = obj.pWidgetRef[szSelectWidgetName]--txtObjName--obj.pWidgetRef.imgSmallIcon
        local pGeometry = pWidgetRef:GetCachedGeometry()
        local Size = GetLocalSize(pGeometry)
        local Pos = LocalToAbsolute(pGeometry,DefaultVec)
        self:DebugLog("szPointKey = " .. obj.tbData.szPointKey .. " Size.X = " .. Size.X .. " Size.Y = " .. Size.Y .. " Pos.X = " .. Pos.X .. " Pos.Y = " .. Pos.Y)
        if Pos.X ~= 0 and Size.X ~= 0 then
            table.insert(tbPos, Pos)
            table.insert(tbSize, Size)
            local RenderTransform = pWidgetRef.RenderTransform
            local nAngle = math.abs(RenderTransform.Angle)
            local Scale = RenderTransform.Scale
            if nAngle == 180 or (Scale.X == -1 and Scale.Y == -1) then
                table.insert(tbRotation, true)
            else
                table.insert(tbRotation, false)
            end
        end
    end
    self:CallSetSelectInfo(tbPos, tbSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, tbRotation, true, tbTemplate.bMaskEffect)
    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "" and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") then
        self:EndAction()
    end
end

return GuideActionSelectAllResIcon
