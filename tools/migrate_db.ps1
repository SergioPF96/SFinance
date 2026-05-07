#Requires -Version 7
# One-off tool: encrypt sfinance.sqlite with PIN 7681
# Run: pwsh -File tools\migrate_db.ps1  (from project root)

$ErrorActionPreference = 'Stop'

$SourcePath   = 'C:\Users\Sergio\Proyectos\SFinance\sfinance.sqlite'
$TargetPath   = 'C:\Users\Sergio\Documents\sfinance.sqlite'
$CredPath     = 'C:\Users\Sergio\AppData\Roaming\com.example\sfinance\flutter_secure_storage.dat'
$Sqlite3mcDll = 'C:\Users\Sergio\Proyectos\SFinance\my_apps\apps\sfinance\build\windows\x64\runner\Debug\sqlite3.dll'
$Pin          = '7681'

function ToHex([byte[]] $bytes) {
    [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
}

# ── 1. Random bytes ──────────────────────────────────────────────────────────
$salt      = [byte[]]::new(16)
$masterKey = [byte[]]::new(32)
$nonce     = [byte[]]::new(12)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($salt)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($masterKey)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($nonce)

# ── 2. PBKDF2-SHA256 (500 000 iterations) ───────────────────────────────────
Write-Host 'Deriving wrapping key from PIN (this takes ~30 s)...'
$pbkdf2      = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Pin, $salt, 500000, 'SHA256')
$wrappingKey = $pbkdf2.GetBytes(32)
$pbkdf2.Dispose()

# ── 3. AES-256-GCM: encrypt master key ──────────────────────────────────────
$ciphertext = [byte[]]::new($masterKey.Length)   # 32 bytes
$tag        = [byte[]]::new(16)
$aesgcm     = [System.Security.Cryptography.AesGcm]::new($wrappingKey)
$aesgcm.Encrypt($nonce, $masterKey, $ciphertext, $tag)
$aesgcm.Dispose()

# ── 4. Build auth.envelope JSON (AuthEnvelope format) ───────────────────────
$envelope = [ordered]@{
    salt               = ToHex $salt
    encryptedMasterKey = [Convert]::ToBase64String($ciphertext)
    gcmNonce           = [Convert]::ToBase64String($nonce)
    gcmTag             = [Convert]::ToBase64String($tag)
}
$envelopeJson = $envelope | ConvertTo-Json -Compress
# flutter_secure_storage stores a JSON map of { key -> string_value }
$storageJson  = @{ 'auth.envelope' = $envelopeJson } | ConvertTo-Json -Compress

# ── 5. DPAPI-encrypt and write flutter_secure_storage.dat ───────────────────
Write-Host 'Writing credential file...'
Add-Type -AssemblyName System.Security
$plainBytes   = [System.Text.Encoding]::UTF8.GetBytes($storageJson)
$cryptoBytes  = [System.Security.Cryptography.ProtectedData]::Protect(
    $plainBytes, $null,
    [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($CredPath)) | Out-Null
[System.IO.File]::WriteAllBytes($CredPath, $cryptoBytes)
Write-Host "  → $CredPath"

# ── 6. Create encrypted database (ATTACH + schema copy) ─────────────────────
Write-Host 'Encrypting database...'

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class Sqlite3mc {
    const string Dll = @"$Sqlite3mcDll";
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)]
    public static extern int sqlite3_open_v2(string file, out IntPtr db, int flags, IntPtr vfs);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl, CharSet=CharSet.Ansi)]
    public static extern int sqlite3_exec(IntPtr db, string sql, IntPtr cb, IntPtr arg, out IntPtr errmsg);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)]
    public static extern int sqlite3_close(IntPtr db);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)]
    public static extern void sqlite3_free(IntPtr p);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl, CharSet=CharSet.Ansi)]
    public static extern IntPtr sqlite3_errmsg(IntPtr db);
}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate int ExecCb(IntPtr arg, int argc, IntPtr argv, IntPtr colNames);

public static class SqlCapture {
    public static readonly List<string[]> Rows = new List<string[]>();
    public static int Cb(IntPtr arg, int argc, IntPtr argv, IntPtr colNames) {
        var row = new string[argc];
        for (int i = 0; i < argc; i++) {
            var ptr = Marshal.ReadIntPtr(argv, i * IntPtr.Size);
            row[i] = ptr != IntPtr.Zero ? Marshal.PtrToStringAnsi(ptr) ?? "" : "";
        }
        Rows.Add(row);
        return 0;
    }
}
"@

$SQLITE_OPEN_READWRITE = 0x00000002
$SQLITE_OPEN_CREATE    = 0x00000004
$SQLITE_OK             = 0

function ExecSql([IntPtr]$db, [string]$sql) {
    $ep = [IntPtr]::Zero
    $r  = [Sqlite3mc]::sqlite3_exec($db, $sql, [IntPtr]::Zero, [IntPtr]::Zero, [ref]$ep)
    if ($r -ne $SQLITE_OK) {
        $msg = if ($ep -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ep) } else { "(no msg)" }
        [Sqlite3mc]::sqlite3_free($ep)
        [Sqlite3mc]::sqlite3_close($db) | Out-Null
        throw "sql failed ($r): $msg  SQL: $sql"
    }
}

function RunQuery([IntPtr]$db, [string]$sql) {
    [SqlCapture]::Rows.Clear()
    $cb  = [ExecCb][SqlCapture]::Cb
    $ep  = [IntPtr]::Zero
    $cbPtr = [System.Runtime.InteropServices.Marshal]::GetFunctionPointerForDelegate($cb)
    $r   = [Sqlite3mc]::sqlite3_exec($db, $sql, $cbPtr, [IntPtr]::Zero, [ref]$ep)
    if ($r -ne $SQLITE_OK) {
        $msg = if ($ep -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ep) } else { "(no msg)" }
        [Sqlite3mc]::sqlite3_free($ep)
        throw "query failed ($r): $msg"
    }
}

# Open source (READWRITE|CREATE required for ATTACH to create new files)
$srcDb = [IntPtr]::Zero
$rc = [Sqlite3mc]::sqlite3_open_v2($SourcePath, [ref]$srcDb, ($SQLITE_OPEN_READWRITE -bor $SQLITE_OPEN_CREATE), [IntPtr]::Zero)
if ($rc -ne $SQLITE_OK) { throw "Cannot open source ($rc)" }

if (Test-Path $TargetPath) { Remove-Item $TargetPath -Force }

$masterKeyHex = ToHex $masterKey
$targetPathFwd = $TargetPath.Replace('\', '/')

# ATTACH creates the new encrypted database
ExecSql $srcDb "ATTACH DATABASE '$targetPathFwd' AS enc KEY `"x'$masterKeyHex'`";"

# Copy schema: get DDL for all tables/indices from main, replay in enc
RunQuery $srcDb "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY rootpage;"
foreach ($row in [SqlCapture]::Rows) {
    $type = $row[0]; $name = $row[1]; $ddl = $row[2]
    # Rewrite: CREATE TABLE foo → CREATE TABLE enc.foo  (handles quoted and unquoted names)
    $encDdl = $ddl -replace "(?i)^(CREATE\s+(?:UNIQUE\s+)?(?:TABLE|INDEX)\s+(?:IF\s+NOT\s+EXISTS\s+)?)(""[^""]*""|[^\s(]+)", "`$1enc.`$2"
    Write-Host "  schema: $type $name"
    ExecSql $srcDb $encDdl
}

# Copy data for every table
RunQuery $srcDb "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY rootpage;"
$tableNames = [SqlCapture]::Rows | ForEach-Object { $_[0] }
foreach ($tbl in $tableNames) {
    Write-Host "  data:   $tbl"
    ExecSql $srcDb "INSERT INTO enc.`"$tbl`" SELECT * FROM main.`"$tbl`";"
}

ExecSql $srcDb "DETACH DATABASE enc;"
[Sqlite3mc]::sqlite3_close($srcDb) | Out-Null

Write-Host "  → $TargetPath"
Write-Host ''
Write-Host "Done. Launch the app and unlock with PIN: $Pin"
