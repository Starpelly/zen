# run this script with a "dot source" like this:
# . .\ps-setup.ps1
# this allows you to easily run the debug build of the compiler like this:
# zen test/main.zen

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$zenPath = Join-Path $scriptDir "build\Debug_Win64\zen\zen.exe"

Set-Alias zen $zenPath