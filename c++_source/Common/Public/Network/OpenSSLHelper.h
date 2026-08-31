// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#pragma once

enum EOpenSSLState
{
    NotConnected = 0,
    Connecting,
    ConnectSuccessed,
    ConnectFailed,
};

class FOpenSSLHelper
{
public:
    FOpenSSLHelper();
    ~FOpenSSLHelper() {}

    bool Init();
    void Uninit();
    bool Connect(int fd, const TCHAR* HostName);
    void Close();
    EOpenSSLState VerifyState();
    bool Send(const uint8* Data, int32 BufferSize, int32& BytesSent);
    bool Recv(uint8* Data, int32 BufferSize, int32& BytesRead);

private:
    struct FImplement;
    TSharedPtr<FImplement> Impl;
};
