// Fill out your copyright notice in the Description page of Project Settings.
#include "JsonConverter/JsonConvertScriptStruct.h"
#include "Common.h"

namespace
{
	TSharedPtr<FJsonValue> ConvertScalarUPropertyToJsonValue(FProperty* Property,const void* Value)
	{
		if (FNumericProperty *NumericProperty = CastField<FNumericProperty>(Property))
		{
			// see if it's an enum
			UEnum* EnumDef = NumericProperty->GetIntPropertyEnum();
			if (EnumDef != NULL)
			{
				// export enums as strings
				FString StringValue = EnumDef->GetNameStringByIndex(NumericProperty->GetSignedIntPropertyValue(Value));
				return MakeShareable(new FJsonValueString(StringValue));
			}

			// We want to export numbers as numbers
			if (NumericProperty->IsFloatingPoint())
			{
				//float FloatValue = NumericProperty->GetFloatingPointPropertyValue(Value);
				return MakeShareable(new FJsonValueNumber(NumericProperty->GetFloatingPointPropertyValue(Value)));
			}
			else if (NumericProperty->IsInteger())
			{
				//int32 IntValue = NumericProperty->GetSignedIntPropertyValue(Value);
				return MakeShareable(new FJsonValueNumber(NumericProperty->GetSignedIntPropertyValue(Value)));
			}

			// fall through to default
		}
		else if (FBoolProperty *BoolProperty = CastField<FBoolProperty>(Property))
		{
			//bool BoolValue = BoolProperty->GetPropertyValue(Value);
			// Export bools as bools
			return MakeShareable(new FJsonValueBoolean(BoolProperty->GetPropertyValue(Value)));
		}
		else if (FStrProperty *StringProperty = CastField<FStrProperty>(Property))
		{
			//FString StringValue = StringProperty->GetPropertyValue(Value);
			return MakeShareable(new FJsonValueString(StringProperty->GetPropertyValue(Value)));
		}
		else if (FArrayProperty *ArrayProperty = CastField<FArrayProperty>(Property))
		{
			TArray< TSharedPtr<FJsonValue> > Out;
			FScriptArrayHelper Helper(ArrayProperty, Value);
			for (int32 i = 0, n = Helper.Num(); i < n; ++i)
			{
				TSharedPtr<FJsonValue> Elem = JsonConvertScriptStruct::UPropertyToJsonValue(ArrayProperty->Inner, Helper.GetRawPtr(i));
				if (Elem.IsValid())
				{
					// add to the array
					Out.Push(Elem);
				}
			}
			return MakeShareable(new FJsonValueArray(Out));
		}
		else if (FStructProperty *StructProperty = CastField<FStructProperty>(Property))
		{
			TSharedRef<FJsonObject> Out = MakeShareable(new FJsonObject());
			if (JsonConvertScriptStruct::UScriptStructToJsonObject(Value, StructProperty->Struct, Out))
			{
				return MakeShareable(new FJsonValueObject(Out));
			}
			// fall through to default
		}
		else
		{
			// Default to export as string for everything else
 			FString StringValue;
 			Property->ExportTextItem(StringValue, Value, NULL, NULL, PPF_None);
 			return MakeShareable(new FJsonValueString(StringValue));
		}

		// invalid
		return TSharedPtr<FJsonValue>();
	}

	/** Convert JSON to property, assuming either the property is not an array or the value is an individual array element */
	bool ConvertScalarJsonValueToUProperty(TSharedPtr<FJsonValue> JsonValue, FProperty* Property, void* OutValue)
	{
		if (FNumericProperty *NumericProperty = CastField<FNumericProperty>(Property))
		{
			if (NumericProperty->IsEnum() && JsonValue->Type == EJson::String)
			{
				// see if we were passed a string for the enum
				const UEnum* EnumProperty = NumericProperty->GetIntPropertyEnum();
				check(EnumProperty); // should be assured by IsEnum()
				FString StrValue = JsonValue->AsString();
				int32 IntValue = EnumProperty->GetIndexByName(FName(*StrValue));
				if (IntValue == INDEX_NONE)
				{
					UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Unable import enum %s from string value %s"), *EnumProperty->CppType, *StrValue);
					return false;
				}
				NumericProperty->SetIntPropertyValue(OutValue, (int64)IntValue);
			}
			else if (NumericProperty->IsFloatingPoint())
			{
				// AsNumber will log an error for completely inappropriate types (then give us a default)
				NumericProperty->SetFloatingPointPropertyValue(OutValue, JsonValue->AsNumber());
			}
			else if (NumericProperty->IsInteger())
			{
				if (JsonValue->Type == EJson::String)
				{
					// parse string -> int64 ourselves so we don't lose any precision going through AsNumber (aka double)
					NumericProperty->SetIntPropertyValue(OutValue, FCString::Atoi64(*JsonValue->AsString()));
				}
				else
				{
					// AsNumber will log an error for completely inappropriate types (then give us a default)
					NumericProperty->SetIntPropertyValue(OutValue, (int64)JsonValue->AsNumber());
				}
			}
			else
			{
				UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Unable to set numeric property type %s"), *Property->GetClass()->GetName());
				return false;
			}
		}
		else if (FBoolProperty *BoolProperty = CastField<FBoolProperty>(Property))
		{
			// AsBool will log an error for completely inappropriate types (then give us a default)
			BoolProperty->SetPropertyValue(OutValue, JsonValue->AsBool());
		}
		else if (FStrProperty *StringProperty = CastField<FStrProperty>(Property))
		{
			// AsString will log an error for completely inappropriate types (then give us a default)
			StringProperty->SetPropertyValue(OutValue, JsonValue->AsString());
		}
		else if (FArrayProperty *ArrayProperty = CastField<FArrayProperty>(Property))
		{
			if (JsonValue->Type == EJson::Array)
			{
				TArray< TSharedPtr<FJsonValue> > ArrayValue = JsonValue->AsArray();
				int32 ArrLen = ArrayValue.Num();

				// make the output array size match
				FScriptArrayHelper Helper(ArrayProperty, OutValue);
				Helper.Resize(ArrLen);

				// set the property values
				for (int32 i = 0; i < ArrLen; ++i)
				{
					const TSharedPtr<FJsonValue>& ArrayValueItem = ArrayValue[i];
					if (ArrayValueItem.IsValid() && !ArrayValueItem->IsNull())
					{
						if (!JsonConvertScriptStruct::JsonValueToUProperty(ArrayValueItem, ArrayProperty->Inner, Helper.GetRawPtr(i)))
						{
							UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Unable to deserialize array element [%d]"), i);
							return false;
						}
					}
				}
			}
			else
			{
				UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Attempted to import TArray from non-array JSON key"));
				return false;
			}
		}
		else if (FStructProperty *StructProperty = CastField<FStructProperty>(Property))
		{
			static const FName NAME_DateTime(TEXT("DateTime"));
			if (JsonValue->Type == EJson::Object)
			{
				TSharedPtr<FJsonObject> Obj = JsonValue->AsObject();
				if (Obj.IsValid()) // should normally always be true
				{
					if (!JsonConvertScriptStruct::JsonObjectToUScriptStruct(Obj.ToSharedRef(), StructProperty->Struct, OutValue))
					{
						// error message should have already been logged
						return false;
					}
				}
				else
				{
					UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Attempted to import UStruct from an invalid object JSON key"));
					return false;
				}
			}
			else if (JsonValue->Type == EJson::String && StructProperty->Struct->GetFName() == NAME_DateTime)
			{
				FString DateString = JsonValue->AsString();
				FDateTime& DateTimeOut = *(FDateTime*)OutValue;
				if (DateString == TEXT("min"))
				{
					// min representable value for our date struct. Actual date may vary by platform (this is used for sorting)
					DateTimeOut = FDateTime::MinValue();
				}
				else if (DateString == TEXT("max"))
				{
					// max representable value for our date struct. Actual date may vary by platform (this is used for sorting)
					DateTimeOut = FDateTime::MaxValue();
				}
				else if (DateString == TEXT("now"))
				{
					// this value's not really meaningful from json serialization (since we don't know timezone) but handle it anyway since we're handling the other keywords
					DateTimeOut = FDateTime::UtcNow();
				}
				else if (!FDateTime::ParseIso8601(*DateString, DateTimeOut))
				{
					UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Unable to import FDateTime from Iso8601 String"));
					return false;
				}
			}
			else
			{
				UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Attempted to import UStruct from non-object JSON key"));
				return false;
			}
		}
		else
		{
			// Default to expect a string for everything else
			if (Property->ImportText(*JsonValue->AsString(), OutValue, 0, NULL) == NULL)
			{
				UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Unable import property type %s from string value"), *Property->GetClass()->GetName());
				return false;
			}
		}
		return true;
	}

	//
	bool ParseScriptStructPropertyNameToSimple(FString& name)
	{
		int32 index;
		if (name.FindLastChar('_', index))
		{
			name = name.Mid(0, index);
		}
		if (name.FindLastChar('_', index))
		{
			name = name.Mid(0, index);
		}
		return true;
	}
}

TSharedPtr<FJsonValue> JsonConvertScriptStruct::UPropertyToJsonValue(FProperty* Property, const void* Structure)
{
	if (Property->ArrayDim == 1)
	{
		const void* ValuePtr = Property->ContainerPtrToValuePtr<void>(Structure, 0);
		return ConvertScalarUPropertyToJsonValue(Property, ValuePtr);
	}

	TArray< TSharedPtr<FJsonValue> > Array;
	for (int32 ArrayIndex = 0; ArrayIndex < Property->ArrayDim; ArrayIndex++)
	{
		// This grabs the pointer to where the property value is stored
		const void* ValuePtr = Property->ContainerPtrToValuePtr<void>(Structure, ArrayIndex);
		// Parse this property
		TSharedPtr<FJsonValue> jsonValue = ConvertScalarUPropertyToJsonValue(Property, ValuePtr);
		Array.Add(jsonValue);
	}

	return MakeShareable(new FJsonValueArray(Array));
}

bool JsonConvertScriptStruct::UScriptStructToJsonObject(const void* Structure, const UScriptStruct* Struct, TSharedRef<FJsonObject> OutJsonObject)
{
	return UScriptStructToAttributes(Structure, Struct, OutJsonObject->Values);
}

bool JsonConvertScriptStruct::UScriptStructToAttributes(const void* Structure, const UScriptStruct* Struct, TMap< FString, TSharedPtr<FJsonValue> >& OutJsonAttributes)
{
	for (TFieldIterator<FProperty> It(Struct); It; ++It)
	{
		FProperty* Property = *It;

		// This is the variable name if you need it
		FString VariableName = Property->GetName();
		ParseScriptStructPropertyNameToSimple(VariableName);
		//const void* Value = Property->ContainerPtrToValuePtr<uint8>(Struct);

		TSharedPtr<FJsonValue> JsonValue = UPropertyToJsonValue(Property, Structure);

		if (!JsonValue.IsValid())
		{
			return false;
		}
		OutJsonAttributes.Add(VariableName, JsonValue);
		//JsonObject->sett
	}
	return true;
}

bool JsonConvertScriptStruct::ConvertScriptStructToJsonStr(void* Structure, const FStructProperty* StructProperty, FString& OutStr)
{
	// Walk the Structs' properties
	UScriptStruct* Struct = StructProperty->Struct;
	TSharedRef<FJsonObject> JsonObject = MakeShareable(new FJsonObject());
	if (UScriptStructToJsonObject(Structure, Struct, JsonObject))
	{
		TSharedRef<TJsonWriter<> > JsonWriter = TJsonWriterFactory<>::Create(&OutStr, 0);
		if (FJsonSerializer::Serialize(JsonObject, JsonWriter))
		{
			JsonWriter->Close();
			return true;
		}
		else
		{
			UE_LOG(LogJson, Warning, TEXT("UStructToJsonObjectString - Unable to write out json"));
			JsonWriter->Close();
		}
	}

	return false;
}

bool JsonConvertScriptStruct::JsonValueToUProperty(TSharedPtr<FJsonValue> JsonValue, FProperty* Property, void* OutValue)
{
	if (!JsonValue.IsValid())
	{
		UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Invalid value JSON key"));
		return false;
	}

	bool bArrayProperty = Property->IsA<FArrayProperty>();
	bool bJsonArray = JsonValue->Type == EJson::Array;

	if (!bJsonArray)
	{
		if (bArrayProperty)
		{
			UE_LOG(LogJson, Error, TEXT("JsonValueToUProperty - Attempted to import TArray from non-array JSON key"));
			return false;
		}

		if (Property->ArrayDim != 1)
		{
			UE_LOG(LogJson, Warning, TEXT("Ignoring excess properties when deserializing %s"), *Property->GetName());
		}

		return ConvertScalarJsonValueToUProperty(JsonValue, Property, OutValue);
	}

	// In practice, the ArrayDim == 1 check ought to be redundant, since nested arrays of UPropertys are not supported
	if (bArrayProperty && Property->ArrayDim == 1)
	{
		// Read into TArray
		return ConvertScalarJsonValueToUProperty(JsonValue, Property, OutValue);
	}

	// We're deserializing a JSON array
	const auto& ArrayValue = JsonValue->AsArray();
	if (Property->ArrayDim < ArrayValue.Num())
	{
		UE_LOG(LogJson, Warning, TEXT("Ignoring excess properties when deserializing %s"), *Property->GetName());
	}

	// Read into native array
	int ItemsToRead = FMath::Clamp(ArrayValue.Num(), 0, Property->ArrayDim);
	for (int Index = 0; Index != ItemsToRead; ++Index)
	{
		if (!ConvertScalarJsonValueToUProperty(ArrayValue[Index], Property, (char*)OutValue + Index * Property->ElementSize))
		{
			return false;
		}
	}

	return true;
}

bool JsonConvertScriptStruct::JsonObjectToUScriptStruct(const TSharedRef<FJsonObject>& JsonObject, const UScriptStruct* Struct, void* OutStruct)
{
	return JsonAttributesToUScriptStruct(JsonObject->Values, Struct, OutStruct);
}

bool JsonConvertScriptStruct::JsonAttributesToUScriptStruct(const TMap< FString, TSharedPtr<FJsonValue> >& JsonAttributes, const UScriptStruct* Struct, void* OutStruct)
{
	for (TFieldIterator<FProperty> ItProperty(Struct); ItProperty; ++ItProperty)
	{
		FProperty* Property = *ItProperty;

		// This is the variable name if you need it
		FString PropertyName = Property->GetName();
		ParseScriptStructPropertyNameToSimple(PropertyName);
		//const void* Value = Property->ContainerPtrToValuePtr<uint8>(Struct);

		TSharedPtr<FJsonValue> JsonValue;
		for (auto It = JsonAttributes.CreateConstIterator(); It; ++It)
		{
			if (PropertyName.Equals(It.Key(), ESearchCase::IgnoreCase))
			{
				JsonValue = It.Value();
				break;
			}
		}
		if (!JsonValue.IsValid() || JsonValue->IsNull())
		{
			// we allow values to not be found since this mirrors the typical UObject mantra that all the fields are optional when deserializing
			continue;;
		}

		void* Value = Property->ContainerPtrToValuePtr<uint8>(OutStruct);
		if (!JsonValueToUProperty(JsonValue, Property, Value))
		{
			UE_LOG(LogJson, Error, TEXT("JsonObjectToUStruct - Unable to parse %s.%s from JSON"), *Struct->GetName(), *PropertyName);
			return false;
		}
	}
	return true;
}

bool JsonConvertScriptStruct::ConvertJsonStrToScriptStruct(const FString& inStr, void* Structure, const FStructProperty* StructProperty)
{
	UScriptStruct* Struct = StructProperty->Struct;
	TSharedPtr<FJsonObject> JsonObject;
	TSharedRef<TJsonReader<> > JsonReader = TJsonReaderFactory<>::Create(inStr);
	if (!FJsonSerializer::Deserialize(JsonReader, JsonObject) || !JsonObject.IsValid())
	{
		UE_LOG(LogJson, Warning, TEXT("JsonObjectStringToUStruct - Unable to parse json=[%s]"), *inStr);
		return false;
	}
	if (!JsonConvertScriptStruct::JsonObjectToUScriptStruct(JsonObject.ToSharedRef(), Struct, Structure))
	{
		UE_LOG(LogJson, Warning, TEXT("JsonObjectStringToUStruct - Unable to deserialize. json=[%s]"), *inStr);
		return false;
	}
	return true;
}

bool JsonConvertScriptStruct::GetScriptStructPropertyContent(void* Structure, const FStructProperty* StructProperty, const FName &PropertyName, FString& Str_R, UObject *&Obj_R, int32 &Int_R, float &Float_R, bool &Bool_R)
{
	// Walk the Structs' properties
	UScriptStruct* Struct = StructProperty->Struct;
	FString StrPropertyName = PropertyName.ToString();
	for (TFieldIterator<FProperty> It(Struct); It; ++It)
	{
		FProperty* Property = *It;

		// This is the variable name if you need it
		FString VariableName = Property->GetName();
		ParseScriptStructPropertyNameToSimple(VariableName);
		if (VariableName == StrPropertyName)
		{
			if (Property->ArrayDim != 1)
			{
				break;
			}
			else
			{
				const void* ValuePtr = Property->ContainerPtrToValuePtr<void>(Structure, 0);
				if (FNumericProperty *NumericProperty = CastField<FNumericProperty>(Property))
				{
					// see if it's an enum
					UEnum* EnumDef = NumericProperty->GetIntPropertyEnum();
					if (EnumDef != NULL)
					{
						// export enums as strings
						int64 EnumValue = NumericProperty->GetSignedIntPropertyValue(ValuePtr);
						Str_R = EnumDef->GetNameStringByIndex(EnumValue);
						Int_R = EnumValue;
						return true;
					}

					// We want to export numbers as numbers
					if (NumericProperty->IsFloatingPoint())
					{
						Float_R = NumericProperty->GetFloatingPointPropertyValue(ValuePtr);
						return true;
					}
					else if (NumericProperty->IsInteger())
					{
						Int_R = NumericProperty->GetSignedIntPropertyValue(ValuePtr);
						return true;
					}
					// fall through to default
				}
				else if (FBoolProperty *BoolProperty = CastField<FBoolProperty>(Property))
				{
					Bool_R = BoolProperty->GetPropertyValue(ValuePtr);
					return true;
				}
				else if (FStrProperty *StringProperty = CastField<FStrProperty>(Property))
				{
					Str_R = StringProperty->GetPropertyValue(ValuePtr);
					return true;
				}
				else if (FObjectProperty *ObjectProperty = CastField<FObjectProperty>(Property))
				{
					Obj_R = ObjectProperty->GetPropertyValue(ValuePtr);
					return true;
				}

				else
				{
					// Default to export as string for everything else
					Property->ExportTextItem(Str_R, ValuePtr, NULL, NULL, PPF_None);
					return true;
				}
			}
		}
	}
	return false;
}