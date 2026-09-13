@echo off
REM ============================================================
REM ExtraBite Development Runner (Optional Helper)
REM ============================================================
REM NOTE: The application and release APK do NOT depend on this script.
REM Default production credentials are built into AppConfig and can
REM also be supplied via standard Flutter arguments:
REM   flutter run
REM   flutter build apk --release
REM   flutter build appbundle --release
REM ============================================================

set SUPABASE_URL=https://epcurxrrnbqqwifrcrjz.supabase.co
set SUPABASE_ANON_KEY=sb_publishable_WA8fwLpcrfoNIYjvqzVuzw_NgozUw61

if exist ".env.local" (
    for /f "usebackq tokens=1,* delims==" %%A in (".env.local") do (
        if "%%A"=="SUPABASE_URL" set SUPABASE_URL=%%B
        if "%%A"=="SUPABASE_ANON_KEY" set SUPABASE_ANON_KEY=%%B
    )
)

echo Starting ExtraBite Mobile...
echo Supabase URL: %SUPABASE_URL%

if "%1"=="" (
    flutter run ^
        --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
        --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
) else (
    flutter run -d %1 ^
        --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
        --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
)
