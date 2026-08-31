#pragma once

#include "TabFile/Base/TabFile.h"
#define EXPORT_API

TAB_FILE_DATA(EXPORT_API, FLandIDNameTabData)
{
	int32 LandID;
	FString LandName;

	FLandIDNameTabData()
		: LandID(0)
		, LandName("")
	{}

	TAB_FILE_DATA_SINGLE_KEY(int, LandID);

	virtual void RegisterParams() override
	{
		TAB_FILE_DATA_REGISTER(LandID, "land_id");
		TAB_FILE_DATA_REGISTER(LandName, "land_name");
	}
};

TAB_FILE(EXPORT_API, FLandIDNameTabFile, FLandIDNameTabData)
{
public:
	void SetPath(const FString& InPath)
	{
		Path = InPath;
	}

	virtual const TCHAR* GetPath() const override
	{
		return *Path;
	}

	virtual bool Load() override
	{
		if (Path.Len() == 0)
		{
			return true;
		}

		return TBasedTemplateTabFileClass::Load();
	}

private:
	FString Path;
};