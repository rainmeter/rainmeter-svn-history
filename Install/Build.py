#!/usr/bin/python
#
# Run in the Install/ folder!
#

#import sys, pysvn, os, zipfile, glob, shutil, datetime
import sys, os, zipfile, glob, shutil, datetime
import UpdateRevision

#g_Msvc = "C:\Program Files\Microsoft Visual Studio 9.0\Common7\IDE\VCExpress.exe"
#g_Solution = "Rainmeter.sln"

g_Version = "1.3"
g_Msvc = "vcbuild"
g_MainPath = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), os.pardir))
g_NsisPath = "C:\\Program Files\\NSIS\\MakeNSIS.exe"
g_Aut2exe = "C:\\Program Files\\AutoIt3\\Aut2Exe\\Aut2exe.exe"
g_SVN = "C:\\Program Files\\SlikSvn\\bin\\svn.exe"

###########################################################
# Compiles the project and the plugins
###########################################################
def Compile(config, platform):
    print "Compiling"
#    cmd = '"' + g_Msvc + '" ' + os.path.join(g_MainPath, g_Solution) + ' /rebuild ' + config + ' /platform:' + platform 
#    os.system(cmd)

    cmd = '"' + g_Msvc + '" ' + os.path.join(g_MainPath, "Library", "Library.vcproj") + ' /r ' + config + ' /platform:' + platform 
    os.system(cmd)
    cmd = '"' + g_Msvc + '" ' + os.path.join(g_MainPath, "Application", "Application.vcproj") + ' /r ' + config + ' /platform:' + platform 
    os.system(cmd)

    plugins = ["PluginAdvancedCPU", "PluginMBM5", "PluginPerfMon", "PluginMediaKey", "PluginPing", "PluginPower", "PluginQuote", "PluginRecycleManager", "PluginResMon", "PluginSpeedFan", "PluginSysInfo", "PluginWebParser", "PluginWindowMessage", "PluginWirelessInfo", "PluginiTunes", "PluginWifiStatus", "PluginWin7Audio", "PluginVirtualDesktops"]

    for plugin in plugins:
        cmd = '"' + g_Msvc + '" ' + os.path.join(g_MainPath, "Plugins", plugin, plugin + ".vcproj") + ' /r ' + config + ' /platform:' + platform 
        os.system(cmd)

###########################################################
# Collects everything to the distrib folder
###########################################################
def CreateDistrib(dir, vcredist):
    DeleteFolder(os.path.join(g_MainPath, "Distrib", dir))

    distribPath = os.path.join(g_MainPath, "Distrib", dir)
    releasePath = os.path.join(g_MainPath, "Testbench", dir, "release")
    addonsPath = os.path.join(distribPath, "Addons")

    os.makedirs(distribPath)
    os.makedirs(addonsPath)

    # Copy files to distrib
    shutil.copytree(os.path.join(g_MainPath, "Install", "Skins"), os.path.join(distribPath, "Skins"), ignore=shutil.ignore_patterns('.svn', 'source'))
    shutil.copytree(os.path.join(g_MainPath, "Install", "Themes"), os.path.join(distribPath, "Themes"), ignore=shutil.ignore_patterns('.svn'))
    shutil.copytree(os.path.join(releasePath, "Plugins"), os.path.join(distribPath, "Plugins"))
    shutil.copy2(os.path.join(g_MainPath, "Install", "Default.ini"), distribPath)
    shutil.copy2(os.path.join(releasePath, "Rainmeter.dll"), distribPath)
    shutil.copy2(os.path.join(releasePath, "Rainmeter.exe"), distribPath)
    shutil.copy2(os.path.join(g_MainPath, "Plugins", "PluginWirelessInfo", "wirelessuio.inf"), os.path.join(distribPath, "Plugins"))
    shutil.copy2(os.path.join(g_MainPath, "Plugins", "PluginWirelessInfo", "wirelessuio.sys"), os.path.join(distribPath, "Plugins"))
    shutil.copy2(os.path.join(g_MainPath, "install", "runtime", "vcredist_" + vcredist + ".exe"), distribPath)

    rainThemesReleasePath = os.path.join(g_MainPath, "Addons", "RainThemes", "Release")
    rainThemesSourcePath = os.path.join(g_MainPath, "Addons", "RainThemes", "Source")
    rainThemesDistribPath = os.path.join(addonsPath, "RainThemes")
    os.makedirs(rainThemesDistribPath)
    shutil.copy2(os.path.join(rainThemesReleasePath, "RainThemes.exe"), rainThemesDistribPath)
    shutil.copy2(os.path.join(rainThemesSourcePath, "RainThemes.bmp"), rainThemesDistribPath)	

    rainBackupReleasePath = os.path.join(g_MainPath, "Addons", "RainBackup", "Release")
    rainBackupSourcePath = os.path.join(g_MainPath, "Addons", "RainBackup", "Source")
    rainBackupDistribPath = os.path.join(addonsPath, "RainBackup")
    os.makedirs(rainBackupDistribPath)
    shutil.copy2(os.path.join(rainBackupReleasePath, "RainBackup.exe"), rainBackupDistribPath)
	
    rainBrowserReleasePath = os.path.join(g_MainPath, "Addons", "RainBrowser", "Release")
    rainBrowserHelpPath = os.path.join(g_MainPath, "Addons", "RainBrowser", "Help")
    rainBrowserSourcePath = os.path.join(g_MainPath, "Addons", "RainBrowser", "Source")
    rainBrowserDistribPath = os.path.join(addonsPath, "RainBrowser")
    os.makedirs(rainBrowserDistribPath)
    shutil.copy2(os.path.join(rainBrowserReleasePath, "RainBrowser.exe"), rainBrowserDistribPath)

    rainStallerReleasePath = os.path.join(g_MainPath, "Addons", "Rainstaller", "Release")
    rainStallerSourcePath = os.path.join(g_MainPath, "Addons", "Rainstaller", "Source")
    rainStallerDistribPath = os.path.join(addonsPath, "Rainstaller")
    os.makedirs(rainStallerDistribPath)
    shutil.copy2(os.path.join(rainStallerReleasePath, "Rainstaller.exe"), rainStallerDistribPath)

###########################################################
# Creates the installer
###########################################################
def BuildInstaller(bits, flags, revision, beta):
    # Build the installers
    cmd = '"' + g_NsisPath + '" /DBETA /D' + flags + " " + os.path.join(g_MainPath, "Install", "RAINME~1.NSI")
    os.system(cmd)
    d = datetime.date.today()
    
    if revision > 0:
        target = "Rainmeter-" + g_Version + "-r%i-" % (revision) + bits + beta + ".exe"
    else:
        target = "Rainmeter-" + g_Version + "-" + bits + beta + ".exe"
        
    try:
        os.remove(target)
    except OSError:
        print "Unable to delete " + target
    os.rename("Rainmeter-Latest-" + bits + ".exe", target)

###########################################################
# Creates a zip archive from all distrib files (except the runtime installer)
###########################################################
def ArchiveDistrib(bits, dir):
    global g_MainPath, g_Version

    distribPath = os.path.join(g_MainPath, "Distrib", dir)
    
    # Create archive
    zipName = "Rainmeter-%s-%s.zip" % (g_Version, bits)
    
    zipPath = os.path.join(g_MainPath, "Install", zipName)
    zip = zipfile.ZipFile(zipPath, "w", zipfile.ZIP_DEFLATED)
    
    for root, dirs, allfiles in os.walk(distribPath):
        for name in allfiles:
            if (name[:8] != "vcredist"):
                print "Archiving " + os.path.join(root, name)[len(g_MainPath) + 1:]
                zip.write(os.path.join(root, name), os.path.join(root, name)[len(distribPath) + 1:], zipfile.ZIP_DEFLATED)
    zip.close()

###########################################################
# Creates a zip archive from all PDB files
###########################################################
def ArchivePDBs(revision):
    global g_MainPath, g_Version
    
    # Create archive
    if revision > 0:
        zipName = "Rainmeter-%s-r%i-PDBs.zip" % (g_Version, revision)
    else:
        zipName = "Rainmeter-%s-PDBs.zip" % (g_Version)
    
    zipPath = os.path.join(g_MainPath, "Install", zipName)
    zip = zipfile.ZipFile(zipPath, "w", zipfile.ZIP_DEFLATED)
    
    for root, dirs, allfiles in os.walk(g_MainPath):
        for name in allfiles:
            if (name[-3:] == "pdb" and name != "vc90.pdb" and name != "vc70.pdb"):
                if root.find("Release") != -1:
                    print "Archiving " + os.path.join(root, name)[len(g_MainPath) + 1:]
                    zip.write(os.path.join(root, name), os.path.join(root, name)[len(g_MainPath) + 1:], zipfile.ZIP_DEFLATED)
    zip.close()

##########################################################
# Deletes the specified folder from the hard drive
###########################################################
def DeleteFolder(folder):
    os.system("rmdir /S /Q " + folder)

##########################################################
# Builds the addons which are include in the installer
###########################################################
def BuildAddons():
    # EnigmaConfigure
    print "Building EnigmaConfigure"
    enigmaConfigureSourcePath = os.path.join(g_MainPath, "Install", "Skins", "Enigma", "Resources", "Variables", "Source")
    enigmaConfigureReleasePath = os.path.join(g_MainPath, "Install", "Skins", "Enigma", "Resources", "Variables")
    try:
        os.makedirs(enigmaConfigureReleasePath)
    except WindowsError:
        print "Release folder already exists"

    cmd = '"' + g_Aut2exe + '" /in ' + os.path.join(enigmaConfigureSourcePath, "EnigmaConfigure.au3") + \
          ' /icon ' + os.path.join(enigmaConfigureSourcePath, "EnigmaConfigure.ico") + \
          ' /out ' + os.path.join(enigmaConfigureReleasePath, "EnigmaConfigure.exe")
    os.system(cmd)


    # RainThemes
    print "Building RainThemes"
    rainThemesSourcePath = os.path.join(g_MainPath, "Addons", "RainThemes", "Source")
    rainThemesReleasePath = os.path.join(g_MainPath, "Addons", "RainThemes", "Release")
    try:
        os.makedirs(rainThemesReleasePath)
    except WindowsError:
        print "Release folder already exists"
    
    cmd = '"' + g_Aut2exe + '" /in ' + os.path.join(rainThemesSourcePath, "RainThemes.au3") + \
          ' /icon ' + os.path.join(rainThemesSourcePath, "rT.ico") + \
          ' /out ' + os.path.join(rainThemesSourcePath, "..\Release", "RainThemes.exe")
    os.system(cmd)
	
    # RainBackup
    print "Building RainBackup"
    rainBackupSourcePath = os.path.join(g_MainPath, "Addons", "RainBackup", "Source")
    rainBackupReleasePath = os.path.join(g_MainPath, "Addons", "RainBackup", "Release")
    try:
        os.makedirs(rainBackupReleasePath)
    except WindowsError:
        print "Release folder already exists"
    
    cmd = '"' + g_Aut2exe + '" /in ' + os.path.join(rainBackupSourcePath, "RainBackup.au3") + \
          ' /icon ' + os.path.join(rainBackupSourcePath, "rBk.ico") + \
          ' /out ' + os.path.join(rainBackupSourcePath, "..\Release", "RainBackup.exe")
    os.system(cmd)	

    # RainBrowser
    print "Building RainBrowser"
    rainBrowserSourcePath = os.path.join(g_MainPath, "Addons", "RainBrowser", "Source")
    rainBrowserReleasePath = os.path.join(g_MainPath, "Addons", "RainBrowser", "Release")
    try:
        os.makedirs(rainBrowserReleasePath)
    except WindowsError:
        print "Release folder already exists"
    
    cmd = '"' + g_Aut2exe + '" /in ' + os.path.join(rainBrowserSourcePath, "RainBrowser.au3") + \
          ' /icon ' + os.path.join(rainBrowserSourcePath, "rB.ico") + \
          ' /out ' + os.path.join(rainBrowserSourcePath, "..\Release", "RainBrowser.exe")
    os.system(cmd)
	
###########################################################
# Build Rainstaller
###########################################################
def BuildRainstaller(bits):
    print "Building Rainstaller"
    rainStallerSourcePath = os.path.join(g_MainPath, "Addons", "Rainstaller", "Source")
    rainStallerReleasePath = os.path.join(g_MainPath, "Addons", "Rainstaller", "Release")
    try:
        os.makedirs(rainStallerReleasePath)
    except WindowsError:
        print "Release folder already exists"
    cmd = '"' + g_NsisPath + '" /D' + bits + " " + os.path.join(rainStallerSourcePath, "Rainstaller.nsi")
    os.system(cmd)

##########################################################
# The main function
###########################################################
def main():
    global g_Version
    
    if len(sys.argv) < 2:
        print "Usage: script.py [RELEASE/BETA]"
    else:
        #cmd = '"' + g_SVN + '" update'
        #os.system(cmd)

        if sys.argv[1] == "BETA" or sys.argv[1] == "beta":
            revision = UpdateRevision.UpdateRevision()

            BuildAddons()
            
            Compile("Release", "Win32")
            BuildRainstaller("x32")
            CreateDistrib("x32", "x86")
            BuildInstaller("32bit", "X32", revision, "-beta")

            Compile("Release64", "x64")
            BuildRainstaller("x64")
            CreateDistrib("x64", "x64")
            BuildInstaller("64bit", "X64", revision, "-beta")
            
            ArchivePDBs(revision)
            
            print "BETA DONE"
        elif sys.argv[1] == "RELEASE" or sys.argv[1] == "release":
            UpdateRevision.UpdateRevision()
            revision = 0

            BuildAddons()
            
            Compile("Release", "Win32")
            BuildRainstaller("x32")
            CreateDistrib("x32", "x86")
            BuildInstaller("32bit", "X32", 0, "")
            ArchiveDistrib("32bit", "x32")

            Compile("Release64", "x64")
            BuildRainstaller("x64")
            CreateDistrib("x64", "x64")
            BuildInstaller("64bit", "X64", 0, "")
            ArchiveDistrib("64bit", "x64")

            ArchivePDBs(revision)
       
            print "RELEASE DONE"
        else:
   	        print "Give RELEASE or BETA as parameter"

if __name__=="__main__":
        main()
