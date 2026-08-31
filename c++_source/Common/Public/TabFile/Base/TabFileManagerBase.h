#pragma once

#include <type_traits>

class FTabFileBase;

class COMMON_API FTabFileManagerBase
{
public:
    template<class T>
    void Register()
    {
        static_assert(std::is_base_of<FTabFileBase, T>::value,
            "typename T must derive from FTabFileBase");
        T& TabFile = T::GetSingleton();
        TabFiles.AddUnique(&TabFile);
    }

	virtual ~FTabFileManagerBase() {}
    virtual bool Init();
    virtual void Uninit();
    void UnregisterAll();

protected:
    bool Load();
    void Unload();
    virtual void RegisterFiles() = 0;

protected:
    TArray<FTabFileBase*> TabFiles;

#ifdef ENABLE_TAB_FILE_EDITOR
public:
    static bool EditorLoadSingleTabFile(FTabFileBase* TabFile);
    static void EditorUnloadSingleTabFile(FTabFileBase* TabFile);
protected:
    static TMap<FTabFileBase*, bool> EditorTabFilesHolder;
#endif
};
