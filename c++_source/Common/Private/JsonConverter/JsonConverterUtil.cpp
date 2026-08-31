#include "JsonConverter/JsonConverterUtil.h"
#include "Common.h"
#include "JsonConverter/JsonConvertScriptStruct.h"

void UJsonConverterUtil::Generic_ConvertScriptStructToJsonStr(void* Structure, const FStructProperty* StructProperty, FString& OutStr)
{
    JsonConvertScriptStruct::ConvertScriptStructToJsonStr(Structure, StructProperty, OutStr);
}

void UJsonConverterUtil::Generic_ConvertJsonStrToScriptStruct(const FString& inStr, void* Structure, const FStructProperty* StructProperty)
{
    JsonConvertScriptStruct::ConvertJsonStrToScriptStruct(inStr, Structure, StructProperty);
}