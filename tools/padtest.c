/* Checks the fh2pad gamepad provider outside the game: activates
 * Windows.Gaming.Input.Gamepad through RoGetActivationFactory, which finds fh2pad.dll
 * through the class registration, then prints the virtual pad's readings.
 * Keys only count while the game window is focused, so from a console this
 * shows the merged real pads only. */
#include <windows.h>
#include <roapi.h>
#include <winstring.h>
#include <stdio.h>

typedef struct { UINT64 timestamp; UINT32 buttons; double lt, rt, lx, ly, rx, ry; } pad_reading;
typedef struct { void **vt; } obj;
#define CALL(o, slot, type, ...) ((type)((o)->vt[slot]))(o, ##__VA_ARGS__)

static const GUID IID_pad_statics = {0x8bbce529, 0xd49c, 0x39e9, {0x95,0x60,0xe4,0x7d,0xde,0x96,0xb7,0xc8}};

int main(void)
{
    const WCHAR name[] = L"Windows.Gaming.Input.Gamepad";
    HSTRING cls;
    obj *statics = NULL, *list = NULL, *pad = NULL;
    UINT32 n = 0;
    pad_reading r;
    HRESULT hr;
    RoInitialize(RO_INIT_MULTITHREADED);
    WindowsCreateString(name, (UINT32)wcslen(name), &cls);
    hr = RoGetActivationFactory(cls, &IID_pad_statics, (void **)&statics);
    printf("factory hr %#lx statics %p\n", hr, (void *)statics);
    if (FAILED(hr)) return 1;
    hr = CALL(statics, 10, HRESULT (STDMETHODCALLTYPE *)(obj *, obj **), &list);
    CALL(list, 7, HRESULT (STDMETHODCALLTYPE *)(obj *, UINT32 *), &n);
    printf("get_Gamepads hr %#lx size %u\n", hr, n);
    if (!n) return 1;
    CALL(list, 6, HRESULT (STDMETHODCALLTYPE *)(obj *, UINT32, obj **), 0, &pad);
    for (int i = 0; i < 12; i++) {
        hr = CALL(pad, 8, HRESULT (STDMETHODCALLTYPE *)(obj *, pad_reading *), &r);
        printf("hr %#lx ts %llu buttons %#x lt %.2f rt %.2f lx %.2f ly %.2f rx %.2f ry %.2f\n", hr,
               (unsigned long long)r.timestamp, r.buttons, r.lt, r.rt, r.lx, r.ly, r.rx, r.ry);
        Sleep(500);
    }
    return 0;
}
