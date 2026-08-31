local HttpHelper = {}

HttpHelper.tbDelegateMap = {}

HttpHelper.HttpResponseCodes = {
    OK = 200,
    NOT_MODIFIED = 304
}

-- fnCallback(bSuccess, szContent)
function HttpHelper:SendGetRequest(szUrl, fnCallback)
    local bRet = false
    local pHttpHelper = CommonShell.GetCommon(GWorld):GetHttpHelper()
    local tbDelegateKey = {}
    local fnFinalCallback, szInfo
    if(GEnableNewLua) then
        szInfo = getdebuginfo_f(fnCallback)
        fnFinalCallback = function(...)
            -- release pDelegate
            self.tbDelegateMap[tbDelegateKey] = nil
            fnCallback(...)
        end
    else
        fnFinalCallback = function(_, ...)
            -- release pDelegate
            self.tbDelegateMap[tbDelegateKey] = nil
            fnCallback(...)
        end
    end

    tbDelegateKey.fnFinalCallback = fnFinalCallback
    local pDelegate = createDelegate(pHttpHelper.OnHttpRequestCompletedDelegateSignature,
        fnFinalCallback, szInfo)
    if pHttpHelper:SendGetRequest(szUrl, pDelegate) then
        -- hold pDelegate to prevent gc
        self.tbDelegateMap[tbDelegateKey] = pDelegate
        bRet = true
    end
    return bRet
end

function HttpHelper:SendGetRequestWithHeader(szUrl, szHeaderName, szHeaderValue, szResponseHeader, fnCallback)
    local bRet = false
    local pHttpHelper = CommonShell.GetCommon(GWorld):GetHttpHelper()
    local tbDelegateKey = {}
    local fnFinalCallback, szInfo
    if(GEnableNewLua) then
        szInfo = getdebuginfo_f(fnCallback)
        fnFinalCallback = function(...)
            -- release pDelegate
            self.tbDelegateMap[tbDelegateKey] = nil
            fnCallback(...)
        end
    else
        fnFinalCallback = function(_, ...)
            -- release pDelegate
            self.tbDelegateMap[tbDelegateKey] = nil
            fnCallback(...)
        end
    end

    tbDelegateKey.fnFinalCallback = fnFinalCallback
    local pDelegate = createDelegate(pHttpHelper.OnHttpRequestWithHeaderCompletedDelegateSignature,
        fnFinalCallback, szInfo)
    if pHttpHelper:SendGetRequestWithHeader(szUrl, szHeaderName, szHeaderValue, szResponseHeader, pDelegate) then
        -- hold pDelegate to prevent gc
        self.tbDelegateMap[tbDelegateKey] = pDelegate
        bRet = true
    end
    return bRet
end

-- fnCallback(bSuccess, szContent)
function HttpHelper:SendPostRequest(szUrl, szHeaderName, szHeaderValue, szContent, fnCallback)
    local bRet = false
    local pHttpHelper = CommonShell.GetCommon(GWorld):GetHttpHelper()
    local tbDelegateKey = {}
    local fnFinalCallback, szInfo
    if(GEnableNewLua) then
        szInfo = getdebuginfo_f(fnCallback)
        fnFinalCallback = function(...)
            -- release pDelegate
            self.tbDelegateMap[tbDelegateKey] = nil
            fnCallback(...)
        end
    else
        fnFinalCallback = function(_, ...)
            -- release pDelegate
            self.tbDelegateMap[tbDelegateKey] = nil
            fnCallback(...)
        end
    end

    tbDelegateKey.fnFinalCallback = fnFinalCallback
    local pDelegate = createDelegate(pHttpHelper.OnHttpRequestCompletedDelegateSignature,
        fnFinalCallback, szInfo)
    if pHttpHelper:SendPostRequest(szHeaderName, szHeaderValue, szUrl, szContent, pDelegate) then
        -- hold pDelegate to prevent gc
        self.tbDelegateMap[tbDelegateKey] = pDelegate
        bRet = true
    end
    return bRet
end

return HttpHelper