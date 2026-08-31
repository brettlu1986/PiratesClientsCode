-----------------------------------------------------
--File Name    : GuideActionPlayMedia.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionPlayMedia          = luaclass("GuideActionPlayMedia",GuideActionFullUIControl)

local ClientEventDef    = require("ClientEventDef")
local L10N              = require("L10N")
local MediaSystem       = require("MediaSystem")

local function CloseMediaPlayer()
    MediaSystem:CloseMedia()
end

function GuideActionPlayMedia:DoAction(tbTemplate)
    GuideActionPlayMedia.super.DoAction(self, tbTemplate)
    self:CallShowMediaPlayer(L10N:ToString(tbTemplate.l10nGuideText), tbTemplate.bClickAnywhere)
    MediaSystem:PlayMedia(tbTemplate.nMediaId)
end

function GuideActionPlayMedia:Begin()
    GuideActionPlayMedia.super.Begin(self)  
    self.EventHelper:RegisterEvent(ClientEventDef.EV_VIDEO_CLOSED, self, self.OnVideoEnd)
end

function GuideActionPlayMedia:OnVideoEnd()
    CloseMediaPlayer()
    self:EndAction()
end

function GuideActionPlayMedia:OnClickAnywhere()
    GuideActionPlayMedia.super.OnClickAnywhere(self)
    CloseMediaPlayer()
    self:EndAction()
end


function GuideActionPlayMedia:End()
    GuideActionPlayMedia.super.End(self)
    
end

return GuideActionPlayMedia
