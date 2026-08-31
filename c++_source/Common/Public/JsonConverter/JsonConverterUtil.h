#pragma once
#include "JsonConverterUtil.generated.h"

UCLASS()
class COMMON_API UJsonConverterUtil : public UObject
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, CustomThunk, meta = (DisplayName = "ConvertScriptStructToJsonStr", CustomStructureParam = "Structure"), Category = "Json")
    static void ConvertScriptStructToJsonStr(int32 Structure, FString& OutStr);

    /*
    * 蓝图中UScriptStruct 序列化成Json字符串
    */
    static void Generic_ConvertScriptStructToJsonStr(void* Structure, const FStructProperty* StructProperty, FString& OutStr);
    DECLARE_FUNCTION(execConvertScriptStructToJsonStr)
    {
        Stack.StepCompiledIn<FStructProperty>(NULL);
        void* Structure = Stack.MostRecentPropertyAddress;
        FStructProperty* StructProperty = (FStructProperty*)Stack.MostRecentProperty;

        P_GET_PROPERTY_REF(FStrProperty, OutStr);

        P_FINISH;
        P_NATIVE_BEGIN;
        Generic_ConvertScriptStructToJsonStr(Structure, StructProperty, OutStr);
        P_NATIVE_END;
    }

    /*
    * 蓝图中Json字符串 反序列化为UScriptStruct
    */
    UFUNCTION(BlueprintCallable, CustomThunk, meta = (DisplayName = "ConvertJsonStrToScriptStruct", CustomStructureParam = "Structure"), Category = "Json")
    static void ConvertJsonStrToScriptStruct(const FString& Instr, int32 &Structure);
    static void Generic_ConvertJsonStrToScriptStruct(const FString& inStr, void* Structure, const FStructProperty* StructProperty);
    DECLARE_FUNCTION(execConvertJsonStrToScriptStruct)
    {
        P_GET_PROPERTY(FStrProperty, InString);
        Stack.StepCompiledIn<FStructProperty>(NULL);
        void* Structure = Stack.MostRecentPropertyAddress;
        FStructProperty* StructProperty = (FStructProperty*)Stack.MostRecentProperty;

        P_FINISH;
        P_NATIVE_BEGIN;
        Generic_ConvertJsonStrToScriptStruct(InString, Structure, StructProperty);
        P_NATIVE_END;
    }
};