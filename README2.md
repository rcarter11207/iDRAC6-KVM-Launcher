# Dell iDRAC KVM Launcher Script

A PowerShell script to directly launch the Dell iDRAC (and similar older iDRACs) Virtual Console (KVM) without relying on Java Web Start (.jnlp) and handling common SSL certificate and Java compatibility issues.

---

### Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [How to Use](#how-to-use)

---

### Introduction

Dell's older iDRAC versions (like iDRAC 6) often present challenges when trying to access their Virtual Console (KVM) on modern operating systems due to several factors:

1.  **Java Web Start (.jnlp) Deprecation:** Java Web Start, the technology used by these iDRACs to launch the KVM, has been deprecated and removed from modern Java versions.
2.  **SSL Certificate Issues:** Older iDRACs typically use self-signed SSL certificates or certificates with outdated algorithms, leading to browser warnings and connection failures.
3.  **Java Version Compatibility:** The KVM applets were built for specific, older Java Runtime Environment (JRE) versions (e.g., JRE 7) and are incompatible with newer JRE releases due to security changes and API removals.

This PowerShell script directly addresses these problems by:
* Bypassing Java Web Start.
* Ignoring SSL certificate validation during JAR downloads.
* Explicitly launching `java.exe` with the correct arguments and JRE 7.

### Features

* **Interactive Prompts:** Guides the user to input the iDRAC IP address, username, and password.
* **Secure Password Input:** A previous version of this script used `Read-Host -AsSecureString` for secure password entry, but this was removed because it caused corrupted data to be passed to the Java application. For maximum compatibility, the password is now entered as a standard string.
* **Automated File Downloads:** Checks for the necessary KVM JAR files and downloads them from the iDRAC web server if they are not already present.
* **Native Library Extraction:** It handles the complex process of downloading the native library JARs, extracting the `.dll` files, and placing them in the correct directory for the Java application to use.
* **One-Time Manual Security Step:** To address Java's strict security policies, the script provides clear, step-by-step instructions for a one-time manual change to your `java.security` file. A pause is included to give you time to complete this step. The script remembers that this has been done so you won't be prompted again.

### Prerequisites

* **Windows with PowerShell:** The script is written in PowerShell and is compatible with modern Windows versions.
* **Java 7 Installation:** A working installation of Java 7 (JRE) is required. The script is designed to work with JRE 7 as it is the last version officially compatible with iDRAC 6/7.

### How to Use

1.  **Save the Script:** Copy the code and save it as a `.ps1` file (e.g., `iDrac_KVM_Launcher.ps1`) in a directory of your choice.

2.  **Run the Script:** Open a PowerShell terminal and navigate to the directory where you saved the script. Execute the script with the following command:

    `.\iDrac_KVM_Launcher.ps1`

3.  **Follow the Prompts:** The script will guide you through a one-time setup for your file paths and then prompt you for the IP address, username, and password of the iDRAC you wish to connect to.

4.  **Perform the Manual Security Step:** On the first run, the script will pause and display instructions for modifying your `java.security` file. This is a critical step for the KVM viewer to function. Follow the instructions and press `Enter` to continue.

5.  **Launch the Viewer:** The script will automatically download the necessary files (if needed) and launch the iDRAC KVM viewer.
