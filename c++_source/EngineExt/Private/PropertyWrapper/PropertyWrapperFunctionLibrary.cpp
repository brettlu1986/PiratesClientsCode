
#include "PropertyWrapper/PropertyWrapperFunctionLibrary.h"
#include "EngineExt.h"

void UPropertyWrapperFunctionLibrary::SetOriginValue_Float(FFloatPropertyWrapper& PropertyWrapper, float OriginValue)
{
    PropertyWrapper.SetOriginValue(OriginValue);
}

int UPropertyWrapperFunctionLibrary::Overlap_Float(FFloatPropertyWrapper& PropertyWrapper, EPropertyOverlapType OverlapType, float Value)
{
    return PropertyWrapper.Overlap(OverlapType, Value);
}

void UPropertyWrapperFunctionLibrary::RemoveOverlap_Float(FFloatPropertyWrapper& PropertyWrapper, int OverlapIndex)
{
    PropertyWrapper.RemoveOverlap(OverlapIndex);
}

float UPropertyWrapperFunctionLibrary::GetValue_Float(FFloatPropertyWrapper& PropertyWrapper)
{
    return PropertyWrapper.GetValue();
}

void UPropertyWrapperFunctionLibrary::BindOnValueChanged_Float(FFloatPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName)
{
	FScriptDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionName);
	PropertyWrapper.OnValueChanged.Add(Delegate);
}

void UPropertyWrapperFunctionLibrary::UnbindOnValueChanged_Float(FFloatPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName)
{
	FScriptDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionName);
	PropertyWrapper.OnValueChanged.Remove(Delegate);
}

void UPropertyWrapperFunctionLibrary::SetOriginValue_Int32(FInt32PropertyWrapper& PropertyWrapper, int32 OriginValue)
{
    PropertyWrapper.SetOriginValue(OriginValue);
}

int UPropertyWrapperFunctionLibrary::Overlap_Int32(FInt32PropertyWrapper& PropertyWrapper, EPropertyOverlapType OverlapType, int32 Value)
{
    return PropertyWrapper.Overlap(OverlapType, Value);
}

void UPropertyWrapperFunctionLibrary::RemoveOverlap_Int32(FInt32PropertyWrapper& PropertyWrapper, int OverlapIndex)
{
    PropertyWrapper.RemoveOverlap(OverlapIndex);
}

int32 UPropertyWrapperFunctionLibrary::GetValue_Int32(FInt32PropertyWrapper& PropertyWrapper)
{
    return PropertyWrapper.GetValue();
}

void UPropertyWrapperFunctionLibrary::BindOnValueChanged_Int32(FInt32PropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName)
{
	FScriptDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionName);
	PropertyWrapper.OnValueChanged.Add(Delegate);
}

void UPropertyWrapperFunctionLibrary::UnbindOnValueChanged_Int32(FInt32PropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName)
{
	FScriptDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionName);
	PropertyWrapper.OnValueChanged.Remove(Delegate);
}

void UPropertyWrapperFunctionLibrary::SetOriginValue_Bool(FBoolPropertyWrapper& PropertyWrapper, bool OriginValue)
{
    PropertyWrapper.SetOriginValue(OriginValue);
}

int UPropertyWrapperFunctionLibrary::Overlap_Bool(FBoolPropertyWrapper& PropertyWrapper, bool Value)
{
    return PropertyWrapper.Overlap(Value);
}

void UPropertyWrapperFunctionLibrary::RemoveOverlap_Bool(FBoolPropertyWrapper& PropertyWrapper, int OverlapIndex)
{
    PropertyWrapper.RemoveOverlap(OverlapIndex);
}

bool UPropertyWrapperFunctionLibrary::GetValue_Bool(FBoolPropertyWrapper& PropertyWrapper)
{
    return PropertyWrapper.GetValue();
}

void UPropertyWrapperFunctionLibrary::BindOnValueChanged_Bool(FBoolPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName)
{
	FScriptDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionName);
	PropertyWrapper.OnValueChanged.Add(Delegate);
}

void UPropertyWrapperFunctionLibrary::UnbindOnValueChanged_Bool(FBoolPropertyWrapper& PropertyWrapper, UObject* Object, FName FunctionName)
{
	FScriptDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionName);
	PropertyWrapper.OnValueChanged.Remove(Delegate);
}