PROGRAM = gimme
SOURCES = main.d window_manager.d libs/X11/X.d libs/X11/Xlib.d
DFLAGS  = -L-lX11

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
