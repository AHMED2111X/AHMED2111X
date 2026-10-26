# ==============================================================================
# FALCON INTEGRITY FIX - سكربت البناء (PowerShell)
# يبني حزمة ZIP مع قائمة بصمات SHA-256 (payload.sha256) تلقائياً.
#
#   .\build_zip.ps1                 # يبني FALCONINTEGITY_FIX_V<VER>.zip
#   .\build_zip.ps1 -SkipVerify     # يتخطى فحص sh -n (غير مستحسن)
#
# ملاحظة مهمة: أسماء الملفات داخل ZIP تُكتب دائماً بـ "/" (شرط أندرويد).
# ==============================================================================
param(
    [string]$Version = "",
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ROOT = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Select-String -Path (Join-Path $ROOT 'module.prop') -Pattern '^version=(.+)$').Matches[0].Groups[1].Value
}
$VER_NUM = ($Version -replace '^v','')

# --- 1) قائمة الملفات الجذرية المرسلة في الحزمة ---
$rootFiles = @(
    'action.sh','apply_pif.sh','banner.png','busybox','classes.dex','clean_install.sh','common_func.sh',
    'common_setup.sh','custom.pif.json','custom.pif.prop','customize.sh','example.app_replace.list',
    'falcon_kbcheck.sh','falcon_keybox.sh','falcon_rom_compat.sh','falcon_sdcard_cleanup.sh','falcon_stealth.sh','falcon_update_pif.sh',
    'icon.png','icondump.dex','icons.sh','kb_sync.sh','keybox.xml','killpi.sh','migrate.sh','module.prop',
    'post-fs-data.sh','rkp_fix.sh','rom_spoof_block.sh','security_patch.txt','sepolicy.rule','service.sh',
    'soter_fix.sh','sources.conf','target.txt','uninstall.sh','update.json'
)
$subDirs = @('falcon_tricky','tricky','zygisk','META-INF')

$stage = Join-Path $env:TEMP "falcon_build_$VER_NUM"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null
# ⛔ مهم: $env:TEMP قد يكون مساراً قصيراً (8.3 مثل ADMINI~1) بينما Get-ChildItem
#    يُرجع المسار الكامل ⇒ أي Substring على المسار القصير يُفسد المسارات النسبية.
$stage = (Get-Item -LiteralPath $stage).FullName

Write-Host "[1/5] تجميع الملفات..." -ForegroundColor Cyan
foreach ($f in $rootFiles) {
    $src = Join-Path $ROOT $f
    if (-not (Test-Path -LiteralPath $src)) { throw "ملف مفقود: $f" }
    Copy-Item -LiteralPath $src -Destination (Join-Path $stage $f) -Force
}
foreach ($d in $subDirs) {
    $src = Join-Path $ROOT $d
    if (-not (Test-Path -LiteralPath $src)) { throw "مجلد مفقود: $d" }
    Copy-Item -LiteralPath $src -Destination (Join-Path $stage $d) -Recurse -Force
}

# ⛔ توحيد نهايات الأسطر على LF لكل الملفات النصية — إلزامي لأندرويد:
#    سكربت shell بسطر CRLF يفشل بصمت (المُفسِّر يقرأ \r كجزء من الأمر).
#    git مع autocrlf=true يُخرج الملفات على Windows بنهايات CRLF، فالتطبيع
#    هنا يضمن أن الحزمة المُنتَجة سليمة مهما كان مصدر البناء.
$textExt = @('.sh', '.prop', '.txt', '.rule', '.list', '.conf', '.json', '.ps1')
$normalized = 0
Get-ChildItem $stage -Recurse -File | ForEach-Object {
    $ext = $_.Extension.ToLower()
    if ($textExt -notcontains $ext -and $_.Name -ne 'updater-script') { return }
    $raw = [System.IO.File]::ReadAllBytes($_.FullName)
    if ($raw.Length -eq 0) { return }
    $hasCR = $false
    for ($i = 0; $i -lt $raw.Length; $i++) { if ($raw[$i] -eq 13) { $hasCR = $true; break } }
    if (-not $hasCR) { return }
    $txt = [System.Text.Encoding]::UTF8.GetString($raw)
    $txt = $txt -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($_.FullName, $txt, (New-Object System.Text.UTF8Encoding($false)))
    $script:normalized++
}
if ($normalized -gt 0) { Write-Host "      تم توحيد $normalized ملفاً على نهايات LF" -ForegroundColor DarkGray }

Write-Host "[2/5] توليد payload.sha256 ..." -ForegroundColor Cyan
$lines = New-Object System.Collections.Generic.List[string]
Get-ChildItem $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($stage.Length + 1) -replace '\\','/'
    if ($rel -like 'META-INF/*') { return }   # مديرو الروت لا يستخرجون META-INF
    if ($rel -eq 'payload.sha256') { return }
    $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()
    $lines.Add("$h  $rel")
}
[System.IO.File]::WriteAllText((Join-Path $stage 'payload.sha256'), (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "      $($lines.Count) ملفاً في قائمة البصمات" -ForegroundColor DarkGray

Write-Host "[3/5] إنشاء ملف ZIP ..." -ForegroundColor Cyan
$out = Join-Path $ROOT "FALCONINTEGITY_FIX_$($Version.ToUpper()).zip"
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
$fs = [System.IO.File]::Open($out, [System.IO.FileMode]::CreateNew)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    Get-ChildItem $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
        $rel = $_.FullName.Substring($stage.Length + 1) -replace '\\','/'
        $entry = $zip.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = $_.LastWriteTime
        $es = $entry.Open()
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $es.Write($bytes, 0, $bytes.Length)
        $es.Dispose()
    }
} finally {
    $zip.Dispose()
    $fs.Dispose()
}
Write-Host "      $out  ($((Get-Item -LiteralPath $out).Length) بايت)" -ForegroundColor DarkGray

Write-Host "[4/5] التحقق من بنية الحزمة ..." -ForegroundColor Cyan
$zv = [System.IO.Compression.ZipFile]::OpenRead($out)
$bad = @($zv.Entries | Where-Object { $_.FullName -like '*\*' })
$cnt = $zv.Entries.Count
$zv.Dispose()
if ($bad.Count -gt 0) { throw "خطأ: أسماء ملفات بمسار مائل خلفي داخل الحزمة ($($bad.Count))" }
# ⛔ فحص إضافي: كل مدخل يجب أن يكون مساراً نسبياً (بدون مجلد جذر)
$zv = [System.IO.Compression.ZipFile]::OpenRead($out)
$abs = @($zv.Entries | Where-Object { $_.FullName -match '^/|^[A-Za-z]:|^[^/]+/[^/]+/' -and $_.FullName -notlike 'falcon_tricky/*' -and $_.FullName -notlike 'tricky/*' -and $_.FullName -notlike 'zygisk/*' -and $_.FullName -notlike 'META-INF/*' })
$zv.Dispose()
if ($abs.Count -gt 0) { throw "خطأ: مسارات غير نسبية داخل الحزمة: $($abs[0].FullName)" }
Write-Host "      $cnt مدخلاً · لا توجد مسارات خاطئة" -ForegroundColor DarkGray

if (-not $SkipVerify) {
    Write-Host "[5/5] فحص السكربتات والتحقق من البصمات ..." -ForegroundColor Cyan
    $bb = Join-Path $env:TEMP 'opencode\busybox.exe'
    $vdir = Join-Path $env:TEMP "falcon_verify_$VER_NUM"
    if (Test-Path $vdir) { Remove-Item $vdir -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($out, $vdir)
    Push-Location $vdir
    try {
        if (Test-Path $bb) {
            & $bb sha256sum -c payload.sha256 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "فشل التحقق من بصمات SHA-256" }
            $fails = 0
            Get-ChildItem $vdir -Recurse -File -Filter '*.sh' | ForEach-Object {
                & $bb sh -n $_.FullName 2>$null
                if ($LASTEXITCODE -ne 0) { $fails++; Write-Host "      خطأ صياغة: $($_.Name)" -ForegroundColor Red }
            }
            if ($fails -gt 0) { throw "$fails سكربت فشل في فحص الصياغة" }
            Write-Host "      كل البصمات صحيحة · كل السكربتات سليمة الصياغة" -ForegroundColor Green
        } else {
            Write-Host "      (BusyBox غير متاح — تم تخطي الفحص)" -ForegroundColor Yellow
        }
    } finally { Pop-Location }
} else {
    Write-Host "[5/5] تم تخطي الفحص" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "تم بناء الحزمة: $out" -ForegroundColor Green
