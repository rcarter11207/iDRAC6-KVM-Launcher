# Dell iDRAC 6 Virtual Console Launcher

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A PowerShell script to directly launch the Dell iDRAC 6 (and similar older iDRACs) Virtual Console (KVM) without relying on Java Web Start (.jnlp) and handling common SSL certificate and Java compatibility issues.

---

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
  - [PowerShell Version](#powershell-version)
  - [Java Runtime Environment (JRE)](#java-runtime-environment-jre)
- [How to Use](#how-to-use)
- [Script Details & Arguments](#script-details--arguments)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

Dell's older iDRAC versions (like iDRAC 6) often present challenges when trying to access their Virtual Console (KVM) on modern operating systems due to several factors:

1.  **Java Web Start (.jnlp) Deprecation:** Java Web Start, the technology used by these iDRACs to launch the KVM, has been deprecated and removed from modern Java versions.
2.  **SSL Certificate Issues:** Older iDRACs typically use self-signed SSL certificates or certificates with outdated algorithms, leading to browser warnings and connection failures.
3.  **Java Version Compatibility:** The KVM applets were built for specific, older Java Runtime Environment (JRE) versions (e.g., JRE 7) and are incompatible with newer JRE releases due to security changes and API removals.

This PowerShell script directly addresses these problems by:
* Bypassing Java Web Start.
* Ignoring SSL certificate validation during JAR downloads.
* Explicitly launching `java.exe` with the correct arguments and JRE 7.

---

## Features

* **Interactive Prompts:** Guides the user to input the iDRAC IP address, username, and password. The script now saves your Java and base directory paths to a `iDRAC_config.json` file after the first run.
* **Password Handling:** The script uses `Read-Host` for password entry, which is the most reliable way for `Start-Process` to pass the value to the Java application.
* **Automated JAR Download:** Automatically fetches the necessary KVM JAR files from the iDRAC's web interface if they are not already present in the script's designated folder.
* **Native Library Extraction:** It handles the complex process of downloading the native library JARs, extracting the `.dll` files, and placing them in a `lib` sub-directory for the Java application to use.
* **Robust SSL Bypass:** Employs the `-SkipCertificateCheck` parameter (for PowerShell 7+) on `Invoke-WebRequest` to reliably download files from iDRACs with invalid SSL certificates.
* **One-Time Manual Security Step:** To address Java's strict security policies, the script provides clear, step-by-step instructions for a one-time manual change to your `java.security` file. A pause is included to give you time to complete this step. The script remembers that this has been done so you won't be prompted again.

---

## Requirements

### PowerShell Version

* **PowerShell 7 (Recommended):** Highly recommended for its stability and the `Invoke-WebRequest -SkipCertificateCheck` parameter.
    * **Check your version:** Open PowerShell and type `$PSVersionTable.PSVersion`.
    * **Install PowerShell 7:** Download the latest release from [Microsoft's GitHub Releases page](https://github.com/PowerShell/PowerShell/releases).

### Java Runtime Environment (JRE)

* **JRE 7 (JRE 1.7.0_XX) - Absolutely Critical!**
    * **Older iDRACs (like iDRAC 6) are ONLY compatible with JRE 7.** Newer Java versions (JRE 8, 11, 17, etc.) will **NOT** work and will result in errors like "class not found" or security exceptions because they lack the necessary deprecated protocols and APIs.
    * **Obtaining JRE 7:** Oracle no longer provides direct public downloads for JRE 7 without an Oracle account and acceptance of specific license terms. You may need to search for archived JRE 7 installers from a trusted source.
    * **Installation Path:** The script will prompt you for the path to your JRE 7 installation on the first run and save it to the `iDRAC_config.json` file for future use.

---

## How to Use

1.  **Save the Script:**
    * Clone this GitHub repository or simply copy the script content into a new `.ps1` file.
    * Save the file in a dedicated folder on your local machine (e.g., `C:\iDRAC_Launcher\`). This folder will also serve as the storage location for the downloaded iDRAC JAR files.

2.  **Run the Script:**
    * Open a PowerShell console.
    * Navigate to the directory where you saved the script using `cd C:\path\to\your\script`.
    * Execute the script by typing:
      ```powershell
      .\iDrac_KVM_Launcher.ps1
      ```
    * Press `Enter`.

3.  **Follow the Prompts:**
    * **First Run:** The script will first prompt you for the path to your JRE 7 installation and a base directory for its files. It will then display a set of instructions for a **one-time manual change** to your `java.security` file. You must perform this step. The script will pause and wait for you to press Enter before continuing.
    * **All Runs:** The script will then prompt you for the iDRAC IP address, username, and password. Enter the correct credentials for your iDRAC.

4.  **Enjoy the KVM Console!**
    * The script will attempt to download the necessary JAR files (if not present) and then launch the Java Virtual Console.

---

## Script Details & Arguments

The script works by directly invoking `java.exe` with a specific set of arguments that the iDRAC KVM applet expects. Here's a breakdown of the key arguments:

* `-cp <path_to_avctKVM.jar>`: Specifies the classpath, telling Java where to find the main KVM application JAR.
* `-Djava.library.path=<path_to_lib_folder>`: Points Java to the directory containing the native (OS-specific) libraries for keyboard and mouse support.
* `com.avocent.idrac.kvm.Main`: This is the full class name of the main entry point for the KVM application.
* `ip=<iDRAC_IP>`: The IP address of the iDRAC.
* `user=<username>`: Your iDRAC login username.
* `passwd=<password>`: Your iDRAC login password.
* `kmport=5900`, `vport=5900`, `apcp=1`, `version=2`, `vmprivilege=true`: Standard parameters passed by the iDRAC.
* `helpurl`, `title`: Additional informational parameters for the KVM viewer.

---

## Troubleshooting

### Common Errors and Solutions

* **`The remote certificate is invalid according to the validation procedure: RemoteCertificateNameMismatch, RemoteCertificateChainErrors`**
    * **Cause:** The iDRAC uses a self-signed or outdated SSL certificate, and PowerShell's `Invoke-WebRequest` is refusing to connect.
    * **Solution:** Ensure you are running PowerShell 7 or later. The script uses `-SkipCertificateCheck` which is the most reliable bypass. If this error persists, ensure no network proxies or antivirus software are interfering with SSL connections.
    * **Before Retrying:** Manually delete any partially downloaded or 0KB `.jar` files from your script directory and its `lib` subfolder to force a clean download.

* **`Error: Could not find or load main class C:\path\to\your\lib` (or similar path/JAR name)**
    * **Cause:** The Java Virtual Machine (`java.exe`) was launched, but it could not find or correctly load the `avctKVM.jar` file or its required main class (`com.avocent.idrac.kvm.Main`). This almost always means the JAR files were not downloaded correctly or are corrupted.
    * **Solution:**
        1.  **Verify Downloads:** Check the script's directory and its `lib` subfolder. Confirm that `avctKVM.jar`, `avctKVMIOWin32.jar`, and `avctVMWin32.jar` exist and have non-zero, reasonable file sizes (e.g., `avctKVM.jar` is typically ~1MB). If they are missing or 0KB, the download failed.
        2.  **Retry Download:** Delete any existing JARs and re-run the script.
        3.  **Correct Java Path:** The script will ask for this path on the first run. If you need to change it, simply delete the `iDRAC_config.json` file and re-run the script to enter the correct path.

* **`Invalid URI: The hostname could not be parsed.`**
    * **Cause:** This very unusual error indicates that PowerShell was unable to correctly construct the download URL, often due to invisible characters or a unique string interpolation issue in the user's environment.
    * **Solution:** The script now uses explicit string concatenation (`"https://" + $iDRAC_IP + ":443/..."`) to build URLs, which should mitigate this. If it re-appears, try re-typing the affected lines in a plain text editor to eliminate any hidden characters.

### KVM Viewer Specific Issues

* **"KVM Native Library - The Native library for keyboard and mouse support failed to load..." Warning:**
    * **Cause:** This is a very common message when using older iDRACs with newer Java/OS combinations. The specialized `.dll` files for direct keyboard/mouse hardware integration might not load due to Java security policies or OS compatibility.
    * **Impact:** "Pass All Keystrokes to Server" (e.g., Windows key combinations like Ctrl+Alt+Del through direct input) and "Single Cursor" support may not work. You will likely see two mouse cursors (your local and the remote one within the KVM window). You'll typically need to click inside the KVM window to "capture" your mouse and use a hotkey (often `Ctrl+Alt` or `Ctrl+Alt+Shift`) to "release" it. Special key combinations (like Ctrl+Alt+Del) are usually sent via a menu option in the KVM viewer itself.
    * **Solution:** If basic keyboard and mouse input works, this warning is usually safe to ignore.

* **Virtual Media (DVD/USB redirection) not working:**
    * This specific script focuses on launching the KVM. Virtual media functionality is usually accessed from within the opened KVM viewer window (look for a "Virtual Media" menu). The "Native Library" warning for keyboard/mouse should *not* directly affect Virtual Media functionality, as they rely on different underlying mechanisms.

---

## Contributing

Feel free to open issues or submit pull requests if you find bugs or have improvements!

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for the full text.
