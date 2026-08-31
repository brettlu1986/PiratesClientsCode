// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GenericPlatform/GenericPlatformFile.h"
#include "SensitiveWordManager.generated.h"

#define DEFAULT_HASHMAP_SIZE 521


UCLASS()
class CLIENT_API USensitiveWordManager : public UObject
{
	GENERATED_UCLASS_BODY()
private:
	struct FMemPool
	{
		char* Block;
		char* Avail;
		char* End;
	};

	struct FHashMapEntry
	{		
		struct FHashMapEntry* Next;
		const char Key[1];
	};

public:
	UFUNCTION()
	bool Init(const FString& FileName);

	UFUNCTION()
	void Uninit();

	UFUNCTION()
	bool Replace(const FString& Src, FString& Dest);

	UFUNCTION()
	bool Check(const FString& Src);

private:
	bool MemPoolInit(int Size);
	char* MemPoolGet(int Size);
	void MemPoolUninit();

	bool AddToDict(const char* Word);
	void CollectCountInfo(char* Buffer, int BufferSize, int& OutCharCount, int& OutLineCount);
	void IterateAllLines(const char* Buffer, int BufferSize, int LineCount);
private:
	TMap<int32, FHashMapEntry*> Dict;
	FMemPool  Mem;
};
