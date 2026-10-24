#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
static HMODULE ownModule;
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID) {
 if(reason==DLL_PROCESS_ATTACH){ownModule=instance;DisableThreadLibraryCalls(instance);}return TRUE;
}
// No Lua arguments/results, no dependency on Lua ABI exports.
extern "C" __declspec(dllexport) int m4music_start(void*) {
 wchar_t buffer[32768];DWORD n=GetModuleFileNameW(ownModule,buffer,32768);if(!n||n>=32768)return 0;
 std::wstring folder(buffer,n);folder.resize(folder.find_last_of(L"\\/"));folder.resize(folder.find_last_of(L"\\/"));
 std::wstring exe=folder+L"\\M4MusicHost.exe",command=L"\""+exe+L"\"";
 STARTUPINFOW start={};start.cb=sizeof(start);start.dwFlags=STARTF_USESHOWWINDOW;start.wShowWindow=SW_HIDE;
 PROCESS_INFORMATION process={};
 if(CreateProcessW(exe.c_str(),&command[0],nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,folder.c_str(),&start,&process)) {
  CloseHandle(process.hThread);CloseHandle(process.hProcess);
 } else {
  DWORD error=GetLastError();std::wstring log=folder+L"\\launcher-error.txt";
  HANDLE f=CreateFileW(log.c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);
  if(f!=INVALID_HANDLE_VALUE){char s[80];int length=wsprintfA(s,"CreateProcess error: %lu\r\n",error);DWORD written;WriteFile(f,s,length,&written,nullptr);CloseHandle(f);}
 }
 return 0;
}
