-----------------------------------------------------
--File Name    : UPNpcHeadIconWidget.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPNpcHeadIconWidget = luaclass("UPNpcHeadIconWidget", UPWidgetBase)
local UISetUtils = require("UISetUtils")
local NpcHeadIconRes = require("NpcHeadIconRes")
local StringUtil = require("StringUtil")

function UPNpcHeadIconWidget:OnWidgetCreated()
	local nHeadIcon = 0
	local nInterAction = 0
	if self.OwnerGameObject.tbNpcTemplateData then 
		nHeadIcon = self.OwnerGameObject.tbNpcTemplateData.nHeadIcon
		nInterAction = self.OwnerGameObject.tbNpcTemplateData.nInteractionType
	end 
	if nHeadIcon > 0 then
		local tbIconRes = NpcHeadIconRes:GetTemplate(nHeadIcon)
		if tbIconRes and not StringUtil.IsEmptyString(tbIconRes.szHeadIcon) then
			-- local pRes = tbIconRes.szHeadIcon:load()
			-- if not pRes then
            --     self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
            --     logdebug("Error HeadIcon Path  " .. tbIconRes.szHeadIcon)
			-- 	return
			-- end
			self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Visible)			
			-- UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon,pRes,true)
			UISetUtils.SetAsyncImageBrushFromSprite(self.pWidgetRef.imgIcon,tbIconRes.szHeadIcon, nil, true)
			if  nInterAction == 0 then
				self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
			end
		end
	else
		self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
	end
end




return UPNpcHeadIconWidget 