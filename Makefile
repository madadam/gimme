PROGRAM = gimme
SOURCES = main.d string_helpers.d window_manager.d libs/X11/X.d libs/X11/Xlib.d libs/X11/Xatom.d

COMMON_DFLAGS  = -L-lX11
DEBUG_DFLAGS   = $(COMMON_DFLAGS) -w -wi
RELEASE_DFLAGS = $(COMMON_DFLAGS) -inline -release -O

DFLAGS         = $(RELEASE_DFLAGS)

TEST_PROGRAM = $(PROGRAM)_test

$(PROGRAM): $(SOURCES)
	dmd -of$(PROGRAM) $(DFLAGS) $(SOURCES)

build: $(PROGRAM)

run: build
	./$(PROGRAM)

test: $(SOURCES)
	dmd -of$(TEST_PROGRAM) $(DFLAGS) -unittest $(SOURCES)
	./$(TEST_PROGRAM)

clean:
	rm -f *.o
	rm -f $(PROGRAM)
	rm -f $(TEST_PROGRAM)
