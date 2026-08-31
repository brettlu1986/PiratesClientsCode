#pragma once
#include "TabFile/Base/TabFile.h"
#include "GameAvatarPartTabFile.h"

TAB_FILE_DATA(COMMON_API, FGameAvatarPartTypeTabFileData)
{
    int PartType;
    FName PartName;
    FString FilePath;

    int MinPartID;
    int MaxPartID;
    FString Group;
#if WITH_EDITOR
    FString Description;
#endif

    FGameAvatarPartTypeTabFileData()
        : PartType(0)
        , MinPartID(0)
        , MaxPartID(0)
    {}

    TAB_FILE_DATA_SINGLE_KEY(int, PartType);

    virtual void RegisterParams() override
    {
        TAB_FILE_DATA_REGISTER(PartType, "part_type");
        TAB_FILE_DATA_REGISTER(PartName, "part_name");
        TAB_FILE_DATA_REGISTER(FilePath, "file_path");
        TAB_FILE_DATA_REGISTER(MinPartID, "min_part_id");
        TAB_FILE_DATA_REGISTER(MaxPartID, "max_part_id");
        TAB_FILE_DATA_REGISTER(Group, "group");

#if WITH_EDITOR
        TAB_FILE_DATA_REGISTER(Description, "description");
#endif
    }

    virtual void OnPostLoad() override
    {
        FGameAvatarPartTabFile::GetSingleton().AddPath(FilePath);
    }
};

TAB_FILE(COMMON_API, FGameAvatarPartTypeTabFile, FGameAvatarPartTypeTabFileData)
{
public:
    virtual const TCHAR* GetPath() const override 
    {
        return TEXT("common/res/part/part_type.tab");
    }

    const FGameAvatarPartTypeTabFileData* GetDataByPartID(int PartID) const
    {
        int iCount = PartIDRegions.Num() - 1;
        switch (iCount)
        {
        case 0:
        {
            return nullptr;
        }
        case 1:
        {
            auto Data = PartIDRegions[0];
            if (PartID >= Data->MinPartID && PartID <= Data->MaxPartID)
            {
                return Data;
            }
            break;
        }
        case 2:
        {
            auto Data = PartID <= PartIDRegions[0]->MaxPartID ? PartIDRegions[0] : PartIDRegions[1];
            if (PartID >= Data->MinPartID && PartID <= Data->MaxPartID)
            {
                return Data;
            }
            break;
        }
        default:
        {
            // 二分查
            int iStart = 0;
            int iEnd = iCount - 1;
            int iMiddle = iCount;
            const FGameAvatarPartTypeTabFileData* Data = nullptr;
            while (iEnd > iStart + 1)
            {
                iMiddle = (iEnd + iStart) / 2;
                Data = PartIDRegions[iMiddle];
                if (PartID == Data->MaxPartID || PartID == Data->MinPartID)
                {
                    return Data;
                }
                else if (PartID < Data->MinPartID)
                {
                    iEnd = iMiddle;
                }
                else
                {
                    iStart = iMiddle;
                }
            }
            Data = PartID <= PartIDRegions[iStart]->MaxPartID ? PartIDRegions[iStart] : PartIDRegions[iEnd];
            if (PartID >= Data->MinPartID && PartID <= Data->MaxPartID)
            {
                return Data;
            }
            break;
        }
        }
        return nullptr;
    }

#ifdef ENABLE_TAB_FILE_EDITOR
public:
    void GetGroupData(TArray<TSharedPtr<FString>>& GroupData)
    {
        TSet<FString> GroupSet;
        for (int index = 0; index < PartIDRegions.Num(); ++index)
        {
            GroupSet.Add(PartIDRegions[index]->Group);
        }

        GroupData.Reserve(GroupSet.Num());
        for (TSet<FString>::TConstIterator SetIt(GroupSet); SetIt; ++SetIt)
        {
            GroupData.Add(MakeShareable(new FString(*SetIt)));
        }
    }

    void GetTabFileData(const FString& InGroup, TArray<const FGameAvatarPartTypeTabFileData*>& OutData)
    {
       for (int index = 0; index < PartIDRegions.Num(); ++index)
       {
           if (!InGroup.Compare(PartIDRegions[index]->Group, ESearchCase::IgnoreCase))
           {
               OutData.Add(PartIDRegions[index]);
           }
       }
    }

    void GetAllTabFileData(const TArray<const FGameAvatarPartTypeTabFileData*>*& OutData)
    {
         OutData = &PartIDRegions;
    }
#endif

protected:
    virtual bool AddRawData(FTabFileDataBase* Data) override
    {
        if (!TBasedTemplateTabFileClass::AddRawData(Data))
        {
            return false;
        }

        // 排序插入
        const FGameAvatarPartTypeTabFileData* TabData = static_cast<const FGameAvatarPartTypeTabFileData*>(Data);
        int iMax = TabData->MaxPartID;
        int iCount = PartIDRegions.Num();
        bool bInsert = false;
        for (int ii=0; ii<iCount; ii++)
        {
            auto SavedData = PartIDRegions[ii];
            if (iMax < SavedData->MinPartID)
            {
                PartIDRegions.Insert(TabData, ii);
                bInsert = true;
                break;
            }
        }
        if (!bInsert)
        {
            PartIDRegions.Add(TabData);
        }
        return true;
    }

    virtual void RemoveRawData(FTabFileDataBase* Data) override
    {
        TBasedTemplateTabFileClass::AddRawData(Data);
        PartIDRegions.Remove(static_cast<const FGameAvatarPartTypeTabFileData*>(Data));
    }

    virtual void Unload() override
    {
        TBasedTemplateTabFileClass::Unload();
        PartIDRegions.Empty();
    }

private:
    TArray<const FGameAvatarPartTypeTabFileData*> PartIDRegions;
};