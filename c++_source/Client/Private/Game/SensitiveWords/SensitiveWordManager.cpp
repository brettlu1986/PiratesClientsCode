// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/SensitiveWords/SensitiveWordManager.h"
#include "Client.h"

#define MAX_CHAR_LENGTH 1024
#define REPLACE_CHAR '*'

DEFINE_LOG_CATEGORY_STATIC(SensitiveWordManagerLog, Log, All)

unsigned char utf8_look_for_table[] =
{
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 1, 1 };

#define UTFLEN(x) utf8_look_for_table[(x)]

static int SDBMHash(const char *str, int len) {
	int hash = 0;
	while (*str && len-- > 0) {
		hash = (*str++) + 65599 * hash;
	}
	return (hash & 0x7FFFFFFF);
}

USensitiveWordManager::USensitiveWordManager(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{

}
bool USensitiveWordManager::Init(const FString& FileName)
{
	auto FileHandler = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*FileName);
	if (!FileHandler)
	{
		UE_LOG(SensitiveWordManagerLog, Error,
			TEXT("USensitiveWordManager::Init Load File Failed, %s"), *FileName);
		return false;
	}

	char* Buffer = nullptr;
	auto BufferSize = FileHandler->Size();
	if (BufferSize > 0)
	{		
		Buffer = (char*)FMemory::Malloc(BufferSize + 2);
		FileHandler->Read((uint8*)Buffer, BufferSize);

		//buffer结尾添加'\r''0',用于截取buffer
		char* Temp = (char*)Buffer + BufferSize;
		*Temp = '\r';
		++Temp;
		*Temp = 0;
		BufferSize++;

		delete FileHandler;
	}
	else
	{
		delete FileHandler;
		UE_LOG(SensitiveWordManagerLog, Error,
			TEXT("USensitiveWordManager::Init Load File Size=0, %s"), *FileName);
		return false;
	}

	int LineCount = 0;
	int TotalCharCount = 0;
	CollectCountInfo(Buffer, BufferSize, TotalCharCount, LineCount);
	if (!MemPoolInit(TotalCharCount + LineCount* sizeof(FHashMapEntry)))
	{
		UE_LOG(SensitiveWordManagerLog, Error,
			TEXT("USensitiveWordManager::Init Pool Failed"));
		FMemory::Free(Buffer);
		return false;
	}

	IterateAllLines(Buffer, BufferSize, LineCount);

	FMemory::Free(Buffer);

	return true;
}

void USensitiveWordManager::Uninit()
{
	MemPoolUninit();
}

bool USensitiveWordManager::AddToDict(const char* Word)
{
	check(Word);
	int WordLen = strlen(Word);
	check(WordLen > 0);
	check(Word[WordLen] == 0);

	FHashMapEntry* Entry = (FHashMapEntry*)MemPoolGet(WordLen + 1 + sizeof(FHashMapEntry));
	FMemory::Memcpy(const_cast<char*>(&Entry->Key[0]), Word, WordLen + 1);
	int KeyLen = UTFLEN((unsigned char)* Entry->Key);
	int Hash = SDBMHash(Entry->Key, KeyLen) % DEFAULT_HASHMAP_SIZE;

	FHashMapEntry** Temp = Dict.Find(Hash);
	if (Temp != NULL)
	{
		Entry->Next = *Temp;
		Dict[Hash] = Entry;
	}
	else
	{
		Entry->Next = NULL;
		Dict.Add(Hash, Entry);
	}

	return true;
}

void USensitiveWordManager::CollectCountInfo(char* Buffer, 
	int BufferSize, int& OutTotalCharCount, int& OutLineCount)
{
	OutTotalCharCount = 0;
	char* P = Buffer;

	int CharCountInOneLine = 0;
	while (*P)
	{
		if (*P == '\r' || *P == '\n')
		{
			while (*P == '\r' || *P == '\n')
			{
				*P = 0;
				P++;
				check(P >= Buffer && P <= Buffer + BufferSize);
			}
			OutTotalCharCount += CharCountInOneLine + 1;
			CharCountInOneLine = 0;
			OutLineCount++;
		}
		else 
		{
			CharCountInOneLine++;
			P++;
			check(P >= Buffer && P <= Buffer + BufferSize);
		}
	}
}

void USensitiveWordManager::IterateAllLines(const char* Buffer, int BufferSize, int LineCount)
{
	const char* P = Buffer;	
	const char* Temp = P;
	while (LineCount > 0)
	{
		P++;
		check(P >= Buffer && P <= Buffer + BufferSize);
		if (*P == 0)
		{
			LineCount--;
			AddToDict(Temp);
			if (LineCount <= 0)
			{
				break;
			}
			while (*P == 0)
			{
				check(P >= Buffer && P + 1 <= Buffer + BufferSize);
				P++;
			}
			Temp = P;
		}
	}
}

bool USensitiveWordManager::MemPoolInit(int Size)
{
	check(Mem.Block == nullptr && Size > 0);
	Mem.Block = (char*)FMemory::Malloc(Size);
	if (Mem.Block == NULL)
	{
		return false;
	}

	Mem.Avail = Mem.Block;
	Mem.End = Mem.Avail + Size;

	return true;
}

void USensitiveWordManager::MemPoolUninit()
{
	check(Mem.Block);
	FMemory::Free(Mem.Block);
	memset(&Mem, 0, sizeof(FMemPool));
}

char* USensitiveWordManager::MemPoolGet(int Size)
{
	check(Mem.Avail + Size <= Mem.End);
	char* Ret = Mem.Avail;
	Mem.Avail += Size;
	return Ret;
}

bool USensitiveWordManager::Check(const FString& Src)
{
	int StrLen = strlen(TCHAR_TO_UTF8(*Src));
	if (StrLen >= MAX_CHAR_LENGTH)
	{
		return false;
	}

	int SourceBufferSize = StrLen + 1;
	char* Source = reinterpret_cast<char *>(FMemory::Malloc(SourceBufferSize));
	FCStringAnsi::Strcpy(Source, SourceBufferSize, TCHAR_TO_UTF8(*Src));

	const char* P = Source;
	while (*P)
	{
		unsigned char CH = (unsigned char)*P;
		int Len = UTFLEN(CH);
		int Hash = SDBMHash(P, Len) % DEFAULT_HASHMAP_SIZE;
		FHashMapEntry** TempHashMapEntry = Dict.Find(Hash);
		if (TempHashMapEntry)
		{
			for (FHashMapEntry* HashMapEntry = *TempHashMapEntry; HashMapEntry != NULL;
				HashMapEntry = HashMapEntry->Next)
			{
				const char* P1 = P;
				const char* P2 = HashMapEntry->Key;
				while (*P1 && *P2 && *P1 == *P2)
				{
					P1++;
					check(P1 <= Source + SourceBufferSize);
					P2++;
				}
				if (*P2 == 0)
				{
					//find
					int TempLen = P2 - HashMapEntry->Key;
					if (TempLen > 0) {
						FMemory::Free(Source);
						return true;
					}
				}

			}
		}

		P += Len;
		check(P <= Source + SourceBufferSize);
	}

	return false;
}

bool USensitiveWordManager::Replace(const FString& Src, FString& Dest)
{
	bool Ret = false;

	char Source[MAX_CHAR_LENGTH];
	FCStringAnsi::Strcpy(Source, MAX_CHAR_LENGTH, TCHAR_TO_UTF8(*Src));

	int SourceBufferSize = FCStringAnsi::Strlen(Source) + 1;

	char OutBuf[MAX_CHAR_LENGTH];
	char* POut = OutBuf;
	const char* P = Source;

	while (*P)
	{
		unsigned char CH = (unsigned char)*P;
		int Len = UTFLEN(CH);
		int Hash = SDBMHash(P, Len) % DEFAULT_HASHMAP_SIZE;
		int FindLen = 0;
		FHashMapEntry** TempHashMapEntry = Dict.Find(Hash);
		if (TempHashMapEntry)
		{
			for (FHashMapEntry* HashMapEntry = *TempHashMapEntry; HashMapEntry != NULL;
				HashMapEntry = HashMapEntry->Next)
			{
				const char* P1 = P;
				const char* P2 = HashMapEntry->Key;
				while (*P1 && *P2 && *P1 == *P2)
				{
					P1++;
					P2++;
				}
				if (*P2 == 0)
				{
					//find
					int TempLen = P2 - HashMapEntry->Key;
					if (TempLen > FindLen) 
					{
						FindLen = TempLen;
					}
				}

			}
		}
		if (FindLen > 0)
		{
			int TempLen1 = FindLen;
			const char* TempP = P;
			while (TempLen1 > 0)
			{
				unsigned char TempCh = (unsigned char)*TempP;
                TempP+=UTFLEN(TempCh);
				int TempLen2 = UTFLEN(TempCh);
				*POut++ = REPLACE_CHAR;
				TempLen1 -= TempLen2;
				check(TempLen1 >= 0);
			}

			P += FindLen;
			Ret = true;
		}
		else
		{
			FMemory::Memcpy(POut, P, Len);
			POut += Len;
			P += Len;
		}
		check(P <= Source + SourceBufferSize);
		check(POut < &OutBuf[0] + MAX_CHAR_LENGTH);
	}
	
	*POut = 0;
	Dest = UTF8_TO_TCHAR(OutBuf);

	return Ret;
}