$ErrorActionPreference = "Stop"
& ruby (Join-Path $PSScriptRoot "nomotect-init.rb") @args
exit $LASTEXITCODE
