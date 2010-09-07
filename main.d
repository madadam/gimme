import std.path;
import std.process;
import std.stdio;
import window_manager;

import core.sys.posix.unistd;

version(unittest) {
  void main() {}
} else {
  void main(string[] argv) {
    if (argv.length < 2) {
      writeln("Usage: ", basename(argv[0]), " program_name [program arguments]");
    }

    auto window = findMatchingWindow(argv[1]);

    if (window) {
      window.activate();
    } else {
      forkAndRun(argv[1], argv[2 .. $]);
    }
  }
}

private void forkAndRun(in string command, in string[] args) {
  pid_t pid = fork();

  if (!pid) {
    // FIXME: Doesn't work with gvim
    // execvp(command, args);

    system(command);
  }
}
