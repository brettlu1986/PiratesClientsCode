#pragma once

#include "PropertyWrapper.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnFloatPropertyWrapperValueChanged, float, NewValue);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnInt32PropertyWrapperValueChanged, int32, NewValue);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnBoolPropertyWrapperValueChanged, bool, NewValue);

UENUM(BlueprintType)
enum class EPropertyOverlapType : uint8
{
	Add,
	Multiply,
	Fixed
};

USTRUCT(BlueprintType)
struct ENGINEEXT_API FFloatPropertyWrapper
{
	GENERATED_USTRUCT_BODY()
public:

	FFloatPropertyWrapper()
		: OriginValue(0.f)
		, CurrentValue(0.f)
		, TopIndex(-1)
	{
	}

	void SetOriginValue(float InOriginValue)
	{
		OriginValue = InOriginValue;
		RefreshValue();
	}

    int Overlap(EPropertyOverlapType OverlapType, float OverlapValue)
    {
        TopIndex++;
        switch(OverlapType)
        {
            case EPropertyOverlapType::Add:
                AddOverlapValueMap.Add(TopIndex, OverlapValue);
                break;
            case EPropertyOverlapType::Multiply:
                MultiplyOverlapValueMap.Add(TopIndex, OverlapValue);
                break;
            case EPropertyOverlapType::Fixed:
                FixedOverlapValueMap.Add(TopIndex, OverlapValue);
                break;
        }
		OverlapIdMap.Add(TopIndex, OverlapType);
        RefreshValue();
        return TopIndex;
    }
    
    void RemoveOverlap(int OverlapId)
    {
		EPropertyOverlapType* OverlapType = OverlapIdMap.Find(OverlapId);
		ReturnIfNullptr(OverlapType);
        switch(*OverlapType)
        {
            case EPropertyOverlapType::Add:
                AddOverlapValueMap.Remove(OverlapId);
                break;
            case EPropertyOverlapType::Multiply:
                MultiplyOverlapValueMap.Remove(OverlapId);
                break;
            case EPropertyOverlapType::Fixed:
                FixedOverlapValueMap.Remove(OverlapId);
                break;
        }
		OverlapIdMap.Remove(OverlapId);
        RefreshValue();
    }

	float GetValue()
	{
		return CurrentValue;
	}

	bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
	{
		float LastValue = CurrentValue;
		Ar << CurrentValue;
		if (Ar.IsLoading())
		{
			if ((LastValue != CurrentValue) && OnValueChanged.IsBound())
			{
				OnValueChanged.Broadcast(CurrentValue);
			}
		}
		return bOutSuccess;
	}

	void PostSerialize(const FArchive& Ar)
	{
		CurrentValue = OriginValue;
	}

private:
    void RefreshValue()
    {
		float LastValue = CurrentValue;
        if (FixedOverlapValueMap.Num() > 0)
        {
			TArray<float> FixedOverlapValues;
			FixedOverlapValueMap.GenerateValueArray(FixedOverlapValues);
			CurrentValue = FixedOverlapValues.Last();
        }
		else
		{
			CurrentValue = OriginValue;
			for (auto Pair : AddOverlapValueMap)
			{
				CurrentValue = CurrentValue + Pair.Value;
			}
			for (auto Pair : MultiplyOverlapValueMap)
			{
				CurrentValue = CurrentValue * Pair.Value;
			}
		}
		if ((LastValue != CurrentValue) && OnValueChanged.IsBound())
		{
			OnValueChanged.Broadcast(CurrentValue);
		}
	}

public:
	UPROPERTY(BlueprintAssignable)
	FOnFloatPropertyWrapperValueChanged OnValueChanged;

private:
	UPROPERTY(EditDefaultsOnly)
	float OriginValue;

	UPROPERTY(Transient)
	float CurrentValue;
	
	int TopIndex;
    
	TMap<int, float> AddOverlapValueMap;
    
	TMap<int, float> MultiplyOverlapValueMap;
    
	TMap<int, float> FixedOverlapValueMap;

	TMap<int, EPropertyOverlapType> OverlapIdMap;
};
template<>
struct TStructOpsTypeTraits<FFloatPropertyWrapper> : public TStructOpsTypeTraitsBase2<FFloatPropertyWrapper>
{
    enum
    {
		WithNetSerializer = true,
		WithPostSerialize = true,
    };
};

USTRUCT(BlueprintType)
struct ENGINEEXT_API FInt32PropertyWrapper
{
	GENERATED_USTRUCT_BODY()
public:

	FInt32PropertyWrapper()
		: OriginValue(0)
		, CurrentValue(0)
		, TopIndex(-1)
	{
	}

	void SetOriginValue(int32 InOriginValue)
	{
		OriginValue = InOriginValue;
		RefreshValue();
	}

	int Overlap(EPropertyOverlapType OverlapType, int32 OverlapValue)
	{
		TopIndex++;
		switch (OverlapType)
		{
		case EPropertyOverlapType::Add:
			AddOverlapValueMap.Add(TopIndex, OverlapValue);
			break;
		case EPropertyOverlapType::Multiply:
			MultiplyOverlapValueMap.Add(TopIndex, OverlapValue);
			break;
		case EPropertyOverlapType::Fixed:
			FixedOverlapValueMap.Add(TopIndex, OverlapValue);
			break;
		}
		OverlapIdMap.Add(TopIndex, OverlapType);
		RefreshValue();
		return TopIndex;
	}

	void RemoveOverlap(int OverlapId)
	{
		EPropertyOverlapType* OverlapType = OverlapIdMap.Find(OverlapId);
		ReturnIfNullptr(OverlapType);
		switch (*OverlapType)
		{
		case EPropertyOverlapType::Add:
			AddOverlapValueMap.Remove(OverlapId);
			break;
		case EPropertyOverlapType::Multiply:
			MultiplyOverlapValueMap.Remove(OverlapId);
			break;
		case EPropertyOverlapType::Fixed:
			FixedOverlapValueMap.Remove(OverlapId);
			break;
		}
		OverlapIdMap.Remove(OverlapId);
		RefreshValue();
	}

	int32 GetValue()
	{
		return CurrentValue;
	}

	bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
	{
		int32 LastValue = CurrentValue;
		Ar << CurrentValue;
		if (Ar.IsLoading())
		{
			if ((LastValue != CurrentValue) && OnValueChanged.IsBound())
			{
				OnValueChanged.Broadcast(CurrentValue);
			}
		}
		return bOutSuccess;
	}

	void PostSerialize(const FArchive& Ar)
	{
		CurrentValue = OriginValue;
	}

private:
	void RefreshValue()
	{
		int32 LastValue = CurrentValue;
		if (FixedOverlapValueMap.Num() > 0)
		{
			TArray<int32> FixedOverlapValues;
			FixedOverlapValueMap.GenerateValueArray(FixedOverlapValues);
			CurrentValue = FixedOverlapValues.Last();
		}
		else
		{
			CurrentValue = OriginValue;
			for (auto Pair : AddOverlapValueMap)
			{
				CurrentValue = CurrentValue + Pair.Value;
			}
			for (auto Pair : MultiplyOverlapValueMap)
			{
				CurrentValue = CurrentValue * Pair.Value;
			}
		}
		if ((LastValue != CurrentValue) && OnValueChanged.IsBound())
		{
			OnValueChanged.Broadcast(CurrentValue);
		}
	}

public:
	UPROPERTY(BlueprintAssignable)
	FOnInt32PropertyWrapperValueChanged OnValueChanged;

private:
	UPROPERTY(EditDefaultsOnly)
	int32 OriginValue;

	UPROPERTY(Transient)
	int32 CurrentValue;

	int TopIndex;

	TMap<int, int32> AddOverlapValueMap;

	TMap<int, int32> MultiplyOverlapValueMap;

	TMap<int, int32> FixedOverlapValueMap;

	TMap<int, EPropertyOverlapType> OverlapIdMap;
};
template<>
struct TStructOpsTypeTraits<FInt32PropertyWrapper> : public TStructOpsTypeTraitsBase2<FInt32PropertyWrapper>
{
    enum
    {
		WithNetSerializer = true,
		WithPostSerialize = true,
    };
};

USTRUCT(BlueprintType)
struct ENGINEEXT_API FBoolPropertyWrapper
{
	GENERATED_USTRUCT_BODY()
public:

	FBoolPropertyWrapper()
		: OriginValue(false)
		, CurrentValue(false)
		, TopIndex(-1)
	{
	}

	void SetOriginValue(bool InOriginValue)
	{
		OriginValue = InOriginValue;
		RefreshValue();
	}

	int Overlap(bool OverlapValue)
	{
		TopIndex++;
		FixedOverlapValueMap.Add(TopIndex, OverlapValue);
		RefreshValue();
		return TopIndex;
	}

	void RemoveOverlap(int OverlapId)
	{
		FixedOverlapValueMap.Remove(OverlapId);
		RefreshValue();
	}

	bool GetValue()
	{
		return CurrentValue;
	}

	bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
	{
		bool LastValue = CurrentValue;
		Ar << CurrentValue;
		if (Ar.IsLoading())
		{
			if ((LastValue != CurrentValue) && OnValueChanged.IsBound())
			{
				OnValueChanged.Broadcast(CurrentValue);
			}
		}
		return bOutSuccess;
	}

	void PostSerialize(const FArchive& Ar)
	{
		CurrentValue = OriginValue;
	}

private:
	void RefreshValue()
	{
		bool LastValue = CurrentValue;
		if (FixedOverlapValueMap.Num() > 0)
		{
			TArray<bool> FixedOverlapValues;
			FixedOverlapValueMap.GenerateValueArray(FixedOverlapValues);
			CurrentValue = FixedOverlapValues.Last();
		}
		else
		{
			CurrentValue = OriginValue;
		}
		if (OnValueChanged.IsBound())
		{
			OnValueChanged.Broadcast(CurrentValue);
		}
	}

public:
	UPROPERTY(BlueprintAssignable)
	FOnBoolPropertyWrapperValueChanged OnValueChanged;

private:
	UPROPERTY(EditDefaultsOnly)
	bool OriginValue;

	UPROPERTY(Transient)
	bool CurrentValue;

	int TopIndex;

	TMap<int, bool> FixedOverlapValueMap;
};
template<>
struct TStructOpsTypeTraits<FBoolPropertyWrapper> : public TStructOpsTypeTraitsBase2<FBoolPropertyWrapper>
{
    enum
    {
		WithNetSerializer = true,
		WithPostSerialize = true,
    };
};