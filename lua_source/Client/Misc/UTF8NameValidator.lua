
-----------------------------------------------------
--File Name    : UTF8NameValidator.lua
--Author       : Zuo Kun
--Create Time  : 2017-10-25
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local UTF8NameValidator = luaclass("UTF8NameValidator")

UTF8NameValidator.CharacterDisplayWidth ={
    nHalfWidth = 1,
    nFullWidth = 2,
}

UTF8NameValidator.LengthConstraint = {
    nMinCodePoint = 0,
    nMaxCodePoint = 0,
    nMinDisplayWidth = 0,
    nMaxDisplayWidth = 0,
}

UTF8NameValidator.Result = {
    OK = 1,
    InvalidUTF8 = 2,
    InvalidLength = 3,
    InvalidCodePoint = 4,
}

UTF8NameValidator.tbBlocks = {}

function UTF8NameValidator:SetLengthConstraint(nMinCodePoint, nMaxCodePoint, nMinDisplayWidth, nMaxDisplayWidth)
    self.LengthConstraint.nMinCodePoint = nMinCodePoint
    self.LengthConstraint.nMaxCodePoint = nMaxCodePoint
    self.LengthConstraint.nMinDisplayWidth = nMinDisplayWidth
    self.LengthConstraint.nMaxDisplayWidth = nMaxDisplayWidth
end

function UTF8NameValidator:AddBlock(nRangeBegin, nRangeEnd, nDisplayWidth)
    local tbBlock = {}
    tbBlock.nRangeBegin = nRangeBegin
    tbBlock.nRangeEnd = nRangeEnd
    tbBlock.nDisplayWidth = nDisplayWidth
    table.insert( self.tbBlocks, tbBlock )
end

function UTF8NameValidator:AddBlocks(tbBlocks)
    if not tbBlocks then
        return
    end
    for _,v in ipairs(tbBlocks) do
        self:AddBlock(v.nRangeBegin,v.nRangeEnd,v.nDisplayWidth)
    end
end

local function ValidateCodePoint(self, nCodePoint)
    local tbBLock = nil
    for _,v in ipairs(self.tbBlocks) do
        if nCodePoint >= v.nRangeBegin and nCodePoint <= v.nRangeEnd then
            tbBLock = v
            break
        end
    end

    if tbBLock then
        return true, tbBLock.nDisplayWidth
    else
        return false, 0
    end
end

function UTF8NameValidator:Validate(szName)
    if not szName or string.len(szName) == 0 then
        return self.Result.InvalidUTF8, 0
    end
    local nCodePoint = 0
    local nDisplayWidth = 0
    for _nPos, nCode in utf8.codes(szName) do
        local bRet, nWidth = ValidateCodePoint(self, nCode)
        nCodePoint = nCodePoint + 1
        if not bRet then
            return self.Result.InvalidCodePoint, 0
        else
            nDisplayWidth = nDisplayWidth + nWidth
        end
    end

    if nCodePoint < self.LengthConstraint.nMinCodePoint or nCodePoint > self.LengthConstraint.nMaxCodePoint then
        return self.Result.InvalidLength, nDisplayWidth
    end

    if nDisplayWidth < self.LengthConstraint.nMinDisplayWidth or nDisplayWidth > self.LengthConstraint.nMaxDisplayWidth then
        return self.Result.InvalidLength, nDisplayWidth
    end

    return self.Result.OK, nDisplayWidth
end

function UTF8NameValidator:DisplayWidth(szName)
    if not szName then
        return self.Result.InvalidUTF8, 0
    end
    local nCodePoint = 0
    local nDisplayWidth = 0
    for _nPos, nCode in utf8.codes(szName) do
        local bRet, nWidth = ValidateCodePoint(self, nCode)
        nCodePoint = nCodePoint + 1

        if not bRet then
            return self.Result.InvalidCodePoint, 0
        else
            nDisplayWidth = nDisplayWidth + nWidth
        end
    end

    return self.Result.OK, nDisplayWidth
end

function UTF8NameValidator:GetLegalNameLength(szName, nLen)
    if not szName then
        return self.Result.InvalidUTF8, 0
    end
    local nDisplayWidth = 0
    for nPos, nCode in utf8.codes(szName) do
        local bRet, nWidth = ValidateCodePoint(self, nCode)
        if not bRet then
            return self.Result.InvalidCodePoint, nPos
        else
            nDisplayWidth = nDisplayWidth + nWidth
        end
        if nDisplayWidth > nLen then
            return self.Result.OK, nPos - 1
        end
    end


    return self.Result.OK, #szName
end

return UTF8NameValidator