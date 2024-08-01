Write-Host "Generating API key..."

# all characters
$API_KEY=(-join ((33..126) | Get-Random -Count 32 | % {[char]$_}))
$env:AI_UNLIMITED_INIT_API_KEY = $API_KEY

Write-Host "API Key is generated, please export it by running the following command: \n"
Write-Host '$env:AI_UNLIMITED_INIT_API_KEY = $API_KEY'