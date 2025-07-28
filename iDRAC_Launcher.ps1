<#
.SYNOPSIS
    Launches the Dell iDRAC 6 Virtual Console (KVM) by directly invoking the Java application,
    bypassing Java Web Start (.jnlp) and handling self-signed certificate issues.

.DESCRIPTION
    This script automates the process of connecting to a Dell iDRAC 6 Virtual Console (KVM).
    It addresses common issues with iDRAC 6 on modern systems, such as Java Web Start
    (.jnlp) deprecation and self-signed SSL certificate errors.

    The script performs the following steps:
    1. Prompts the user for the iDRAC IP address, username, and password.
    2. Configures PowerShell to bypass SSL certificate validation for Invoke-WebRequest.
    3. Downloads the necessary iDRAC KVM JAR files (avctKVM.jar, avctKVMIOWin64.jar, avctVMWin64.jar)
       from the iDRAC if they are not already present locally.
    4. Launches the Java Virtual Machine (java.exe) directly with the downloaded JARs
       and the required arguments to establish the KVM session.

.NOTES
    Author: ChatGPT (Modified by User)
    Version: 1.0
    Date: July 27, 2025
    GitHub: [Link to your GitHub Gist/Repo where you will post this]

    Requirements:
    - PowerShell 7 (or later) is highly recommended for '-SkipCertificateCheck' on Invoke-WebRequest.
      (PowerShell 5.1 might work but requires additional certificate bypass setup if '-SkipCertificateCheck' is not available).
    - An installed Java Runtime Environment (JRE) version 7 (JRE 1.7.0_XX). Older iDRACs are
      not compatible with newer Java versions due to deprecated security protocols.
      Ensure 'java.exe' from JRE 7 is accessible at the specified '$JavaPath'.

    Known Issues/Considerations:
    - "KVM Native Library" Warning: You might see a warning about native libraries failing to load
      for keyboard/mouse support. This typically means "Pass All Keystrokes to Server" and
      "Single Cursor support" won't work, but basic keyboard and mouse input should still
      function (often requiring clicking to capture/release mouse). This is common with
      older iDRACs and modern OS/Java.
    - Password Security: The script prompts for a secure password, but it must be converted
      to plain text temporarily to be passed as an argument to the Java application.
      Be mindful of this if you are running in highly sensitive environments.
#>

# --- Certificate bypass for Invoke-WebRequest (for downloading JARs) ---
# These lines help bypass SSL certificate validation for the web requests.
# In PowerShell 7, -SkipCertificateCheck on Invoke-WebRequest is generally preferred
# for explicitly ignoring certificate issues, but these provide additional compatibility.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls;
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};

# --- Configuration Variables (User Input) ---

# Prompt for iDRAC IP Address
$iDRAC_IP = Read-Host -Prompt "Enter iDRAC IP Address (e.g., 10.0.1.40)"
# Basic validation: check if it's not empty. More robust validation could be added.
if (-not $iDRAC_IP) {
    Write-Error "iDRAC IP address cannot be empty. Exiting."
    exit 1
}

# Prompt for iDRAC Username
$iDRAC_User = Read-Host -Prompt "Enter iDRAC Username (e.g., root)"
if (-not $iDRAC_User) {
    Write-Error "iDRAC username cannot be empty. Exiting."
    exit 1
}

# Prompt for iDRAC Password (securely)
$SecurePassword = Read-Host -Prompt "Enter iDRAC Password" -AsSecureString
# Convert SecureString to plain text string for Java arguments (necessary for the Java applet)
$iDRAC_Pass_PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))


# Path to your Java installation (JRE 7 is crucial for iDRAC 6 compatibility)
# IMPORTANT: Verify this path matches your JRE 7 installation.
# This should point to java.exe, NOT javaws.exe
$JavaPath = "C:\Program Files\Java\jre7\bin\java.exe"

# --- Local Paths for JAR Files ---
# These paths specify where the iDRAC KVM JARs will be stored on your local machine.
# Create a dedicated folder for these files.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$KVMJar = Join-Path -Path $ScriptDir -ChildPath "avctKVM.jar"
$NativeLibPath = Join-Path -Path $ScriptDir -ChildPath "lib" # Folder for native libraries

# --- (Optional) Download JARs if they don't exist yet ---
# This block checks if the necessary JAR files are present locally.
# If not, it attempts to download them from the iDRAC.
if (-not (Test-Path $KVMJar)) {
    Write-Host "Downloading avctKVM.jar..."
    try {
        # Using explicit string concatenation for the URI to prevent potential variable interpolation issues
        # -SkipCertificateCheck is used for PowerShell 7 to ignore self-signed certificates.
        Invoke-WebRequest -Uri ("https://" + $iDRAC_IP + ":443/software/avctKVM.jar") -OutFile $KVMJar -ErrorAction Stop -SkipCertificateCheck
    }
    catch {
        Write-Error "Failed to download avctKVM.jar: $($_.Exception.Message)"
        Write-Error "Please ensure the iDRAC IP is correct and accessible, and Java JRE 7 is installed."
        exit 1
    }

    # Create the 'lib' folder if it doesn't exist
    New-Item -ItemType Directory -Path $NativeLibPath -Force | Out-Null # Use Out-Null to suppress output

    Write-Host "Downloading avctKVMIOWin64.jar..."
    try {
        Invoke-WebRequest -Uri ("https://" + $iDRAC_IP + ":443/software/avctKVMIOWin64.jar") -OutFile "$NativeLibPath\avctKVMIOWin64.jar" -ErrorAction Stop -SkipCertificateCheck
    }
    catch {
        Write-Error "Failed to download avctKVMIOWin64.jar: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "Downloading avctVMWin64.jar..."
    try {
        Invoke-WebRequest -Uri ("https://" + $iDRAC_IP + ":443/software/avctVMWin64.jar") -OutFile "$NativeLibPath\avctVMWin64.jar" -ErrorAction Stop -SkipCertificateCheck
    }
    catch {
        Write-Error "Failed to download avctVMWin64.jar: $($_.Exception.Message)"
        exit 1
    }
    Write-Host "All required JARs downloaded successfully."
}
else {
    Write-Host "JARs already exist. Skipping download."
}

Write-Host "Launching iDRAC Virtual Console for $iDRAC_IP..."

try {
    # Construct the full command string for java.exe
    # This method ensures all arguments are correctly passed as a single string to java.exe
    # Backticks (`) are used for line continuation for readability.
    $javaArgs = `
        "-cp """ + $KVMJar + """ " + `
        "-Djava.library.path=""" + $NativeLibPath + """ " + `
        "com.avocent.idrac.kvm.Main " + `
        "ip=" + $iDRAC_IP + " " + `
        "kmport=5900 " + `
        "vport=5900 " + `
        "apcp=1 " + `
        "version=2 " + `
        "vmprivilege=true " + `
        "user=" + $iDRAC_User + " " + `
        "passwd=" + $iDRAC_Pass_PlainText + " " + ` # Use the plain text password here
        "helpurl=https://" + $iDRAC_IP + ":443/help/contents.html " + `
        "title=iDRAC-Console-for-" + $iDRAC_IP

    Write-Host "DEBUG: Java Command String: '$JavaPath $javaArgs'" # For debugging the final command

    # Execute the command. -NoNewWindow keeps Java's console output suppressed.
    Start-Process -FilePath $JavaPath -ArgumentList $javaArgs -NoNewWindow
}
catch {
    Write-Error "Failed to launch iDRAC Virtual Console: $($_.Exception.Message)"
    Write-Error "Ensure Java is correctly configured (especially TLS settings and site exceptions)."
}

# Clean up the plain text password from memory (best effort)
# This will clear the variable holding the plain text password
Remove-Variable -Name iDRAC_Pass_PlainText -ErrorAction SilentlyContinue
# Explicitly zero out the SecureString object (more complex, often left to garbage collection)
# [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
