iDRAC KVM Launcher Script
This PowerShell script provides a robust and automated solution for launching the KVM (Keyboard, Video, Mouse) console on older Dell iDRAC devices (e.g., iDRAC 6 and 7). These consoles often rely on outdated Java applets that are no longer compatible with modern browsers and Java installations.

This script streamlines the process by handling file downloads, native library extraction, and command-line arguments, making it a reliable tool for system administrators.

Key Features and Changes
This script has been refined to address common pain points and to be a self-contained, user-friendly solution.

Interactive Prompts: The script removes all hardcoded variables (IP address, username, password, file paths). It interactively prompts you for this information at runtime.

Persistent Configuration: On the very first run, the script will ask for your Java installation path and a directory for its files. It saves this information to a iDRAC_config.json file so you won't have to enter it again.

Automated File Setup: The script checks for the required KVM JAR files. If they are not found, it automatically downloads them from the specified iDRAC.

Native Library Extraction: It handles the complex process of downloading the native library JARs, extracting the .dll files, and placing them in the correct directory for the Java application to use. It also cleans up the temporary JAR files to keep your directories tidy.

One-Time Manual Security Step: To address Java's strict security policies, the script provides clear, step-by-step instructions for a one-time manual change to your java.security file. A pause is included to give you time to complete this step. The script remembers that this has been done so you won't be prompted again.

Prerequisites
Windows with PowerShell: The script is written in PowerShell and is compatible with modern Windows versions.

Java 7 Installation: A working installation of Java 7 (JRE) is required. The script is designed to work with JRE 7 as it is the last version officially compatible with iDRAC 6/7.

How to Use
Save the Script: Copy the code and save it as a .ps1 file (e.g., iDrac_KVM_Launcher.ps1) in a directory of your choice.

Run the Script: Open a PowerShell terminal and navigate to the directory where you saved the script. Execute the script with the following command:

.\iDrac_KVM_Launcher.ps1

Follow the Prompts: The script will guide you through a one-time setup for your file paths and then prompt you for the IP address, username, and password of the iDRAC you wish to connect to.

Perform the Manual Security Step: On the first run, the script will pause and display instructions for modifying your java.security file. This is a critical step for the KVM viewer to function. Follow the instructions and press Enter to continue.

Launch the Viewer: The script will automatically download the necessary files (if needed) and launch the iDRAC KVM viewer.
