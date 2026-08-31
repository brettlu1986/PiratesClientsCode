#include "EditorExtendFunctions.h"
#include "PiratesEditor.h"
#include "Misc/FileHelper.h"
#include "GenericPlatform/GenericPlatformFile.h"
#include "Misc/SecureHash.h"
#include "HAL/PlatformFilemanager.h"
#include "Kismet/GameplayStatics.h"
#include "ShipExporter.h"
#include "Editor.h"
#include "FileHelpers.h"
#include "LevelSequenceActor.h"
#include "MovieScene.h"
#include "MovieSceneTimeHelpers.h"
#include "Misc/QualifiedFrameTime.h"
#include "Misc/FrameRate.h"
#include "Misc/FrameTime.h"
#include "Engine/LevelScriptBlueprint.h"

bool UEditorExtendFunctions::SaveStringToFile(const FString& FullPath, const FString& Data)
{
	return FFileHelper::SaveStringToFile(Data, *FullPath, FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
}

void UEditorExtendFunctions::CollectPaths(const FString& FullPath, const FString& Extention, bool bRecursively, TArray<FString>& Out)
{
	class FTempLuaSearchPathVisitor : public IPlatformFile::FDirectoryVisitor
	{
	public:
		FTempLuaSearchPathVisitor(TArray<FString>* pTemp, const FString& TempExtention)
			: pOut(pTemp)
			, Extention(TempExtention)			
		{
		}

		virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory) override
		{
			if (!bIsDirectory && (Extention.Len() == 0 || FCString::Strcmp(FilenameOrDirectory + FCString::Strlen(FilenameOrDirectory) - Extention.Len(), *Extention) == 0))
			{
				pOut->Add(FilenameOrDirectory);
			}
			return true;
		}

	private:
		TArray<FString> *pOut;
		FString Extention;
	};

	FTempLuaSearchPathVisitor PathVisitor(&Out, Extention);
	if (bRecursively)
	{
		IFileManager::Get().IterateDirectoryRecursively(*FullPath, PathVisitor);
	}
	else
	{
		IFileManager::Get().IterateDirectory(*FullPath, PathVisitor);
	}
}

bool UEditorExtendFunctions::DeleteDirectory(const FString& FullPath)
{
	return IFileManager::Get().DeleteDirectory(*FullPath, false, true);
}

bool UEditorExtendFunctions::CopyDirectory(const FString& Dest, const FString& Source, bool bDeleteOld)
{
    if (bDeleteOld)
    {
        UEditorExtendFunctions::DeleteDirectory(Dest);
    }    

    if (!IFileManager::Get().DirectoryExists(*Source))
    {
        return false;
    }
    IFileManager::Get().MakeDirectory(*Dest, true);
    IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();
    return PlatformFile.CopyDirectoryTree(*Dest, *Source, true);    
}

bool UEditorExtendFunctions::DeleteFile(const FString& FullPath)
{
	return IFileManager::Get().Delete(*FullPath, false, false, true);
}

bool UEditorExtendFunctions::CopyFile(const FString& Dest, const FString& Source)
{
	return COPY_OK == IFileManager::Get().Copy(*Dest, *Source, true, true);
}

typedef TMap<FString, FMD5Hash> FTempFileInfoMap;
class FTempFileVisitor : public IPlatformFile::FDirectoryVisitor
{
public:
	FTempFileVisitor(FTempFileInfoMap* pTemp)
		: pNewFileInfoMap(pTemp)
	{
	}
	virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory) override
	{
		if (!bIsDirectory)
		{
			FMD5Hash Hash = FMD5Hash::HashFile(FilenameOrDirectory);
			if (Hash.IsValid())
			{
				pNewFileInfoMap->Add(FilenameOrDirectory, Hash);
			}
		}
		return true;
	}

private:
	FTempFileInfoMap * pNewFileInfoMap;
};

bool UEditorExtendFunctions::CheckFileModified(const TArray<FString>& Dirs, 
	const FString& CheckInfoFilePath,
	TArray<FEditorFileChangeInfo>& OutChangedInfo)
{
	FString BasePath = FPaths::GetPath(FPaths::GetProjectFilePath());
	FPaths::NormalizeFilename(BasePath);

	FTempFileInfoMap OldFileInfoMap;
	TArray<FString> OldFileLines;
	int nFindIndex = -1;
	if (FFileHelper::LoadFileToStringArray(OldFileLines, *CheckInfoFilePath))
	{
		TArray<FString> FilePathWithMD5;
		FilePathWithMD5.Reserve(2);
		for (int ii=0; ii<OldFileLines.Num(); ii++)
		{	
			FilePathWithMD5.Reset();
			const FString& Line = OldFileLines[ii];
			if (Line.FindLastChar(TCHAR(':'), nFindIndex))
			{
				FMD5Hash Hash;
				FString FileName(Line.Left(nFindIndex));
				FString HashString(Line.Right(Line.Len() - nFindIndex - 1));
				LexFromString(Hash, *HashString);
				OldFileInfoMap.Add(FileName, Hash);
			}
		}
	}

	FTempFileInfoMap NewFileInfoMap;
	FTempFileVisitor Visitor(&NewFileInfoMap);
	for (int ii=0; ii<Dirs.Num(); ii++)
	{
		const FString& Dir = Dirs[ii];		
		IFileManager::Get().IterateDirectoryRecursively(*Dir, Visitor);
	}
	
	for (auto Iter = NewFileInfoMap.CreateConstIterator(); Iter; ++Iter)
	{
		FString Path = Iter->Key;
		Path = Path.Right(Path.Len() - Path.Find(TEXT("Content")));
		const FMD5Hash& NewHash = Iter->Value;
		FMD5Hash OldHash;
		if (OldFileInfoMap.RemoveAndCopyValue(Path, OldHash))
		{
			if (NewHash != OldHash)
			{
				OutChangedInfo.Add(FEditorFileChangeInfo(Path, FEditorFileChangeState::Modify));
			}
		}
		else
		{
			OutChangedInfo.Add(FEditorFileChangeInfo(Path, FEditorFileChangeState::New));
		}
	}	

	for (auto Iter = OldFileInfoMap.CreateConstIterator(); Iter; ++Iter)
	{
		OutChangedInfo.Add(FEditorFileChangeInfo(Iter->Key, FEditorFileChangeState::Delete));
	}
	return true;
}

bool UEditorExtendFunctions::SaveFileModifiedInfo(const TArray<FString>& Dirs,
	const FString& CheckInfoFilePath)
{
	FTempFileInfoMap NewFileInfoMap;
	FTempFileVisitor Visitor(&NewFileInfoMap);
	for (int ii = 0; ii < Dirs.Num(); ii++)
	{
		const FString& Dir = Dirs[ii];
		IFileManager::Get().IterateDirectoryRecursively(*Dir, Visitor);
	}

	TArray<FString> FileData;
	for (auto Iter = NewFileInfoMap.CreateConstIterator(); Iter; ++Iter)
	{
		FString Path = Iter->Key;
		Path = Path.Right(Path.Len() - Path.Find(TEXT("Content")));
		const FMD5Hash& NewHash = Iter->Value;		
		FileData.Add(FString::Printf(TEXT("%s:%s"), *Path, *LexToString(NewHash)));
	}
	return FFileHelper::SaveStringArrayToFile(FileData, *CheckInfoFilePath, FFileHelper::EEncodingOptions::ForceUTF8);
} 

void  UEditorExtendFunctions::ShowMulticastFunction()
{
    for (FObjectIterator Iter(UFunction::StaticClass()); Iter; ++Iter)
    {
        UFunction * FunctionObj = Cast<UFunction>(*Iter);
        if (FunctionObj && FunctionObj->FunctionFlags & FUNC_NetMulticast && FunctionObj->FunctionFlags & FUNC_NetReliable)
        {
            FString FunctionOwnerName = FunctionObj->GetOwnerClass()->GetName();
            FunctionOwnerName.RemoveFromStart(TEXT("SKEL_"), ESearchCase::CaseSensitive);
            FunctionOwnerName.RemoveFromEnd(TEXT("_C"), ESearchCase::CaseSensitive);
            UE_LOG(LogTemp, Error, TEXT("find reliable multicast function %s in class %s"), *FunctionObj->GetName(), *FunctionOwnerName);
        }
    }
}

void UEditorExtendFunctions::ExportShipConfig(bool bForce)
{
    UShipExporter::Export(true, bForce);
}

bool UEditorExtendFunctions::ConcateFiles(const TArray<FString>& SourceFiles, const FString& TargetFilePath)
{
    IFileManager& FileManager = IFileManager::Get();

    if (FileManager.FileExists(*TargetFilePath))
    {
        FileManager.Delete(*TargetFilePath);
    }
    FArchive* WriterAr = IFileManager::Get().CreateFileWriter(*TargetFilePath);

    FArchive* ReaderAr = nullptr;
    for (const FString& File : SourceFiles)
    {
        ReaderAr = FileManager.CreateFileReader(*File);
        if (ReaderAr != nullptr)
        {
            int Size = ReaderAr->TotalSize();
            char* TempBuffer = new char[Size];
            ReaderAr->Serialize(TempBuffer, Size);
            WriterAr->Serialize(TempBuffer, Size);
            ReaderAr->Close();
            delete[] TempBuffer;
            delete ReaderAr;
        }
    }

    WriterAr->Close();
    delete WriterAr;

    return true;
}

void UEditorExtendFunctions::CollectDirs(const FString& FullPath, TArray<FString>& Out)
{
    class FTempLuaSearchPathVisitor : public IPlatformFile::FDirectoryVisitor
    {
    public:
        FTempLuaSearchPathVisitor(TArray<FString>* pTemp)
            : pOut(pTemp)
        {
        }

        virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory) override
        {
            if (bIsDirectory)
            {
                pOut->Add(FilenameOrDirectory);
            }
            return true;
        }

    private:
        TArray<FString> *pOut;
    };

    FTempLuaSearchPathVisitor PathVisitor(&Out);

    IFileManager::Get().IterateDirectory(*FullPath, PathVisitor);
}

void UEditorExtendFunctions::CollectAssetOrDefaultObjectByDirectory(const FString& FullPath, TArray<UObject*>& Out, bool bAssetObject)
{
    IFileManager& FileManager = IFileManager::Get();

    TArray<FString> FilePaths;
    FileManager.FindFilesRecursive(FilePaths, *FullPath, TEXT("*.uasset"), true, false, false);
    
    FString ProjectContentDirectory = UKismetSystemLibrary::GetProjectContentDirectory();
    for (int i = 0; i< FilePaths.Num(); ++i)
    {
        FString FilePath = FilePaths[i].Replace(*ProjectContentDirectory, TEXT("")).Replace(TEXT(".uasset"), TEXT(""));
        int32 nIndex = -1;
        if (FilePath.FindLastChar(TEXT('/'), nIndex))
        {
            FString RelativeFileName = FilePath.Right(FilePath.Len() - nIndex - 1);
            FilePath.Append(TEXT("."));
            FilePath.Append(RelativeFileName);
            FilePath.Append(TEXT("_C"));
            FilePath.InsertAt(0, TEXT("/Game/"));
            UObject* AssetObject = ::StaticLoadObject(UObject::StaticClass(), nullptr, *FilePath);;
            if (AssetObject != nullptr)
            {
                if (bAssetObject)
                {
                    Out.Add(AssetObject);
                }
                else
                {
                    UClass* AssetClass = static_cast<UClass*>(AssetObject);
                    if (AssetClass != nullptr)
                    {
                        Out.Add(AssetClass->GetDefaultObject());
                    }
                }
            }
        }
    }
}

void UEditorExtendFunctions::SavePackageByClass(UClass* Class)
{
	if (Class)
	{
		TArray<UPackage*> PackagesToSave;
		PackagesToSave.AddUnique(Class->GetOutermost());
		FEditorFileUtils::PromptForCheckoutAndSave(PackagesToSave, false, false);
	}
}

FString UEditorExtendFunctions::GetCurrentPersistentMapName()
{
    return GWorld->GetName();
}

AActor* UEditorExtendFunctions::AddActorToCurrentLevel(TSubclassOf<AActor> ActorClass, const FTransform& Transform)
{
	ULevel* CurrentLevel = GWorld->GetCurrentLevel();
	if (ActorClass.Get() && CurrentLevel)
	{
		return GEditor->AddActor(CurrentLevel, ActorClass, Transform);
	}
	return nullptr;
}

FString UEditorExtendFunctions::GetCurrentLevelName()
{
    ULevel* CurrentLevel = GWorld->GetCurrentLevel();
    if (CurrentLevel)
    {
        ULevelScriptBlueprint* LevelScriptBlueprint = CurrentLevel->GetLevelScriptBlueprint();
        if (LevelScriptBlueprint)
        {
            return LevelScriptBlueprint->GetName();
        }
    }
    return FString();
}

void UEditorExtendFunctions::GetSelectedActorsInEditor(TSubclassOf<AActor> ActorClass, TArray<AActor*>& SelectedActors)
{
	SelectedActors.Empty();
	USelection* Selection = GEditor->GetSelectedActors();
	if (Selection)
	{
		for (int32 Idx = 0; Idx < Selection->Num(); ++Idx)
		{
			UObject* SelectedObject = Selection->GetSelectedObject(Idx);
			if (SelectedObject->IsA(ActorClass))
			{
				if (AActor* Actor = Cast<AActor>(SelectedObject))
				{
					SelectedActors.Add(Actor);
				}
			}
		}
	}
}


int32 UEditorExtendFunctions::GetMovieSceneLength(ULevelSequence* InLevelSequence)
{
    check(InLevelSequence);
    UMovieScene* MovieScene = InLevelSequence->GetMovieScene();
    check(MovieScene);

    TRange<FFrameNumber> PlaybackRange = MovieScene->GetPlaybackRange();
    FFrameRate TickResolution = MovieScene->GetTickResolution();
    FFrameRate DisplayRate = MovieScene->GetDisplayRate();

    const FFrameNumber SrcStartFrame = MovieScene::DiscreteInclusiveLower(PlaybackRange);
    const FFrameNumber SrcEndFrame = MovieScene::DiscreteExclusiveUpper(PlaybackRange);

    const FFrameNumber StartingFrame = ConvertFrameTime(SrcStartFrame, TickResolution, DisplayRate).FloorToFrame();
    const FFrameNumber EndingFrame = ConvertFrameTime(SrcEndFrame, TickResolution, DisplayRate).FloorToFrame();

    
    int32 DurationFrames = (EndingFrame - StartingFrame).Value;
    return FQualifiedFrameTime(DurationFrames, MovieScene->GetDisplayRate()).AsSeconds();
}

bool UEditorExtendFunctions::GetFileMD5HashString(const FString& FilePath, FString& OutHashString)
{
	FMD5Hash Hash = FMD5Hash::HashFile(*FilePath);
	if (Hash.IsValid())
	{
		OutHashString = LexToString(Hash);
		return true;
	}
	return false;
}