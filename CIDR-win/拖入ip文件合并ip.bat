@echo off
chcp 65001 > nul

if "%~1"=="" (
    echo 请将IP文件拖拽到此批处理文件上
    pause
    exit /b
)

set "input_file=%~1"
set "output_file=%~dp1%~n1_new%~x1"

"%~dp0cidr-merger.exe" --merge -o "%output_file%" "%input_file%"

echo 处理完成，结果保存在 %output_file% 中

pause
