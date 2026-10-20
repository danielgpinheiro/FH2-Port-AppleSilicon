/* Loads d3d12.dll from the current directory (run with the native override
 * d3d12=n) and runs the layer's D3DMetal probes; results go to data\logs\fh2port.log */
#include <windows.h>
#include <stdio.h>

int main(void)
{
    HMODULE m = LoadLibraryA("d3d12.dll");
    void (WINAPI *run)(void) = m ? (void (WINAPI *)(void))GetProcAddress(m, "fh2_run_tests") : NULL;
    if (!run) { printf("d3d12.dll is not the fh2port layer (fh2_run_tests missing)\n"); return 1; }
    run();
    printf("done, see data\\logs\\fh2port.log\n");
    return 0;
}
