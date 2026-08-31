// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
/**
 *
 */
class COMMON_API JsonConvertScriptStruct
{
public:
	/*
	* 蓝图Struct 转成 JsonStr
	*/
	static bool ConvertScriptStructToJsonStr(void* Structure, const FStructProperty* StructProperty, FString& OutStr);
	/*
	* JsonStr转成UScriptStruct
	*/
	static bool ConvertJsonStrToScriptStruct(const FString& inStr, void* Structure, const FStructProperty* StructProperty);

	static bool GetScriptStructPropertyContent(void* Structure, const FStructProperty* StructProperty, const FName &PropertyName, FString& Str_R, UObject *&Obj_R, int32 &Int_R, float &Float_R, bool &Bool_R);

	static bool UScriptStructToJsonObject(const void* Structure, const UScriptStruct* Struct, TSharedRef<FJsonObject> OutJsonObject);
	static bool UScriptStructToAttributes(const void* Structure, const UScriptStruct* Struct, TMap< FString, TSharedPtr<FJsonValue> >& OutJsonAttributes);
	static TSharedPtr<FJsonValue> UPropertyToJsonValue(FProperty* Property, const void* Value);

	static bool JsonObjectToUScriptStruct(const TSharedRef<FJsonObject>& JsonObject, const UScriptStruct* Struct, void* OutStruct);
	static bool JsonAttributesToUScriptStruct(const TMap< FString, TSharedPtr<FJsonValue> >& JsonAttributes, const UScriptStruct* Struct, void* OutStruct);
	static bool JsonValueToUProperty(TSharedPtr<FJsonValue> JsonValue, FProperty* Property, void* OutValue);
};
