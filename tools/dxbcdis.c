/* dxbcdis: disassemble DXBC files with the native d3dcompiler_47 (D3DDisassemble). usage: dxbcdis in.dxbc out.txt ... */
#include <windows.h>
#include <d3dcommon.h>
#include <stdio.h>

typedef HRESULT (WINAPI *disasm_fn)(const void *, SIZE_T, UINT, const char *, ID3DBlob **);

int main(int argc, char **argv)
{
    HMODULE m = LoadLibraryA("d3dcompiler_47.dll");
    disasm_fn dis = m ? (disasm_fn)GetProcAddress(m, "D3DDisassemble") : NULL;
    if (!dis) { printf("no D3DDisassemble\n"); return 1; }
    for (int i = 1; i + 1 < argc; i += 2) {
        FILE *f = fopen(argv[i], "rb");
        long n;
        char *buf;
        ID3DBlob *text = NULL;
        if (!f) continue;
        fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
        buf = malloc(n); fread(buf, 1, n, f); fclose(f);
        if (SUCCEEDED(dis(buf, n, 0, NULL, &text))) {
            FILE *o = fopen(argv[i + 1], "wb");
            fwrite(text->lpVtbl->GetBufferPointer(text), 1, text->lpVtbl->GetBufferSize(text) - 1, o);
            fclose(o);
        } else printf("%s: disassembly failed\n", argv[i]);
        free(buf);
    }
    return 0;
}
