local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMChallengeSetting = luaclass("JGMChallengeSetting", JGMCommonSetting)

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


function JGMChallengeSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMChallengeSetting.super.Init(self, tbGameMode)) then
        return false
    end

    return true
end

function JGMChallengeSetting:Uninit()
    JGMChallengeSetting.super.Uninit(self)
end

function JGMChallengeSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.DungeonPVE
end

return JGMChallengeSetting