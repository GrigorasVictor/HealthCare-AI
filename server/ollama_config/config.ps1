$scriptPath = $PSScriptRoot
$configFolder = Join-Path -Path $scriptPath -ChildPath "model_config"

try {
    # Create config folder if it doesn't exist
    if (-not (Test-Path -Path $configFolder)) {
        New-Item -Path $configFolder -ItemType Directory | Out-Null
    }

    # Remove old custom model
    ollama rm qwen3_custom

    # ----------------------------------------------------------
    # Custom Qwen3:8b model named "qwen3_custom"
    # ----------------------------------------------------------
    $modelfileQwen = @"
FROM qwen3:8b
PARAMETER num_gpu 64
PARAMETER num_ctx 10000
"@

    $qwenPath = Join-Path -Path $configFolder -ChildPath "qwen3_custom.modelfile"
    Set-Content -Path $qwenPath -Value $modelfileQwen

    Write-Host "`nCreating model 'qwen3_custom' from: $(Resolve-Path $qwenPath)" -ForegroundColor Cyan
    ollama create qwen3_custom -f $qwenPath

    Write-Host "`n✅ Model created successfully." -ForegroundColor Green
}
catch {
    Write-Host "`n❌ An error occurred: $_" -ForegroundColor Red
}

# Always pause at the end
Write-Host "`nScript complete."
Read-Host -Prompt "Press Enter to exit"