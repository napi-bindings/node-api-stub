/*
 * Delay-load hook for Node-API addons on Windows (MSVC / clang-cl).
 *
 * The import library declares the Node-API symbols as imported from "node.exe".
 * When the host process has a different name (electron.exe, a renamed node,
 * ...) normal loading would fail: with /DELAYLOAD:node.exe this hook returns
 * the module of the current executable (or libnode.dll when present), and the
 * loader resolves the symbols from it with GetProcAddress.
 * C equivalent of node-gyp's win_delay_load_hook.cc.
 */
#if defined(_MSC_VER)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <delayimp.h>
#include <string.h>

static FARPROC WINAPI node_api_delay_load_hook(unsigned int event, PDelayLoadInfo info) {
  HMODULE m;
  if (event != dliNotePreLoadLibrary) return NULL;
  if (_stricmp(info->szDll, "node.exe") != 0) return NULL;
  m = GetModuleHandleA("libnode.dll");       /* Node built as a shared library */
  if (m == NULL) m = GetModuleHandleA(NULL); /* the host executable */
  return (FARPROC)m;
}

const PfnDliHook __pfnDliNotifyHook2 = node_api_delay_load_hook;

#endif /* _MSC_VER */
