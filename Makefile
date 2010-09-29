PROGRAM = gimme
MAIN_SOURCE = main.d

COMMON_DFLAGS  = -I~/include
DEBUG_DFLAGS   = $(COMMON_DFLAGS) -w -wi
RELEASE_DFLAGS = $(COMMON_DFLAGS) -inline -release -O

ifdef RELEASE
DFLAGS = $(RELEASE_DFLAGS)
else
DFLAGS = $(DEBUG_DFLAGS)
endif

TEST_PROGRAM = $(PROGRAM)_test

$(PROGRAM): $(MAIN_SOURCE)
	rdmd --build-only -of$(PROGRAM) $(DFLAGS) $(MAIN_SOURCE)

build: $(PROGRAM)

run: build
	./$(PROGRAM)

test: $(SOURCES)
	rdmd $(DFLAGS) -unittest $(MAIN_SOURCE)

clean:
	rm -f *.o
	rm -f $(PROGRAM)
	rm -f $(TEST_PROGRAM)
