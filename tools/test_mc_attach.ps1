# Test sqlite3mc.dll approaches for creating encrypted databases
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class Sqmc {
    const string Dll = @"C:\Users\Sergio\Proyectos\SFinance\my_apps\apps\sfinance\build\windows\x64\runner\Debug\sqlite3mc.dll";
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] public static extern int sqlite3_open_v2(string f, out IntPtr db, int flags, IntPtr vfs);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl, CharSet=CharSet.Ansi)] public static extern int sqlite3_exec(IntPtr db, string sql, IntPtr cb, IntPtr arg, out IntPtr errmsg);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] public static extern int sqlite3_close(IntPtr db);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] public static extern void sqlite3_free(IntPtr p);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl, CharSet=CharSet.Ansi)] public static extern IntPtr sqlite3_errmsg(IntPtr db);
}
'@

$key = "00" * 32  # 32 zero bytes

function TryExec([IntPtr]$db, [string]$sql) {
    $ep = [IntPtr]::Zero
    $r  = [Sqmc]::sqlite3_exec($db, $sql, [IntPtr]::Zero, [IntPtr]::Zero, [ref]$ep)
    $msg = if ($ep -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ep) } else { "" }
    [Sqmc]::sqlite3_free($ep)
    Write-Host "  exec rc=$r msg=$msg | sql: $($sql.Substring(0, [Math]::Min(60, $sql.Length)))"
    return $r
}

# ── Test A: ATTACH to create new encrypted file (READWRITE|CREATE = 6) ───────
Write-Host "=== Test A: sqlite3mc.dll ATTACH encrypted (flags=6) ==="
$src = [IntPtr]::Zero
$r = [Sqmc]::sqlite3_open_v2('C:\Users\Sergio\Proyectos\SFinance\sfinance.sqlite', [ref]$src, 6, [IntPtr]::Zero)
Write-Host "open src: $r"
Remove-Item 'C:\Users\Sergio\AppData\Local\Temp\test_mc_a.sqlite' -ErrorAction SilentlyContinue
TryExec $src "ATTACH DATABASE 'C:/Users/Sergio/AppData/Local/Temp/test_mc_a.sqlite' AS enc KEY `"x'$key'`";"
[Sqmc]::sqlite3_close($src) | Out-Null

# ── Test B: Open dest with key, ATTACH plain source ───────────────────────────
Write-Host "`n=== Test B: Open encrypted dest, ATTACH plain source ==="
$dest = [IntPtr]::Zero
Remove-Item 'C:\Users\Sergio\AppData\Local\Temp\test_mc_b.sqlite' -ErrorAction SilentlyContinue
$r = [Sqmc]::sqlite3_open_v2('C:\Users\Sergio\AppData\Local\Temp\test_mc_b.sqlite', [ref]$dest, 6, [IntPtr]::Zero)
Write-Host "open dest: $r"
TryExec $dest "PRAGMA key = `"x'$key'`";"
TryExec $dest "CREATE TABLE test (id INTEGER PRIMARY KEY, val TEXT);"
TryExec $dest "ATTACH DATABASE 'C:/Users/Sergio/Proyectos/SFinance/sfinance.sqlite' AS src;"
TryExec $dest "INSERT INTO test SELECT id, name FROM src.transactions LIMIT 3;"
TryExec $dest "DETACH DATABASE src;"
[Sqmc]::sqlite3_close($dest) | Out-Null

# Check if test_mc_b is encrypted
$bytes = [System.IO.File]::ReadAllBytes('C:\Users\Sergio\AppData\Local\Temp\test_mc_b.sqlite')
$hdr = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 16)
Write-Host "test_mc_b header: '$hdr'"
if ($hdr -eq "SQLite format 3`0") { Write-Host "NOT encrypted" } else { Write-Host "ENCRYPTED (good)" }

Remove-Item 'C:\Users\Sergio\AppData\Local\Temp\test_mc_a.sqlite' -ErrorAction SilentlyContinue
Remove-Item 'C:\Users\Sergio\AppData\Local\Temp\test_mc_b.sqlite' -ErrorAction SilentlyContinue
