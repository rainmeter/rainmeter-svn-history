#!/usr/bin/python
import sys, os

g_SVN = "C:\\PROGRA~1\\SlikSvn\\bin\\svn.exe"
g_Output = "..\\revision-number.h"

def UpdateRevision():
    result = os.popen3(g_SVN + " info")                                                      
    output = result[1].readlines()
  
    for line in output:
        if line[:9] == "Revision:":
            revision = int(line[10:])

    f = open(g_Output, "w")
    f.write("#pragma once\n")
    f.write("const int revision_number = %i;" % revision)
    f.write("\n")
    f.write("const bool revision_beta = true;")
    f.close();

    print "Updated " + g_Output + " to revision " + str(revision)
    cmd = ".\UpdateApplicationRC.exe"
    os.system(cmd)	
	
    return revision

if __name__=="__main__":
  UpdateRevision()
