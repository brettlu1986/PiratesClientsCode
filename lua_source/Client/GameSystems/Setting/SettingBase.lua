local luaclass = require("luaclass")
local SettingBase = luaclass("SettingBase")

SettingBase.Owner = nil

function SettingBase:Init(Owner)
    self.Owner = Owner
end

function SettingBase:Uninit()
end

function SettingBase:LoadLocalSetting()
end

function SettingBase:LoadRemoteSetting()
end

function SettingBase:Set(nKey, nValue)
    self.Owner:Set(nKey, nValue)
end

function SettingBase:Get(nKey)
    return self.Owner:Get(nKey)
end

function SettingBase:ClearSaveData()

end

return SettingBase