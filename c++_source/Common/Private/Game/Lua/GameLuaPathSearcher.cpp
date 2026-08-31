#include "Game/Lua/GameLuaPathSearcher.h"
#include "Common.h"
#include "Engine.h"
#include "HAL/FileManager.h"

DEFINE_LOG_CATEGORY_STATIC(LogLuaPathSearcher, Log, All);

struct FGameLuaPathSearcher::FSearcherBase
{
public:
    FSearcherBase(const FString& InputContentPath, const FString& InLuaFileExtension)
        : ContentPath(InputContentPath)
        , LuaFileExtension(InLuaFileExtension)
    {}
    virtual ~FSearcherBase() {};
    virtual void AddPath(const FString& Path) = 0;
    virtual FString FindFullPath(const FString& ScriptName) = 0;
    virtual bool IsFileExisted(const FString& ScriptName) = 0;

    FString ContentPath;
    FString LuaFileExtension;
};

//////////////////////////////////////////////////////////////////////////
static const int ScriptExtensionNum = 2;
static const FString ScriptExtensions[ScriptExtensionNum] = { TEXT(".lua"), TEXT(".luac") };
static const int LuaExtensionLen[ScriptExtensionNum] = { ScriptExtensions[0].Len(), ScriptExtensions[1].Len() };

struct FGameLuaPathSearcher::FIteratePath : public FGameLuaPathSearcher::FSearcherBase
{
    TArray<FString> SearchPaths;
    int CurrentPathIndex;

    // 增加文件名与路径的cache，因为searchpath只有添加，所以这里敢记SearchPaths的index [6/8/2017 liangcheng]
    // 因为文件过多，上k了，所以这里只记录索引
    TMap<FName, int> FileNameToPaths;

    FIteratePath(const FString& InputRootPath, const FString& InLuaFileExtension)
        : FSearcherBase(InputRootPath, InLuaFileExtension)
    {
    }

    virtual void AddPath(const FString& InputPath) override
    {
        FString Path = ContentPath / InputPath;
        class FAddLuaSearchPathVisitor : public IPlatformFile::FDirectoryVisitor
        {
        public:
            FAddLuaSearchPathVisitor(FIteratePath* pTemp)
                : pPaths(pTemp)
            {}

            virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory) override
            {
                // 这里必定先visit dir然后在遍历dir底下的文件
                if (bIsDirectory)
                {
                    pPaths->AddDir(FilenameOrDirectory);
                }
                else
                {
                    pPaths->AddFile(FilenameOrDirectory);
                }
                return true;
            }

        private:
            FIteratePath * pPaths;
        } PathVisitor(this);

        AddDir(Path);
        IFileManager::Get().IterateDirectoryRecursively(*Path, PathVisitor);
    }
    
    virtual FString FindFullPath(const FString& ScriptName) override
    {
        int* pTemp = FileNameToPaths.Find(*ScriptName);
        if (pTemp)
        {
            return SearchPaths[*pTemp] / ScriptName + LuaFileExtension;
        }
        return FString();
    }

    virtual bool IsFileExisted(const FString& ScriptName) override
    {
        return FileNameToPaths.Find(*ScriptName) != nullptr;
    }

    void AddDir(const FString& Path)
    {
        FString DirPath = Path;
        if (!DirPath.EndsWith(TEXT("/")))
        {
            DirPath.AppendChar('/');
        }

        // 改成遍历path下的所有lua文件，然后存下来 [6/8/2017 liangcheng]
        CurrentPathIndex = SearchPaths.Num();
        SearchPaths.Add(DirPath);
    }

    void AddFile(const FString& Path)
    {
        FString FileExtension = FPaths::GetExtension(Path, true);
        if (FileExtension.Compare(LuaFileExtension) != 0 || !IFileManager::Get().FileExists(*Path))
        {
            return;
        }
        FString Dir = FPaths::GetPath(Path).AppendChar('/');
        if (Dir != SearchPaths[CurrentPathIndex])
        {
            if (!SearchPaths.Find(Dir, CurrentPathIndex))
            {
                UE_LOG(LogLuaPathSearcher, Error, TEXT("AddFilePath failed, %s"), *Path);
                return;
            }
        }
        FName KeyName(*FPaths::GetBaseFilename(Path));
        checkf(!FileNameToPaths.Contains(KeyName), TEXT("Duplicated lua file: %s"), *Path);
        FileNameToPaths.Add(KeyName, CurrentPathIndex);
    }
};

//////////////////////////////////////////////////////////////////////////
struct FGameLuaPathSearcher::FLoadCachePath : public FGameLuaPathSearcher::FSearcherBase
{
    FLoadCachePath(const FString& InputRootPath, const FString& InLuaFileExtension, const FString& CachePath)
        : FSearcherBase(InputRootPath, InLuaFileExtension)
        , PathCacheFile(CachePath)
    {
        LuaFilePaths.Empty();
        FileNameToPaths.Empty();
        FString JsonString;
        if (!PathCacheFile.IsEmpty() && FFileHelper::LoadFileToString(JsonString, *(ContentPath / PathCacheFile)))
        {
            TSharedRef<TJsonReader<>> JsonReader = TJsonReaderFactory<>::Create(JsonString);
            TSharedPtr<FJsonObject> RootObject;
            if (FJsonSerializer::Deserialize(JsonReader, RootObject) && RootObject.IsValid())
            {
                for (const auto& DirPathJson : RootObject->Values)
                {
                    const FString& Dir = DirPathJson.Key;
                    int32 CurrentPathIndex = LuaFilePaths.Num();
                    LuaFilePaths.Emplace(Dir);
                    const TArray< TSharedPtr<FJsonValue> >& FilePaths = DirPathJson.Value->AsArray();
                    for (const auto& FilePath : FilePaths)
                    {
                        const FString& LuaFileName = FilePath->AsString();
  
                        FString FileExtension = FPaths::GetExtension(LuaFileName, true);
                        if (FileExtension.Compare(LuaFileExtension) == 0)
                        {
                            FName KeyName(*FPaths::GetBaseFilename(LuaFileName));
                            checkf(!FileNameToPaths.Contains(KeyName), TEXT("FLoadCachePath Duplicated lua file: %s"), *LuaFileName);
                            FileNameToPaths.Add(KeyName, CurrentPathIndex);
                        }
                    }
                }
            }
        }
        else
        {
            checkf(false, TEXT("Load lua path file failed..."))
        }
    }


    virtual void AddPath(const FString& Path) override
    {
#if !UE_BUILD_SHIPPING

#endif
    }

    virtual FString FindFullPath(const FString& ScriptName) override
    {
        int* pTemp = FileNameToPaths.Find(*ScriptName);
        if (pTemp)
        {
            FString LuaFilePath = LuaFilePaths[*pTemp] / ScriptName + LuaFileExtension;
            return ContentPath / LuaFilePath;
        }
        return FString();
    }

    virtual bool IsFileExisted(const FString& ScriptName) override
    {
        return FileNameToPaths.Find(*ScriptName) != nullptr;
    }

    FString PathCacheFile;
    TArray<FString> LuaFilePaths;
    TMap<FName, int> FileNameToPaths;
};

//////////////////////////////////////////////////////////////////////////
bool FGameLuaPathSearcher::Init(const FString& ContentPath, const FString& LuaFileExtension, const FString& PathCacheFile)
{
    if (PathCacheFile.Len() > 0)
    {
        Impl = MakeShareable(new FLoadCachePath(ContentPath, LuaFileExtension, PathCacheFile));
    }
    else
    {
        Impl = MakeShareable(new FIteratePath(ContentPath, LuaFileExtension));
    }
    return true;
}

void FGameLuaPathSearcher::Uninit()
{

}

void FGameLuaPathSearcher::AddPath(const FString& Path)
{
    Impl->AddPath(Path);
}

FString FGameLuaPathSearcher::FindFullPath(const FString& ScriptName)
{
    return Impl->FindFullPath(ScriptName);
}

bool FGameLuaPathSearcher::IsFileExisted(const FString& Path)
{
    return Impl->IsFileExisted(Path);
}
