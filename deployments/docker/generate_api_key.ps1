Write-Host "Generating API key..."

# Define character ranges for alphanumeric characters
$chars = @()
$chars += 48..57   # 0-9
$chars += 65..90   # A-Z
$chars += 97..122  # a-z

# Generate API key
$API_KEY = -join ($chars | Get-Random -Count 64 | ForEach-Object { [char]$_ })
$env:AI_UNLIMITED_INIT_API_KEY = $API_KEY

Write-Host "API Key is generated, please export it by running the following command: `n"
Write-Host '$env:AI_UNLIMITED_INIT_API_KEY = $API_KEY'
