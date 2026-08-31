-----------------------------------------------------
--File Name    : GuideActionLoopPlayMedia.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFullUIControl  = require("GuideActionFullUIControl")
local GuideActionLoopPlayMedia  = luaclass("GuideActionLoopPlayMedia",GuideActionFullUIControl)

local ClientEventDef    = require("ClientEventDef")
local L10N              = require("L10N")
local MediaSystem       = require("MediaSystem")

GuideActionLoopPlayMedia.nMediaId = nil

local function CloseMediaPlayer()
    MediaSystem:CloseMedia()
end

function GuideActionLoopPlayMedia:DoAction(tbTemplate)
    GuideActionLoopPlayMedia.super.DoAction(self, tbTemplate)
    self:CallShowMediaPlayer(L10N:ToString(tbTemplate.l10nGuideText), tbTemplate.bClickAnywhere)
    self.nMediaId = tbTemplate.nMediaId
    MediaSystem:PlayMedia(tbTemplate.nMediaId)
end

function GuideActionLoopPlayMedia:BindEvent()
    GuideActionLoopPlayMedia.super.BindEvent(self)  
    self.EventHelper:RegisterEvent(ClientEventDef.EV_VIDEO_CLOSED, self, self.OnVideoEnd)
end

function GuideActionLoopPlayMedia:OnVideoEnd()
    MediaSystem:PlayMedia(self.nMediaId)
end

function GuideActionLoopPlayMedia:OnClickAnywhere()
    CloseMediaPlayer()
    self:EndAction()
end


function GuideActionLoopPlayMedia:End()
    GuideActionLoopPlayMedia.super.End(self)
    CloseMediaPlayer()
end

return GuideActionLoopPlayMedia
