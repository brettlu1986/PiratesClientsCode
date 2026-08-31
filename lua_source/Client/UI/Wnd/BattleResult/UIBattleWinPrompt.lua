-----------------------------------------------------
--File Name    : UIBattleWinPrompt.lua
--Description  : 战斗胜利提示界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIBattleWinPrompt = luaclass("UIBattleWinPrompt", WndBase)



function UIBattleWinPrompt:OnShow()
    self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        local FinishCallback = self.tbOpenArgs.FinishCallback
        if FinishCallback then
            FinishCallback()
        end
        --self.pWidgetRef.cvsContent:SetVisibility(ESlateVisibility_Collapsed)
    end)
end

return UIBattleWinPrompt