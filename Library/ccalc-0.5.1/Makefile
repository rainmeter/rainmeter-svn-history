CC = gcc

TARGET = ccalc

CFLAGS = -Wall -pedantic -s -O2

LDFLAGS = $(CFLAGS)

OBJECTS = mparser.o lexer.o strmap.o

MAJOR = 0
MINOR = 5
REVISION = 0
VERSION = $(MAJOR).$(MINOR).$(REVISION)

HEADERS = strmap.h lexer.h mparser.h

# linux

INCLUDEDIR = /usr/include
INSTALLDIR = /usr/local/bin
LIBDIR  = /usr/lib

# windoze

DLLTOOL = dlltool --as=as --dllname

WINDEVELBASE = D:\gcc-2.95.2\i386-mingw32
WININCLDIR = $(WINDEVELBASE)\include
WINLIBDIR = $(WINDEVELBASE)\lib
WINSYSDIR = C:\\WINDOWS\\SYSTEM
WINNTDIR = C:\\WINNT\\SYSTEM32
IMPORTLIB = lib$(TARGET).a
DLLOBJECTS = $(OBJECTS) wininit.o

WINLIBS = -lcrtdll

# ------- unix target definitions ---------------------------

LIBRARY = lib$(TARGET).so
ARNAME  = lib$(TARGET).a
LIBNAME = $(LIBRARY).$(VERSION)
FULLLIB = $(LIBDIR)/$(LIBRARY)

# ------- unix/win binary -----------------------------------

ccalc: $(OBJECTS) ccalc.o
	$(CC) $(LDFLAGS) ccalc.o $(OBJECTS) -lm -o $@

# ------- unix install --------------------------------------

install: ccalc
	cp ccalc $(INSTALLDIR)

# linux library

linux-so-install: linux-so
	rm -f $(LIBDIR)/$(LIBRARY).$(MAJOR) $(LIBDIR)/$(LIBRARY) \
	    $(LIBDIR)/$(LIBRARY).$(VERSION)
	mv $(LIBRARY)* $(LIBDIR)
	mkdir -p $(INCLUDEDIR)/ccalc
	cp $(HEADERS) $(INCLUDEDIR)/ccalc
linux-so: $(LIBRARY)
$(LIBRARY): $(LIBNAME)
	cd $(LIBDIR)
	rm -f $(LIBRARY).$(MAJOR) $(LIBRARY)
	ln -s $(LIBRARY).$(VERSION) $(LIBRARY).$(MAJOR)
	ln -s $(LIBRARY).$(MAJOR) $(LIBRARY)
$(LIBNAME): $(OBJECTS)
	gcc $(CFLAGS) -shared -Wl,-soname,$(LIBRARY).$(MAJOR) -o \
	    $(LIBRARY).$(VERSION) $(OBJECTS)

clean:
	rm -f *.o ccalc core *.exe *.bb *.out *.base *.exp *.dll *.so

# windoze library

$(TARGET).dll: $(DLLOBJECTS) $(TARGET).def 
	ld --base-file $(TARGET).base --dll -o $(TARGET).dll $(DLLOBJECTS) $(WINLIBS) -e _dll_entry@12
	$(DLLTOOL) $(TARGET).dll --def $(TARGET).def --base-file $(TARGET).base --output-exp $(TARGET).exp
	ld --base-file $(TARGET).base $(TARGET).exp --dll -o $(TARGET).dll $(DLLOBJECTS) $(WINLIBS) -e _dll_entry@12
	$(DLLTOOL) $(TARGET).dll --def $(TARGET).def --base-file $(TARGET).base --output-exp $(TARGET).exp
	ld $(TARGET).exp --dll -o $(TARGET).dll $(DLLOBJECTS) $(WINLIBS) -e _dll_entry@12
	strip $(TARGET).dll
$(IMPORTLIB):
	dlltool --def $(TARGET).def --dllname $(TARGET).dll --output-lib $(IMPORTLIB)
win32-dll: $(TARGET).dll
win32-dll-install: $(TARGET).dll
	copy $(TARGET).dll $(WINSYSDIR)
winnt-dll-install: $(TARGET).dll
	copy $(TARGET).dll $(WINNTDIR)
win32-import: $(IMPORTLIB)
win32-import-install: $(IMPORTLIB) $(HEADERS)
	copy *.h $(WININCLDIR)
	copy $(IMPORTLIB) $(WINLIBDIR)
win32-clean:
	del *.o
	del *.so*
	del core
	del *.dll
	del *.base
	del *.ex*
	del *.a

# common rules

.c.o:
	$(CC) -c $(CFLAGS) $<

# depends

ccalc.o: ccalc.c mparser.h
mparser.o: mparser.c mparser.h lexer.h strmap.h pack.h
lexer.o: lexer.c lexer.h
strmap.o: strmap.c strmap.h
wininit.o: wininit.c