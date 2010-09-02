import std.stdio;
import window_manager;

version(unittest) {
  void main() {}
} else {
  void main(string[] argv) {
    Window window = findWindowByProcessName(argv[1]);

    if (window) {
      writeln(window.name, " (", window.processName, ")");
    } else {
      writeln("not found");
    }
  }
}
