# --- Certificate bypass (if downloading JARs via script) ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls;
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};

# --- Configuration Persistence ---
# This script will save your Java and base directory paths so you only have to enter them once.
# It also tracks whether the manual security step has been completed.
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "iDRAC_config.json"

if (Test-Path $configFilePath) {
    Write-Host "Loading configuration from $configFilePath..."
    $config = Get-Content $configFilePath | ConvertFrom-Json

    # --- FIX: Check if the property exists before trying to use it ---
    if ($null -eq $config.securityFileModified) {
        $config | Add-Member -MemberType NoteProperty -Name "securityFileModified" -Value $false
    }
} else {
    Write-Host "Initial setup: Please enter your configuration paths."
    $baseDir = Read-Host -Prompt "Enter the base directory for files (e.g., C:\iDRAC_Launcher)"
    $jreFolder = Read-Host -Prompt "Enter the full path to your JRE 7 folder (e.g., C:\Program Files\Java\jre7)"

    # Save the configuration for future runs, including a flag for the manual security step
    $config = [PSCustomObject]@{
        baseDir = $baseDir
        jreFolder = $jreFolder
        securityFileModified = $false
    }
    $config | ConvertTo-Json | Out-File $configFilePath
    Write-Host "Configuration saved. You will not be asked for these paths again."
}

# --- Runtime Prompts ---
$iDRAC_IP = Read-Host -Prompt "Enter the iDRAC IP address"
$iDRAC_User = Read-Host -Prompt "Enter your iDRAC username"
$iDRAC_Pass = Read-Host -Prompt "Enter your iDRAC password"

# --- Script Paths (derived from your input) ---
$JavaPath = "$jreFolder\bin\java.exe"
$KVMJar = "$baseDir\avctKVM.jar"
$NativeLibPath = "$baseDir\lib"
$kvmIoJarTemp = "$NativeLibPath\avctKVMIOWin32.jar"
$vmJarTemp = "$NativeLibPath\avctVMWin32.jar"

# --- Automated Setup Section ---
Write-Host "--- Automated Setup Started ---"
if (-not (Test-Path $jreFolder)) {
    Write-Error "Java JRE 7 not found at '$jreFolder'. Please ensure it is installed."
    Exit
}

# --- Instructions for manual modification (only shown on the first run) ---
if (-not $config.securityFileModified) {
    Write-Host "--- ATTENTION: MANUAL STEP REQUIRED ---"
    Write-Host "The KVM viewer requires a change to your Java security policy."
    Write-Host "Proceed with caution and at your own risk."
    Write-Host "1. Navigate to the following file location:"
    Write-Host "   $jreFolder\lib\security\java.security"
    Write-Host ""
    Write-Host "2. Open the 'java.security' file in a text editor with administrator privileges."
    Write-Host "3. Find the line that starts with 'jdk.tls.disabledAlgorithms'."
    Write-Host "   It likely looks like this: 'jdk.tls.disabledAlgorithms=SSLv3'"
    Write-Host ""
    Write-Host "4. Comment out this line by adding a '#' to the beginning:"
    Write-Host "   '#jdk.tls.disabledAlgorithms=SSLv3'"
    Write-Host ""
    Write-Host "5. Save the file and close the editor."
    Write-Host "---"

    # Pause and confirm completion
    Read-Host "Press Enter after you have completed the manual step to continue..."

    # Update the config file so this message won't be shown again
    $config.securityFileModified = $true
    $config | ConvertTo-Json | Out-File $configFilePath
}

# --- Download JARs and extract DLLs ---
if (-not (Test-Path $KVMJar)) {
    Write-Host "Downloading avctKVM.jar..."
    Invoke-WebRequest -Uri ("https://" + $iDRAC_IP + ":443/software/avctKVM.jar") -OutFile $KVMJar -ErrorAction Stop -SkipCertificateCheck

    # Create the 'lib' folder first
    New-Item -ItemType Directory -Path $NativeLibPath -Force

    # Download and extract the native library JARs
    Write-Host "Downloading and extracting native libraries..."
    Invoke-WebRequest -Uri ("https://" + $iDRAC_IP + ":443/software/avctKVMIOWin32.jar") -OutFile $kvmIoJarTemp -ErrorAction Stop -SkipCertificateCheck
    Invoke-WebRequest -Uri ("https://" + $iDRAC_IP + ":443/software/avctVMWin32.jar") -OutFile $vmJarTemp -ErrorAction Stop -SkipCertificateCheck

    # Extract DLLs from the downloaded JARs
    Expand-Archive -Path $kvmIoJarTemp -DestinationPath $NativeLibPath -Force
    Expand-Archive -Path $vmJarTemp -DestinationPath $NativeLibPath -Force

    # Remove the temporary JAR files
    Remove-Item $kvmIoJarTemp
    Remove-Item $vmJarTemp

    Write-Host "All files prepared."
}
Write-Host "--- Automated Setup Complete ---"

# --- Launch the Console ---
Write-Host "Launching iDRAC Virtual Console for $iDRAC_IP..."

try {
    $javaArgs = @(
        "-cp", "$KVMJar",
        "-Djava.library.path=$NativeLibPath",
        "com.avocent.idrac.kvm.Main",
        "ip=$iDRAC_IP",
        "kmport=5900",
        "vport=5900",
        "apcp=1",
        "version=2",
        "vmprivilege=true",
        "user=$iDRAC_User",
        "passwd=$iDRAC_Pass",
        "helpurl=https://$iDRAC_IP:443/help/contents.html",
        "title=iDRAC-Console-for-$iDRAC_IP"
    )

    Write-Host "DEBUG: Java Command String: '$JavaPath $javaArgs'"

    # Execute the command
    Start-Process -FilePath $JavaPath -ArgumentList $javaArgs -NoNewWindow
}
catch {
    Write-Error "Failed to launch iDRAC Virtual Console: $($_.Exception.Message)"
    Write-Error "Ensure Java is correctly configured (especially TLS settings and site exceptions)."
}
