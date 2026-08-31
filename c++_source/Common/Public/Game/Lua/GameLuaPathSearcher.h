#pragma once

class COMMON_API FGameLuaPathSearcher
{
    struct FSearcherBase;
    struct FIteratePath;
    struct FLoadCachePath;
    TSharedPtr<FSearcherBase> Impl;

public:    
    bool Init(const FString& ContentPath, const FString& LuaFileExtension, const FString& PathCacheFile);
    void Uninit();

    const FString& GetContentPath() const;
    void AddPath(const FString& Path);    
    FString FindFullPath(const FString& ScriptName);
    bool IsFileExisted(const FString& ScriptName);
};