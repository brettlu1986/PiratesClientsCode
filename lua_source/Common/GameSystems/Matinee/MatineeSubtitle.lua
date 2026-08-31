--File Name    : MatineeSubTitle.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-09
--Description  : MatineeSubTitle
-----------------------------------------------------
local MatineeSubTitleData = require("MatineeSubTitleData")
local MatineeSubTitle = {}

local L10N = require("L10N")

function MatineeSubTitle:Parse(SubtitleManager)
	if not SubtitleManager.DrawingSubtitle then
		return
	end
	for _, v in ipairs(SubtitleManager.DrawingSubtitle.SubtitleItems) do
		local nID = v.ContentID
        local tbSubTitle = MatineeSubTitleData:GetTemplate(nID)
		if nID == nil then
			v.Content = ""
			-- logwarning("subtitle content is nil")
        elseif not tbSubTitle then
			v.Content = ""
            -- logwarning("Error Subtitle id " .. nID)
        else
        	v.Content = L10N:ToString(tbSubTitle.l10nMsg)
		end
	end
end

return MatineeSubTitle