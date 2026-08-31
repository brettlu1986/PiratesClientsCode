#pragma once
#include "TabFile/Base/TabFile.h"

#define TAB_FILE_GAME_AVATAR_PART_DATA_DELIM TEXT("=")

TAB_FILE_DATA(COMMON_API, FGameAvatarPartTabFileData)
{
    int ID;
    TArray<TKeyValuePair<FName, FString>> Data;

#if WITH_EDITOR
    FString Description;
#endif

    FGameAvatarPartTabFileData()
        : ID(0)
    {}

    TAB_FILE_DATA_SINGLE_KEY(int, ID);

    virtual void RegisterParams() override
    {
        TAB_FILE_DATA_REGISTER(ID, "id");

#if WITH_EDITOR
        TAB_FILE_DATA_REGISTER(Description, "description");
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data1", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data2", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data3", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data4", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data5", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data6", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data7", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data8", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data9", OnReadData, OnWriteData);
        TAB_FILE_DATA_REGISTER_CUSTOM_READWRITE("data10", OnReadData, OnWriteData);
#else
        TAB_FILE_DATA_REGISTER_CUSTOM_READ_PARTIAL_MATCH("data", OnReadData);
#endif
    }

    bool OnReadData(const FString& ColumnName, const TCHAR* RawValue)
    {
        if (RawValue[0] == 0)
        {
            return true;
        }

        const TCHAR* SubString = FCString::Strstr(RawValue, TAB_FILE_GAME_AVATAR_PART_DATA_DELIM);
        if (!SubString)
        {
            return false;
        }

        TCHAR szKey[64] = {};
        check(SubString - RawValue < 63);
        FCString::Strncpy(szKey, RawValue, SubString - RawValue + 1);
        Data.AddDefaulted();
        auto& Pair = Data.Last();
        Pair.Key = szKey;
        Pair.Value = SubString + 1;
        return true;
    }

#if WITH_EDITOR
    bool OnWriteData(const FString& ColumnName, FString& RawValue)
    {
        int Index = FCString::Atoi(*ColumnName + 4);
        --Index;
        check(Index >= 0);
        if (Index >= Data.Num())
        {
            RawValue.Empty();
        }
        else
        {
            auto& KeyValue = Data[Index];
            RawValue = FString::Printf(TEXT("%s=%s"), *KeyValue.Key.ToString(), *KeyValue.Value);
        }
        return true;
    }
#endif
};


TAB_FILE(COMMON_API, FGameAvatarPartTabFile, FGameAvatarPartTabFileData)
{
public:
    virtual const TCHAR* GetPath() const override
    {
        return nullptr;
    }

    void AddPath(const FString& Path)
    {
        Paths.AddUnique(Path);
    }

    void RemovePath(const FString& Path)
    {
        Paths.Remove(Path);
    }

private:
    TArray<FString> Paths;

#ifndef ENABLE_TAB_FILE_EDITOR
public:
    virtual void Unload() override
    {
        Paths.Empty();
        TBasedTemplateTabFileClass::Unload();
    }

    virtual bool Load() override
    {
        if (Loaded)
        {
            return true;
        }
        bool bRet = true;
        int PathCount = Paths.Num();
        for (int PathIndex = 0; PathIndex<PathCount; PathIndex++)
        {
            FDefaultTabFileLoader Loader;
            bRet = LoadData(&Loader, *Paths[PathIndex], GetParamInfoKey()) >= 0;
            if (!bRet)
            {
                break;
            }
        }
        OnSelfTabFileLoaded();
        Loaded = true;
        return bRet;
    }
#else
public:
    typedef TMap<int, FGameAvatarPartTabFileData*> TTabFileAllDataMap;

    virtual void Unload() override
    {
        TabFiles.Empty();
        Paths.Empty();
        TBasedTemplateTabFileClass::Unload();
    }

    virtual bool Load() override
    {
        if (Loaded)
        {
            return true;
        }
        bool bRet = true;
        int PathCount = Paths.Num();
        for (int PathIndex = 0; PathIndex < PathCount; PathIndex++)
        {
            FDefaultTabFileLoader Loader;
            CurrentEditorPath = *Paths[PathIndex];
            TTabFileAllDataMap* Map = TabFiles.Find(CurrentEditorPath);
            if (!Map)
            {
                TabFiles.Add(CurrentEditorPath);
            }
            bRet = LoadData(&Loader, *Paths[PathIndex], GetParamInfoKey()) >= 0;
            if (!bRet)
            {
                break;
            }
        }
        CurrentEditorPath = FName();
        OnSelfTabFileLoaded();
        Loaded = true;
        return bRet;
    }

    virtual void EditorGetAllData(TArray<FTabFileDataBase*>& OutData) override
    {
        TTabFileAllDataMap* Map = TabFiles.Find(CurrentEditorPath);
        check(Map);

        OutData.Reserve(Map->Num());
        for (auto Iter = Map->CreateIterator(); Iter; ++Iter)
        {
            OutData.Add(Iter->Value);
        }
    }

    virtual bool EditorSave() override
    {
        bool bRet = true;
        for (auto Iter = TabFiles.CreateIterator(); Iter; ++Iter)
        {
            CurrentEditorPath = Iter->Key;
            TSaverType Saver;
            bRet = EditorSaveData(&Saver, *CurrentEditorPath.ToString(), GetParamInfoKey()) >= 0;
            if (!bRet)
            {
                break;
            }
        }
        EditorOnPostSave();
        return bRet;
    }

    virtual bool EditorAddData(FGameAvatarPartTabFileData* Data) override
    {
        check(false);
        return false;
    }
    virtual void EditorRemoveData(FGameAvatarPartTabFileData* Data) override
    {
        check(false);
    }

    virtual bool EditorAddData(const FName& PathName, FGameAvatarPartTabFileData* Data)
    {
        CurrentEditorPath = PathName;
        bool bRet = AddRawData(Data);
        CurrentEditorPath = FName();
        return bRet;
    }
    virtual void EditorRemoveData(const FName& PathName, FGameAvatarPartTabFileData* Data, bool bDelete=true)
    {
        CurrentEditorPath = PathName;
        RemoveRawData(Data);
        CurrentEditorPath = FName();

        if (bDelete)
        {
            delete Data;
        }
    }

    virtual bool AddRawData(FTabFileDataBase* Data) override
    {
        if (CurrentEditorPath.IsValid())
        {
            if (!AddDataToTabFileMap(CurrentEditorPath, static_cast<FGameAvatarPartTabFileData*>(Data)))
            {
                return false;
            }
        }
        return TBasedTemplateTabFileClass::AddRawData(Data);
    }
    virtual void RemoveRawData(FTabFileDataBase* Data) override
    {
        TBasedTemplateTabFileClass::RemoveRawData(Data);

        if (CurrentEditorPath.IsValid())
        {
            RemoveDataFreomTabFileMap(CurrentEditorPath, static_cast<FGameAvatarPartTabFileData*>(Data));
        }
    }

    const TTabFileAllDataMap* GetTabFileAllData(const FName& PathName)
    {
        return TabFiles.Find(PathName);
    }

private:
    bool AddDataToTabFileMap(const FName& PathName, FGameAvatarPartTabFileData* Data)
    {
        TTabFileAllDataMap* Map = TabFiles.Find(PathName);
        check(Map);
        if (Map->Find(Data->GetID()))
        {
            return false;
        }
        Map->Add(Data->GetID(), Data);
        return true;
    }
    void RemoveDataFreomTabFileMap(const FName& PathName, FGameAvatarPartTabFileData* Data)
    {
        TTabFileAllDataMap* Map = TabFiles.Find(PathName);
        if (Map)
        {
            Map->Remove(Data->GetID());
        }
    }

private:
    TMap<FName, TTabFileAllDataMap> TabFiles;
    FName CurrentEditorPath;
#endif
};