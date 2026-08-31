local SensitiveWordsSystem = {}

SensitiveWordsSystem.pManager = nil

local szSensitiveWordFile = getcontentdir().."GameDataGenerated/common/sensitivewords/sensitivewords.txt"

function SensitiveWordsSystem:Init()
    local pSensitiveWordManager = ClientShell.GetClient(GWorld):GetSensitiveWordManager()
    self.pManager = pSensitiveWordManager

    log("SensitiveWordsSystem:Init", self.pManager)
    pSensitiveWordManager:Init(szSensitiveWordFile)
end

function SensitiveWordsSystem:Uninit()
    log("SensitiveWordsSystem:Uninit")
    self.pManager:Uninit()
end

function SensitiveWordsSystem:Check(szWords)
    log("SensitiveWordsSystem:Check")
    return self.pManager:Check(szWords)
end

function SensitiveWordsSystem:Replace(szWords)
    local _, szRet = self.pManager:Replace(szWords)
    return szRet
end

return SensitiveWordsSystem