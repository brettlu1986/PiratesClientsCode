local DescKeyParserRegister = {}


function DescKeyParserRegister.RegisterParsers(fnRegister)
    fnRegister("HumanWeaponPropertyDescKeyParser")
    fnRegister("HumanArmorPropertyDescKeyParser")
    fnRegister("HumanMiscDescKeyParser")
end

return DescKeyParserRegister