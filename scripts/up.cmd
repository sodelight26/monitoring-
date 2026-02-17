@echo off
setlocal

set ENV_FILE=%1
if "%ENV_FILE%"=="" set ENV_FILE=env\uat.env

docker compose --env-file %ENV_FILE% up -d
docker compose ps
endlocal
