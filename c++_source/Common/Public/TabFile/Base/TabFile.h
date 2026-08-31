#pragma once

#include "TabFileDataParamSerializer.h"

#define TAB_FILE_IGNORE_LINE_PREFIX '#'
#define TAB_FILE_DATA_DELIM LITERAL(TCHAR, '\t')
#define TAB_FILE_NEW_LINE_DELIM TEXT("\r\n")
#define TAB_FILE_LINE_MAX_CHAR_COUNT 4096
#define TAB_FILE_COLUMN_MAX_COUNT 256
#define TAB_FILE_ROOT_DIR TEXT("GameData")

typedef const void* TTabFileParamInfoKeyType;


//////////////////////////////////////////////////////////////////////////
class COMMON_API FTabFileLoaderBase
{
public:
    virtual bool Open(const TCHAR* Path) = 0;
    virtual bool ReadLine(int LineIndex, const uint8* &LineData, int& OutSize) = 0;
    virtual int GetLineCount() = 0;
    virtual void Close() = 0;
    virtual ~FTabFileLoaderBase() {}
};

class COMMON_API FDefaultTabFileLoader : public FTabFileLoaderBase
{
public:
    FDefaultTabFileLoader();
    virtual ~FDefaultTabFileLoader();
    virtual bool Open(const TCHAR* Path) override;
    virtual bool ReadLine(int LineIndex, const uint8* &LineData, int& OutSize) override;
    virtual int GetLineCount() override;
    virtual void Close() override;

private:
    uint8* MemByteArray;
    TArray<TKeyValuePair<int, int>> Lines;
};

//////////////////////////////////////////////////////////////////////////
class COMMON_API FTabFileSaverBase
{
public:
    virtual bool Open(const TCHAR* Path) = 0;
    virtual bool Write(const uint8* Data, int Size) = 0;
    virtual void Close() = 0;
    virtual ~FTabFileSaverBase() {}
};

class COMMON_API FDefaultTabFileSaver : public FTabFileSaverBase
{
public:
    FDefaultTabFileSaver();
    virtual ~FDefaultTabFileSaver();
    virtual bool Open(const TCHAR* Path) override;
    virtual bool Write(const uint8* Data, int Size) override;
    virtual void Close() override;
private:
    IFileHandle* FileHandle;
};

//////////////////////////////////////////////////////////////////////////
struct COMMON_API FTabFileDataBase
{
public:
    virtual ~FTabFileDataBase() {}
    virtual void RegisterParams() = 0;
    virtual void OnPreLoad() {}
    virtual void OnPostLoad() {}
    virtual void OnAllTabFilesLoaded() {}

    virtual void OnPreSave() {}
    virtual void OnPostSave() {}

public:
    virtual void Register(int Offset, const FString& ColumnName, bool bPartialMatch,
        FTabFileParamReadFunc Reader, FTabFileParamWriteFunc Writer);
};

template<typename T>
struct TTemplateTabFileData : public FTabFileDataBase
{
    typedef T TDataType;
};

//////////////////////////////////////////////////////////////////////////
class COMMON_API FTabFileBase
{
public:
    virtual ~FTabFileBase() {}

    const FString& GetErrorMessage() const { return ErrorMessage; }
    virtual void OnAllTabFilesLoaded() {}    // 所有表读完触发

    virtual bool Load() = 0;
    virtual void Unload() = 0;
    virtual void Reserve(int DataCount) = 0;
    virtual void GetAllData(TArray<const FTabFileDataBase*>& OutData) const = 0;
    virtual const TCHAR* GetPath() const = 0;
    
public:
    static void SetTabFileRootDir(const FString& Path);
    static const FString& GetTabFileRootDir();

protected:    
    virtual TTabFileParamInfoKeyType GetParamInfoKey() const = 0;
    virtual int LoadData(FTabFileLoaderBase* Loader, const TCHAR* Path, const void* ParamInfoKey);
    virtual void OnSelfTabFileLoaded() {}   // 本表读完触发
    virtual void OnColumNameParsed(const TArray<FString>& ColumnNames) {}

protected:
    virtual FTabFileDataBase* NewRawData() = 0;
    virtual void DeleteRawData(FTabFileDataBase* Data) = 0;
    virtual bool AddRawData(FTabFileDataBase* Data) = 0;
    virtual void RemoveRawData(FTabFileDataBase* Data) = 0;
    virtual void OnRawDataLoaded(FTabFileDataBase* Data) = 0;

protected:
    FString ErrorMessage;

public:
    virtual void EditorUnregisterParams();
    virtual void EditorGetAllData(TArray<FTabFileDataBase*>& OutData) { }
    virtual bool EditorSave() { return false; }
protected:
    virtual bool EditorGetAllColumnNames(TArray<FString>& OutColumnNames) { return false; }
    virtual int EditorSaveData(FTabFileSaverBase* Saver, const TCHAR* Path, TTabFileParamInfoKeyType ParamInfoKey);
    virtual void EditorOnPreSave() {}
    virtual void EditorOnPostSave() {}
};

//////////////////////////////////////////////////////////////////////////
#ifdef ENABLE_TAB_FILE_EDITOR
template<typename TKey, typename TData, typename TLoader = FDefaultTabFileLoader, typename TSaver = FDefaultTabFileSaver>
#else
template<typename TKey, typename TData, typename TLoader = FDefaultTabFileLoader, typename TSaver = void>
#endif
class TTemplateTabFile : public FTabFileBase
{
    static_assert(std::is_base_of<FTabFileDataBase, TData>::value,
        "typename TData must derive from FTabFileDataBase");
    static_assert(std::is_base_of<FTabFileLoaderBase, TLoader>::value,
        "typename TLoader must derive from FTabFileLoaderBase");

protected:
    typedef TTemplateTabFile<TKey, TData, TLoader, TSaver> TBasedTemplateTabFileClass;
    typedef TData TDataType;
    typedef typename TData::TMapKeyFuncs TMapKeyFuncs;
    typedef TKey TKeyType;
    typedef TLoader TLoaderType;

public:
    TTemplateTabFile()
        : Loaded(false)
    {

    }
    virtual ~TTemplateTabFile()
    {
    }

    virtual bool Load() override
    {
        if (Loaded)
        {
            return true;
        }

        TLoaderType Loader;
        bool bRet = LoadData(&Loader, GetPath(), GetParamInfoKey()) >= 0;
        if (bRet)
        {
            OnSelfTabFileLoaded();
        }        
        Loaded = true;
        return bRet;
    }

    const TDataType* Find(const TKeyType& Key) const
    {
        auto Ret = DataMap.Find(Key);
        if (Ret)
        {
            return *Ret;
        }
        return nullptr;
    }

    const bool IsLoaded() const
    {
        return Loaded;
    }

protected:
    virtual TTabFileParamInfoKeyType GetParamInfoKey() const override
    {
        static char s_Key;
        return &s_Key;
    }
    virtual void OnRawDataLoaded(FTabFileDataBase* Data) override
    {
        Data->OnPostLoad();
    }

protected:
    typedef TMap<TKeyType, TDataType*, FDefaultSetAllocator, TMapKeyFuncs> TDataMap;
    TDataMap DataMap;
    bool Loaded;

    //////////////////////////////////////////////////////////////////////////
//#ifndef ENABLE_TAB_FILE_EDITOR
    // 发布时不允许删除元素
//public:
//    TDataType* Find(const TKeyType& Key)
//    {
//        auto Ret = DataMap.Find(Key);
//        if (Ret)
//        {
//            return *Ret;
//        }
//        return nullptr;
//    }
//    virtual void Unload() override
//    {
//        DataMap.Empty();
//        DataArray.Empty();
//        Loaded = false;
//    }
//    virtual void Reserve(int DataCount) override
//    {
//        DataMap.Reserve(DataMap.Num() + DataCount);
//        DataArray.Reserve(DataArray.Num() + DataCount);
//    }
//    virtual void GetAllData(TArray<const FTabFileDataBase*>& OutData) const override
//    {
//        int iCount = DataArray.Num();
//        OutData.Reserve(iCount);
//        for (int ii = 0; ii < iCount; ii++)
//        {
//            OutData.Add(&DataArray[ii]);
//        }
//    }
//protected:
//    virtual FTabFileDataBase* NewRawData() override
//    {
//        check(DataArray.GetSlack() > 0);
//        DataArray.AddDefaulted();
//        return &DataArray.Last();
//    }
//    virtual void DeleteRawData(FTabFileDataBase* Data) override
//    {
//    }
//    virtual bool AddRawData(FTabFileDataBase* Data) override
//    {
//        auto TabData = static_cast<TDataType*>(Data);
//        TKeyType Key = TabData->GetID();
//        if (Find(Key))
//        {
//            return false;
//        }
//        DataMap.Add(Key, TabData);
//        return true;
//    }
//    virtual void RemoveRawData(FTabFileDataBase* Data) override
//    {
//        check(false);
//    }
//    virtual void OnAllTabFilesLoaded() override
//    {
//        int iCount = DataArray.Num();
//        for (int ii=0; ii<iCount; ii++)
//        {
//            DataArray[ii].OnAllTabFilesLoaded();
//        }
//    }
//private:
//    TArray<TDataType> DataArray;
    //////////////////////////////////////////////////////////////////////////
//#else
public:
    virtual void Unload() override
    {
        for (auto Iterator = DataMap.CreateIterator(); Iterator; ++Iterator)
        {
            delete Iterator->Value;
        }
        DataMap.Empty();
        Loaded = false;
    }
    virtual void Reserve(int DataCount) override
    {
        DataMap.Reserve(DataMap.Num() + DataCount);
    }
    virtual void GetAllData(TArray<const FTabFileDataBase*>& OutData) const override
    {
        for (auto Iterator = DataMap.CreateConstIterator(); Iterator; ++Iterator)
        {
            OutData.Add(Iterator->Value);
        }
    }
    virtual void OnAllTabFilesLoaded() override
    {
        for (auto Iterator = DataMap.CreateConstIterator(); Iterator; ++Iterator)
        {
            Iterator->Value->OnAllTabFilesLoaded();
        }
    }
protected:
    virtual FTabFileDataBase* NewRawData() override
    {
        return new TDataType();
    }
    virtual void DeleteRawData(FTabFileDataBase* Data) override
    {
        check(Data);
        RemoveRawData(Data);
        delete Data;
    }
    virtual bool AddRawData(FTabFileDataBase* Data) override
    {
        auto TabData = static_cast<TDataType*>(Data);
        const TKeyType& Key = TabData->GetID();
        if (Find(Key))
        {
            return false;
        }
        DataMap.Add(Key, TabData);
        return true;
    }
    virtual void RemoveRawData(FTabFileDataBase* Data) override
    {
        check(Data);
        auto TabData = static_cast<TDataType*>(Data);
        DataMap.Remove(TabData->GetID());
    }

#ifdef ENABLE_TAB_FILE_EDITOR
    static_assert(std::is_base_of<FTabFileSaverBase, TSaver>::value,
        "typename TSaver must derive from FTabFileSaverBase");
    typedef TSaver TSaverType;
public:
    virtual TDataType* EditorNewData()
    {
        return static_cast<TDataType*>(NewRawData());
    }
    virtual bool EditorAddData(TDataType* Data)
    {
        return AddRawData(Data);
    }
    virtual void EditorRemoveData(TDataType* Data)
    {
        RemoveRawData(Data);
    }
    virtual void EditorDeleteData(TDataType* Data)
    {
        DeleteRawData(Data);
    }
    virtual void EditorGetAllData(TArray<FTabFileDataBase*>& OutData) override
    {
        OutData.Reserve(DataMap.Num());
        for (auto Iterator = DataMap.CreateIterator(); Iterator; ++Iterator)
        {
            OutData.Add(Iterator->Value);
        }
    }
    virtual bool EditorSave() override
    {
        TSaverType Saver;
        int iDataCount = EditorSaveData(&Saver, GetPath(), GetPath());
        EditorOnPostSave();
        return iDataCount >= 0;
    }
#endif
};

//////////////////////////////////////////////////////////////////////////
template<class T>
class FTabFileSingleton
{
public:
    static T& GetSingleton()
    {
        static T s_Singleton;
        return s_Singleton;
    }
};


template<typename TKey, typename TData>
struct TTabFileKeyValuePairMapKeyFuncs : TDefaultMapKeyFuncs<TKey, TData, false>
{ 
    //////////////////////////////////////////////////////////////////////////
    typedef typename TDefaultMapKeyFuncs<TKey, TData, false>::KeyInitType KeyInitType;
    typedef typename TDefaultMapKeyFuncs<TKey, TData, false>::ElementInitType ElementInitType;

    static FORCEINLINE void HashCombine(uint32& Seed) { }

    template <typename T, typename... Rest> 
    static FORCEINLINE void HashCombine(uint32& Seed, const T& v, Rest... rest)
    { 
        // 抄的boost::hash_combine
        Seed ^= GetTypeHash(v) + 0x9e3779b9 + (Seed << 6) + (Seed >> 2);
        HashCombine(Seed, rest...);
    }
    static FORCEINLINE KeyInitType GetSetKey(ElementInitType Element)
    {
        return Element.Key;
    }
    static FORCEINLINE bool Matches(KeyInitType A, KeyInitType B)
    {
        return A.Key == B.Key && A.Value == B.Value;
    }
    static FORCEINLINE uint32 GetKeyHash(KeyInitType Key)
    {
        uint32 Ret = 0;
        HashCombine(Ret, Key.Key, Key.Value);
        return Ret;
    }
};

//////////////////////////////////////////////////////////////////////////
// 参数相关
// 普通参数注册
#ifdef ENABLE_TAB_FILE_EDITOR
#define TAB_FILE_DATA_REGISTER(Param, ColumnName) \
    Register(offsetof(TDataType, Param), ColumnName, false,\
        FTabFileDataParamHelper::GetReader(Param), FTabFileDataParamHelper::GetWriter(Param));
#else
#define TAB_FILE_DATA_REGISTER(Param, ColumnName) \
    Register(offsetof(TDataType, Param), ColumnName, false, FTabFileDataParamHelper::GetReader(Param), nullptr);
#endif


// 自定义读
// ReadMethod: bool Func(const FString& ColumnName, const TCHAR* RawData)
// WriteMethod: bool Func(const FString& ColumnName, FString& OutValue)
#define TAB_FILE_DATA_REGISTER_CUSTOM_READ(ColumnName, ReadMethod) \
    Register(-1, ColumnName, false,\
        [](void* RawData, unsigned int, const FString& Column, const TCHAR* RawString) { return static_cast<TDataType*>(RawData)->ReadMethod(Column, RawString);}, nullptr);

// 自定义读，列名部分匹配，适合有规律读取
#define TAB_FILE_DATA_REGISTER_CUSTOM_READ_PARTIAL_MATCH(ColumnName, ReadMethod) \
    Register(-1, ColumnName, true,\
        [](void* RawData, unsigned int, const FString& Column, const TCHAR* RawString) { return static_cast<TDataType*>(RawData)->ReadMethod(Column, RawString);}, nullptr);

// 自定义读写
#define TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE(ColumnName, ReadMethod, WriteMethod) \
    Register(-1, ColumnName, false, \
        [](void* RawData, unsigned int, const FString& Column, const TCHAR* RawString) { return static_cast<TDataType*>(RawData)->ReadMethod(Column, RawString);}, \
        [](void* RawData, unsigned int, const FString& Column, FString& RawString) { return static_cast<TDataType*>(RawData)->WriteMethod(Column, RawString);});

// 自定义读写，不指定任何列名，注意：此种方式与上面所有方式互斥，如果此种方式与其他共存则会报错，所以要小心使用
#define TAB_FILE_DATA_REGISTER_CUSTOM_READ_NOCOLUMN(ReadMethod) \
    TAB_FILE_DATA_REGISTER_CUSTOM_READ("", ReadMethod)

// 自定义读写，不指定任何列名，注意：此种方式与上面所有方式互斥，如果此种方式与其他共存则会报错，所以要小心使用
#define TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE_NOCOLUMN(ReadMethod, WriteMethod) \
    TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("", ReadMethod, WriteMethod)


//////////////////////////////////////////////////////////////////////////
// Key 相关
// 单key宏
#define TAB_FILE_DATA_SINGLE_KEY(KeyType1, Key1) \
    public: \
        typedef KeyType1 TKeyType; \
        const TKeyType& GetID() const { return Key1; } \
        typedef TDefaultMapKeyFuncs<TKeyType, TDataType*, false> TMapKeyFuncs;

// 双key宏
#define TAB_FILE_DATA_DOUBLE_KEY(KeyType1, Key1, KeyType2, Key2) \
    public: \
        typedef KeyType1 TKeyType1; \
        typedef KeyType2 TKeyType2; \
        typedef TKeyValuePair<TKeyType1, TKeyType2> TKeyType; \
        const TKeyType& GetID() const \
        { \
            static TKeyType s_Key; \
            s_Key.Key = Key1; s_Key.Value = Key2; \
            return s_Key; \
        } \
        typedef TTabFileKeyValuePairMapKeyFuncs<TKeyType, TDataType*> TMapKeyFuncs;

//////////////////////////////////////////////////////////////////////////
// Class相关
// 声明tabfile data class
#define TAB_FILE_DATA(ExportTag, StructName) \
    struct ExportTag StructName : public TTemplateTabFileData<StructName>

// 声明tabfile class
#define TAB_FILE(ExportTag, ClassName, DataType) \
    class ExportTag ClassName : public TTemplateTabFile<DataType::TKeyType, DataType>, public FTabFileSingleton<ClassName>

// 自带path的声明
#define TAB_FILE_WITH_PATH(ExportTag, ClassName, DataType, Path) \
    TAB_FILE(ExportTag, ClassName, DataType) \
    { \
        virtual const TCHAR* GetPath() const override { return TEXT(Path); } \
    };
    