#pragma once

#include "PropertyWrapper.h"
#include "PropertyWrapperFunctionLibrary.generated.h"

UCLASS()
class ENGINEEXT_API UPropertyWrapperFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
    UFUNCTION(BlueprintCallable, Category="PropertyWrapper", meta = (DisplayName = "SetOriginValue"))
    static void SetOriginValue_Float(UPARAM(ref) FFloatPropertyWrapper& PropertyWrapper, float OriginValue);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "Overlap"))
	static int Overlap_Float(UPARAM(ref) FFloatPropertyWrapper& PropertyWrapper, EPropertyOverlapType OverlapType, float Value);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "RemoveOverlap"))
	static void RemoveOverlap_Float(UPARAM(ref) FFloatPropertyWrapper& PropertyWrapper, int OverlapIndex);

	UFUNCTION(BlueprintPure, Category = "PropertyWrapper", meta = (DisplayName = "Value"))
	static float GetValue_Float(UPARAM(ref) FFloatPropertyWrapper& PropertyWrapper);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "BindOnValueChanged", DefaultToSelf = "Object"))
	static void BindOnValueChanged_Float(UPARAM(ref) FFloatPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "UnbindOnValueChanged", DefaultToSelf = "Object"))
	static void UnbindOnValueChanged_Float(UPARAM(ref) FFloatPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName);

    UFUNCTION(BlueprintCallable, Category="PropertyWrapper", meta = (DisplayName = "SetOriginValue"))
    static void SetOriginValue_Int32(UPARAM(ref) FInt32PropertyWrapper& PropertyWrapper, int32 OriginValue);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "Overlap"))
	static int Overlap_Int32(UPARAM(ref) FInt32PropertyWrapper& PropertyWrapper, EPropertyOverlapType OverlapType, int32 Value);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "RemoveOverlap"))
	static void RemoveOverlap_Int32(UPARAM(ref) FInt32PropertyWrapper& PropertyWrapper, int OverlapIndex);

	UFUNCTION(BlueprintPure, Category = "PropertyWrapper", meta = (DisplayName = "Value"))
	static int32 GetValue_Int32(UPARAM(ref) FInt32PropertyWrapper& PropertyWrapper);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "BindOnValueChanged", DefaultToSelf = "Object"))
	static void BindOnValueChanged_Int32(UPARAM(ref) FInt32PropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "UnbindOnValueChanged", DefaultToSelf = "Object"))
	static void UnbindOnValueChanged_Int32(UPARAM(ref) FInt32PropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName);

    UFUNCTION(BlueprintCallable, Category="PropertyWrapper", meta = (DisplayName = "SetOriginValue"))
    static void SetOriginValue_Bool(UPARAM(ref) FBoolPropertyWrapper& PropertyWrapper, bool OriginValue);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "Overlap"))
	static int Overlap_Bool(UPARAM(ref) FBoolPropertyWrapper& PropertyWrapper, bool Value);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "RemoveOverlap"))
	static void RemoveOverlap_Bool(UPARAM(ref) FBoolPropertyWrapper& PropertyWrapper, int OverlapIndex);

	UFUNCTION(BlueprintPure, Category = "PropertyWrapper", meta = (DisplayName = "Value"))
	static bool GetValue_Bool(UPARAM(ref) FBoolPropertyWrapper& PropertyWrapper);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "BindOnValueChanged", DefaultToSelf = "Object"))
	static void BindOnValueChanged_Bool(UPARAM(ref) FBoolPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName);

	UFUNCTION(BlueprintCallable, Category = "PropertyWrapper", meta = (DisplayName = "UnbindOnValueChanged", DefaultToSelf = "Object"))
	static void UnbindOnValueChanged_Bool(UPARAM(ref) FBoolPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName);
};