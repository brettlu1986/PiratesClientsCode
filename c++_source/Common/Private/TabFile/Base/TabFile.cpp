#include "TabFile/Base/TabFile.h"
#include "Common.h"
#include "TabFile/Base/TabFileManagerBase.h"

DEFINE_LOG_CATEGORY_STATIC(TabFileLog, Log, All);

class FTableParamInfoHelper
{
public:
    struct FParamInfo
    {
        int Offset;
        FString ColumnName;
        FTabFileParamReadFunc ReadFunc;
        FTabFileParamWriteFunc WriteFunc;
        bool PartialMatch;

        FParamInfo()
            : Offset(0)
            , ReadFunc(nullptr)
            , WriteFunc(nullptr)
            , PartialMatch(false)
        {
        }
    };

    typedef TArray<FParamInfo> FParamInfoArray;

public:
    FTableParamInfoHelper()
        : CurrentParamInfoArray(nullptr)
    {

    }

    const FParamInfoArray* SetCurrentTabFileParamInfo(TTabFileParamInfoKeyType ParamInfoKey)
    {
        CurrentParamInfoArray = ParamInfoMap.Find(ParamInfoKey);
        return CurrentParamInfoArray;
    }

    void CreateTabFileParamInfo(TTabFileParamInfoKeyType ParamInfoKey)
    {
        ParamInfoMap.FindOrAdd(ParamInfoKey);
    }

    void DestroyTabFileParamInfo(TTabFileParamInfoKeyType ParamInfoKey)
    {
        ParamInfoMap.Remove(ParamInfoKey);
    }

    bool ReadParam(FTabFileDataBase* Data, const FParamInfo& Info, const TCHAR* RawValue)
    {
        check(Info.ReadFunc);
        return Info.ReadFunc(Data, Info.Offset, Info.ColumnName, RawValue);
    }

    bool WriteParam(FTabFileDataBase* Data, const FParamInfo& Info, FString& RawValue)
    {
        check(Info.WriteFunc);
        return Info.WriteFunc(Data, Info.Offset, Info.ColumnName, RawValue);
    }

    void Clear()
    {
        ParamInfoMap.Empty();
    }

    void RegisterParam(int Offset, const FString& ColumnName, bool bPartialMatch,
        const FTabFileParamReadFunc& Reader, const FTabFileParamWriteFunc& Writer)
    {
        FParamInfo& Info = CreateInfo(Offset, ColumnName, bPartialMatch);
        Info.ReadFunc = Reader;
        Info.WriteFunc = Writer;
    }

private:
    FParamInfo& CreateInfo(int Offset, const FString& ColumnName, bool bPartialMatch)
    {
        check(Offset >= 0 || Offset == -1); // offset 如果为-1，说明是自定义读写
        //check(Offset < 0xffffff);
        check(CurrentParamInfoArray);
        CurrentParamInfoArray->AddDefaulted();
        FParamInfo& Info = CurrentParamInfoArray->Last();
        Info.Offset = Offset;
        Info.ColumnName = ColumnName;
        Info.PartialMatch = bPartialMatch;
        return Info;
    }

private:
    typedef TMap<TTabFileParamInfoKeyType, FParamInfoArray> FTableParamMap;
    FTableParamMap ParamInfoMap;
    FParamInfoArray* CurrentParamInfoArray;
};
static FTableParamInfoHelper s_ParamHelper;

//////////////////////////////////////////////////////////////////////////
void FTabFileDataBase::Register(int Offset, const FString& ColumnName, bool bPartialMatch,
    FTabFileParamReadFunc Reader, FTabFileParamWriteFunc Writer)
{
    s_ParamHelper.RegisterParam(Offset, ColumnName, bPartialMatch, Reader, Writer);
}

//////////////////////////////////////////////////////////////////////////
FDefaultTabFileLoader::FDefaultTabFileLoader()
    : MemByteArray(nullptr)
{
}

FDefaultTabFileLoader::~FDefaultTabFileLoader()
{
    Close();
}

bool FDefaultTabFileLoader::Open(const TCHAR* Path)
{
    IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();
    IFileHandle* FileHandle = PlatformFile.OpenRead(Path);
    if (!FileHandle)
    {
        return false;
    }
    int64 FileSize = FPlatformFileManager::Get().GetPlatformFile().FileSize(Path);
    MemByteArray = reinterpret_cast<uint8*>(FMemory::Malloc(FileSize));
    if (!FileHandle->Read(MemByteArray, FileSize))
    {
        return false;
    }

    Lines.Empty();
    int64 iLineStart = 0;
    int64 iLineEnd = 0;
    const uint8* Chars = MemByteArray;
    int LineStart = 0;
    for (int LineEnd = 0; LineEnd < FileSize; LineEnd++)
    {
        if (/*Chars[LineEnd] == 0x0d
            && */(LineEnd + 1 >= FileSize || Chars[LineEnd + 1] == 0x0a))
        {
            // new line
            if (LineStart != LineEnd)
            {
                Lines.AddDefaulted();
                auto& Info = Lines.Last();
                Info.Key = LineStart;
                if (Chars[LineEnd] == 0x0d)
                {
                    Info.Value = LineEnd - LineStart;
                }
                else
                {
                    Info.Value = LineEnd - LineStart + 1;
                }                
            }

            LineStart = LineEnd + 2;
            ++LineEnd;   // 跳过下一个字符
        }
    }

    if (LineStart < FileSize)
    {
        Lines.AddDefaulted();
        auto& Info = Lines.Last();
        Info.Key = LineStart;
        Info.Value = FileSize - LineStart;
    }

    delete FileHandle;
    return true;
}

bool FDefaultTabFileLoader::ReadLine(int iLineIndex, const uint8* &LineData, int& OutSize)
{
    if (iLineIndex < 0 || iLineIndex >= Lines.Num())
    {
        return false;
    }

    LineData = &MemByteArray[Lines[iLineIndex].Key];
    OutSize = Lines[iLineIndex].Value;
    return true;
}

int FDefaultTabFileLoader::GetLineCount()
{
    return Lines.Num();
}

void FDefaultTabFileLoader::Close()
{
    if (MemByteArray)
    {
        FMemory::Free(MemByteArray);
        MemByteArray = nullptr;
    }
    Lines.Empty();
}

//////////////////////////////////////////////////////////////////////////
static FString TabFileRootDir(TAB_FILE_ROOT_DIR);
void FTabFileBase::SetTabFileRootDir(const FString& Path)
{
    TabFileRootDir = Path;
}

const FString& FTabFileBase::GetTabFileRootDir()
{
    return TabFileRootDir;
}

int FTabFileBase::LoadData(FTabFileLoaderBase* Loader, const TCHAR* Path, TTabFileParamInfoKeyType ParamInfoKey)
{
    check(Path && ParamInfoKey);
    ErrorMessage = "";
    FString FullPath = FPaths::ProjectContentDir() / GetTabFileRootDir() / Path;
    if (!Loader->Open(*FullPath))
    {
        ErrorMessage = FString::Printf(TEXT("Open tabfile[%s] failed."), Path);
        return -1;
    }

    const FTableParamInfoHelper::FParamInfoArray* ParamInfoArray = s_ParamHelper.SetCurrentTabFileParamInfo(ParamInfoKey);
    bool bNeedRegisterParam = !ParamInfoArray;

    int RealDataLineCount = 0;
    int RawLineCount = Loader->GetLineCount();
    const uint8* LineRawData = nullptr;
    int LineRawDataSize = 0;

    // 统计真实数据行，上来滤掉第一行
    for (int ii=1; ii<RawLineCount; ii++)
    {
        Loader->ReadLine(ii, LineRawData, LineRawDataSize);
        if (LineRawData[0] != 0 && LineRawData[0] != TAB_FILE_IGNORE_LINE_PREFIX)
        {
            ++RealDataLineCount;
        }
    }
    if (RealDataLineCount == 0)
    {
        return 0;
    }
    Reserve(RealDataLineCount);

    // 开始解析各行数据
    TCHAR LineData[TAB_FILE_LINE_MAX_CHAR_COUNT] = {};
    const FTableParamInfoHelper::FParamInfo* ColumnInfo[TAB_FILE_COLUMN_MAX_COUNT] = {};
    int iColumnCount = 0;
    TArray<FString> ColumnNames;
    bool bInitColumnInfo = false;
    for(int LineIndex = 0; LineIndex < RawLineCount; LineIndex++)
    {
        Loader->ReadLine(LineIndex, LineRawData, LineRawDataSize);
        if (LineRawData[0] == 0
            || LineRawData[0] == TAB_FILE_IGNORE_LINE_PREFIX)
        {
            continue;
        }

        int NewDataLen = FUTF8ToTCHAR_Convert::ConvertedLength((const ANSICHAR*)LineRawData, LineRawDataSize);
        check(NewDataLen + 1 <= TAB_FILE_LINE_MAX_CHAR_COUNT);
        FUTF8ToTCHAR_Convert::Convert(LineData, NewDataLen, (const ANSICHAR*)LineRawData, LineRawDataSize);
        LineData[NewDataLen] = 0;

        if (iColumnCount == 0)
        {
            // parse first line
            FString TempString(LineData);
            TCHAR Delim[2] = {};
            Delim[0] = TAB_FILE_DATA_DELIM;
            TempString.ParseIntoArray(ColumnNames, Delim);
            iColumnCount = ColumnNames.Num();
            check(iColumnCount < TAB_FILE_COLUMN_MAX_COUNT);
            OnColumNameParsed(ColumnNames);
        }
        else
        {
            // 这里的写法很怪，如果没有注册过，则在new完第一个data后开始注册
            // 这么写的目的是为了写子类data时可以尽量少的写代码，可以通过成员变量类型直接萃取出reader和writer
            // 按照以前的写法是写在tabfile的init里，但那样的话data里的成员变量的类型就得都写一遍，那样比较麻烦
            FTabFileDataBase* Data = NewRawData();

            // 初始化各种注册信息
            if (!bInitColumnInfo)
            {
                bInitColumnInfo = true;

                if (bNeedRegisterParam)
                {
                    // 这里注册param，因为有bInitColumnInfo在所以bNeedRegisterParam不用管
                    s_ParamHelper.CreateTabFileParamInfo(ParamInfoKey);
                    ParamInfoArray = s_ParamHelper.SetCurrentTabFileParamInfo(ParamInfoKey);
                    Data->RegisterParams();
                    Data->OnPreLoad();
                }
                
                int iParamCount = ParamInfoArray->Num();
                if (iParamCount == 1 && (*ParamInfoArray)[0].ColumnName.Len() == 0)
                {
                    // 完全自定义读，不指定任何ColumnName的情况
                    const FTableParamInfoHelper::FParamInfo* Info = &(*ParamInfoArray)[0];
                    for (int ii=0; ii<iColumnCount; ii++)
                    {
                        ColumnInfo[ii] = Info;
                    }
                }
                else
                {
                    // 将paraminfo和Column对接起来，之后就可以直接按照索引顺序解析
                    for (int ii = 0; ii < iParamCount; ii++)
                    {
                        bool bFind = false;
                        const FTableParamInfoHelper::FParamInfo& ParamInfo = (*ParamInfoArray)[ii];
                        check(ParamInfo.ColumnName.Len() > 0);
                        if (ParamInfo.PartialMatch)
                        {
                            for (int jj = 0; jj < iColumnCount; jj++)
                            {
                                if (INDEX_NONE != ColumnNames[jj].Find(*ParamInfo.ColumnName))
                                {
                                    ColumnInfo[jj] = &ParamInfo;
                                    bFind = true;
                                }
                            }
                        }
                        else
                        {
                            for (int jj = 0; jj < iColumnCount; jj++)
                            {
                                if (ParamInfo.ColumnName == ColumnNames[jj])
                                {
                                    ColumnInfo[jj] = &ParamInfo;
                                    bFind = true;
                                    break;
                                }
                            }
                        }
                        if (!bFind)
                        {
                            DeleteRawData(Data);
                            ErrorMessage = FString::Printf(TEXT("The tabfile[%s] read failed, the column[%s] can not find."),
                                Path, *ParamInfo.ColumnName);
                            return -1;
                        } // end if (!bFind)
                    } // end for (int ii=0; ii<iParamCount; ii++)
                } // end if (iParamCount == 1 && (*ParamInfoArray)[0].ColumnName.Len() == 0)
            } // end if (!bInitColumnInfo)

            // 开始解析数据
            bool bBlankLine = true;
            bool bReaded = false;
            TCHAR* Start = &LineData[0];
            int ColumnIndex = 0;
            for (TCHAR* End = Start; End; ++End)
            {
                if (*End == TAB_FILE_DATA_DELIM
                    || *End == 0)
                {
                    bool bLineEnd = (*End == 0);
                    *End = 0;

                    check(ColumnIndex < iColumnCount);
                    auto ParamInfo = ColumnInfo[ColumnIndex];
                    if (ParamInfo)
                    {
                        // 如果找到注册过的列，则解析之
                        if (!s_ParamHelper.ReadParam(Data, *ParamInfo, Start))
                        {
                            DeleteRawData(Data);
                            ErrorMessage = FString::Printf(TEXT("The tabfile[%s] parse line[%d] column[%s] failed."),
                                Path, LineIndex+1, *ParamInfo->ColumnName);
                            return -1;
                        }

                        if (Start[0])
                        {
                            bBlankLine = false;
                        }

                        bReaded = true;
                    }

                    if (bLineEnd)
                    {
                        if (!(Start == End || ColumnIndex == iColumnCount - 1)) {
                            UE_LOG(TabFileLog, Log, TEXT("Load tabfile failed: %s line[%d] column[%d] columnCount[%d]"),
                                Path, LineIndex + 1, ColumnIndex, iColumnCount);
                        }

                        check(Start == End || ColumnIndex == iColumnCount - 1);
                        break;
                    }
                    else
                    {
                        Start = End + 1;
                        ++ColumnIndex;
                    } // end if (bLineEnd)
                } // end if (*End == TAB_FILE_DATA_DELIM
            } // end for (; End; ++End)

            if (!bReaded || bBlankLine)
            {
                if (Data)
                {
                    DeleteRawData(Data);
                }
            }
            else
            {
                OnRawDataLoaded(Data);
                if (!AddRawData(Data))
                {
                    DeleteRawData(Data);
                    ErrorMessage = FString::Printf(TEXT("The tabfile[%s] read line[%d] failed, because the data can not be added, may be key is duplicated?"),
                        Path, LineIndex + 1);
                    return -1;
                }
            }
        }
    }
    return RealDataLineCount;
}

void FTabFileBase::EditorUnregisterParams()
{
    s_ParamHelper.DestroyTabFileParamInfo(GetParamInfoKey());
}

//////////////////////////////////////////////////////////////////////////
FDefaultTabFileSaver::FDefaultTabFileSaver()
    : FileHandle(nullptr)
{
}

FDefaultTabFileSaver::~FDefaultTabFileSaver()
{
    Close();
}

bool FDefaultTabFileSaver::Open(const TCHAR* Path)
{
    IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();
    FileHandle = PlatformFile.OpenWrite(Path);
    return FileHandle != nullptr;
}

bool FDefaultTabFileSaver::Write(const uint8* Data, int Len)
{
    if (!FileHandle)
    {
        return false;
    }
    return FileHandle->Write(Data, Len);
}

void FDefaultTabFileSaver::Close()
{
    if (FileHandle)
    {
        delete FileHandle;
        FileHandle = nullptr;
    }
}

//////////////////////////////////////////////////////////////////////////
int FTabFileBase::EditorSaveData(FTabFileSaverBase* Saver, const TCHAR* Path, TTabFileParamInfoKeyType ParamInfoKey)
{
    EditorOnPreSave();
    ErrorMessage = "";

    const TCHAR* ShortPath = GetPath();
    if (ShortPath == nullptr)
    {
        ShortPath = Path;
    }

    FString FullPath = FPaths::ProjectContentDir() / TAB_FILE_ROOT_DIR / ShortPath;
    if (!Saver->Open(*FullPath))
    {
        ErrorMessage = FString::Printf(TEXT("Open tabfile[%s] failed."), Path);
        return -1;
    }

    const FTableParamInfoHelper::FParamInfoArray* ParamInfoArray = s_ParamHelper.SetCurrentTabFileParamInfo(ParamInfoKey);
    if (!ParamInfoArray)
    {
        // 编辑器这里就不管了，弄个临时变量产生paraminfo，否则表头写不出来
        FTabFileDataBase* TempData = NewRawData();
        s_ParamHelper.CreateTabFileParamInfo(ParamInfoKey);
        ParamInfoArray = s_ParamHelper.SetCurrentTabFileParamInfo(ParamInfoKey);
        TempData->RegisterParams();
        delete TempData;
    }

    FString FileData;
    TArray<FTabFileDataBase*> AllData;
    EditorGetAllData(AllData);   

    // 先写表头
    int iColumnCount = 0;
    TArray<FString> OutColumnNames;
    if (EditorGetAllColumnNames(OutColumnNames))
    {
        iColumnCount = OutColumnNames.Num();
        for (int ii = 0; ii < iColumnCount; ii++)
        {
            if (ii < iColumnCount - 1)
            {
                FileData += FString::Printf(TEXT("%s\t"), *OutColumnNames[ii]);
            }
            else
            {
                FileData += FString::Printf(TEXT("%s\r\n"), *OutColumnNames[ii]);
            }
        }
    }
    else
    {
        iColumnCount = ParamInfoArray->Num();
        for (int ii = 0; ii < iColumnCount; ii++)
        {
            if (ii < iColumnCount - 1)
            {
                FileData += FString::Printf(TEXT("%s\t"), *(*ParamInfoArray)[ii].ColumnName);
            }
            else
            {
                FileData += FString::Printf(TEXT("%s\r\n"), *(*ParamInfoArray)[ii].ColumnName);
            }
        }
    }

    // 在写数据
    FString RawStringData;
    int iDataCount = AllData.Num();
    for (int ii=0; ii<iDataCount; ii++)
    {
        FTabFileDataBase* Data = AllData[ii];
        check(Data);
        Data->OnPreSave();

        for (int jj = 0; jj < iColumnCount; jj++)
        {
            if (!s_ParamHelper.WriteParam(Data, (*ParamInfoArray)[jj], RawStringData))
            {
                ErrorMessage = FString::Printf(TEXT("The tabfile[%s] write line[%d] column[%s] failed."),
                    Path, ii+1, *(*ParamInfoArray)[jj].ColumnName);
                return false;
            }
            FileData += RawStringData;
            if (jj < iColumnCount - 1)
            {
                FileData += TAB_FILE_DATA_DELIM;
            }
            else
            {
                FileData += TAB_FILE_NEW_LINE_DELIM;
            }            
        }

        Data->OnPostSave();
    }

    FTCHARToUTF8 Converter(*FileData, FileData.Len());
    if (!Saver->Write((uint8*)Converter.Get(), Converter.Length()))
    {
        ErrorMessage = FString::Printf(TEXT("Write tabfile[%s] failed."), *Path);
        return -1;
    }
    return iDataCount;
}

#ifdef ENABLE_TAB_FILE_EDITOR
TMap<FTabFileBase*, bool> FTabFileManagerBase::EditorTabFilesHolder;
#endif

//////////////////////////////////////////////////////////////////////////
bool FTabFileManagerBase::Init()
{
    FTabFileBase::SetTabFileRootDir(TEXT("GameDataGenerated"));
    RegisterFiles();
    return Load();
}

void FTabFileManagerBase::Uninit()
{
    Unload();

#ifndef ENABLE_TAB_FILE_EDITOR
    UnregisterAll();
#endif
    FTabFileBase::SetTabFileRootDir(TAB_FILE_ROOT_DIR);
}

bool FTabFileManagerBase::Load()
{
    int iCount = TabFiles.Num();
    for (int ii=0; ii<iCount; ii++)
    {
#ifdef ENABLE_TAB_FILE_EDITOR
        if (EditorTabFilesHolder.Find(TabFiles[ii]))
        {
            continue;
        }
#endif
        if (!TabFiles[ii]->Load())
        {
            UE_LOG(TabFileLog, Log, TEXT("Load tabfile failed: %s"), *TabFiles[ii]->GetErrorMessage());
            return false;
        }
    }

    for (int ii=0; ii<iCount; ii++)
    {
#ifdef ENABLE_TAB_FILE_EDITOR
        if (EditorTabFilesHolder.Find(TabFiles[ii]))
        {
            continue;
        }
#endif
        TabFiles[ii]->OnAllTabFilesLoaded();

        const TCHAR* Path = TabFiles[ii]->GetPath();
        UE_LOG(TabFileLog, Log, TEXT("Load tabfile success: %s"), Path != nullptr ? Path : TEXT("NoNamedFile"));
    }
    return true;
}

void FTabFileManagerBase::Unload()
{
    int iCount = TabFiles.Num();
    for (int ii = 0; ii < iCount; ii++)
    {
#ifdef ENABLE_TAB_FILE_EDITOR
        if (EditorTabFilesHolder.Find(TabFiles[ii]))
        {
            continue;
        }
#endif
        TabFiles[ii]->Unload();
    }
}

void FTabFileManagerBase::UnregisterAll()
{
    TabFiles.Empty();
    s_ParamHelper.Clear();
}

#ifdef ENABLE_TAB_FILE_EDITOR
bool FTabFileManagerBase::EditorLoadSingleTabFile(FTabFileBase* TabFile)
{
    check(TabFile);
    bool& bTemp = EditorTabFilesHolder.FindOrAdd(TabFile);
    bTemp = true;

    if (!TabFile->Load())
    {
        UE_LOG(TabFileLog, Log, TEXT("Load tabfile failed: %s"), *TabFile->GetErrorMessage());
        return false;
    }
    TabFile->OnAllTabFilesLoaded();

    const TCHAR* Path = TabFile->GetPath();
    UE_LOG(TabFileLog, Log, TEXT("Load tabfile success: %s"), Path != nullptr ? Path : TEXT("NoNamedFile"));
    return true;
}

void FTabFileManagerBase::EditorUnloadSingleTabFile(FTabFileBase* TabFile)
{
    check(TabFile);
    EditorTabFilesHolder.Remove(TabFile);

    TabFile->Unload();
}
#endif