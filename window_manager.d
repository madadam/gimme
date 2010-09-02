import std.algorithm;
import std.contracts;
import std.conv;
import std.c.string;
import std.file;

import xlib = std.c.linux.X11.Xlib;

private xlib.Display* display;
private xlib.Atom atom_NET_WM_PID;
private xlib.Atom atom_NET_CLIENT_LIST;

static this() {
  display = xlib.XOpenDisplay(null);
  enforce(display, "Display can't be opened.");
    
  atom_NET_WM_PID      = xlib.XInternAtom(display, cast(byte*) "_NET_WM_PID", xlib.Bool.True);
  atom_NET_CLIENT_LIST = xlib.XInternAtom(display, cast(byte*) "_NET_CLIENT_LIST", xlib.Bool.True);
}
  
unittest {
  assert(!Window(0), "window with null handle should evaluate to false");
  assert( Window(1), "window with non-null handle should evaluate to true");
}

/**
 * A window.
 */
immutable struct Window {
  bool opCast(T)() if (is(T == bool)) {
    return _handle != 0;
  }

  /**
   * Window name.
   */
  @property
  string name() {
    byte* rawName;
 
    if (xlib.XFetchName(display, _handle, &rawName)) {
      return fromStringz(cast(char*) rawName);
    } else {
      return null;
    }
  }

  /**
   * Id of the process of this window.
   */
  @property
  uint processId() {
    return readWindowProperty(_handle, atom_NET_WM_PID)[0];
  }

  /**
   * Name of the process of this window.
   */
  @property
  string processName() {
    return .processName(processId);
  }

  private this(xlib.Window handle) {
    _handle = handle;
  }

  private xlib.Window _handle;
}

Window findWindowByProcessName(string name) {
  foreach(window; topLevelWindows()) {
    if (indexOf(window.processName, name) > -1) {
      return window;
    }
  }

  return Window(0);
}

private immutable(Window)[] topLevelWindows() {
  auto items = readWindowProperty(xlib.XDefaultRootWindow(display), atom_NET_CLIENT_LIST);
  typeof(return) results;

  foreach(item; items) {
    results ~= Window(cast(xlib.Window) item);
  }

  return results;
}

private uint[] readWindowProperty(xlib.Window window, xlib.Atom property) {
  xlib.Atom actualType;
  int format;
  uint numItems;
  uint bytesAfter;
  ubyte* data;
  
  xlib.XGetWindowProperty(display, window, property, 
                          0, uint.max, xlib.Bool.False, xlib.AnyPropertyType, 
                          &actualType, &format, &numItems, &bytesAfter, &data);
  scope(exit) xlib.XFree(data);

  enforce(format == 32);
  enforce(bytesAfter == 0);

  return (cast(uint*) data)[0 .. numItems].dup;
}

unittest {
  char[6] stringz = ['h', 'e', 'l', 'l', 'o', '\0'];

  assert("hello" == fromStringz(cast(char*) stringz));
}

private string fromStringz(const(char)* input) {
  return cast(string) input[0 .. strlen(input)];
}
 
private string processName(uint pid) {
  auto name = "/proc/" ~ to!string(pid) ~ "/cmdline";
  
  if (exists(name)) {
    return readText(name);
  } else {
    return null;
  }
}

