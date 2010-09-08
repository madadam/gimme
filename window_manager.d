import std.algorithm;
import std.exception;
import std.conv;
import std.c.string;
import std.file;
import std.string : tolower;

import xlib  = std.c.linux.X11.Xlib;
import xatom = std.c.linux.X11.Xatom;

private xlib.Display* display;
private xlib.Atom atom_NET_ACTIVE_WINDOW;
private xlib.Atom atom_NET_CLIENT_LIST;
private xlib.Atom atom_NET_WM_PID;

static this() {
  display = xlib.XOpenDisplay(null);
  enforce(display, "Display can't be opened.");
    
  atom_NET_ACTIVE_WINDOW = internAtom("_NET_ACTIVE_WINDOW");
  atom_NET_CLIENT_LIST   = internAtom("_NET_CLIENT_LIST");
  atom_NET_WM_PID        = internAtom("_NET_WM_PID");
}
 
private xlib.Atom internAtom(string name) {
  return xlib.XInternAtom(display, cast(byte*) name, xlib.Bool.True);
}

@property
private xlib.Window rootWindow() {
  return xlib.XDefaultRootWindow(display);
}

unittest {
  assert(!Window(0), "window with null handle should evaluate to false");
  assert( Window(1), "window with non-null handle should evaluate to true");
}

/**
 * A window.
 */
struct Window {
  bool opCast(T)() if (is(T == bool)) {
    return _handle != 0;
  }

  /**
   * Window title.
   */
  @property
  string title() {
    byte* rawBytes;
 
    if (xlib.XFetchName(display, _handle, &rawBytes)) {
      scope(exit) xlib.XFree(rawBytes);
      auto rawChars = cast(char*) rawBytes;

      return cast(string) rawChars[0 .. strlen(rawChars)].dup;
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

  /**
   * Activate (raise and give focus) the window.
   */
  void activate() {
    xlib.XEvent event;
    event.xclient.type         = xlib.EventType.ClientMessage;
    event.xclient.message_type = atom_NET_ACTIVE_WINDOW;
    event.xclient.display      = display;
    event.xclient.window       = _handle;
    event.xclient.format       = 32;
    event.xclient.l[0]         = 0;
    event.xclient.l[1]         = xlib.CurrentTime;
    event.xclient.l[2]         = 0;
    event.xclient.l[3]         = 0;
    event.xclient.l[4]         = 0;
    
    xlib.XSendEvent(display, rootWindow, xlib.Bool.False, 
                    xlib.EventMask.SubstructureRedirectMask |
                    xlib.EventMask.SubstructureNotifyMask,
                    &event);
    xlib.XFlush(display);
  }

  private this(xlib.Window handle) {
    _handle = handle;
  }

  private xlib.Window _handle;
}

/**
 * Find window that matches the given text.
 * 
 * The match is done agains the name of the window's process and against the
 * window title.
 */
Window findMatchingWindow(string pattern) {
  foreach(window; topLevelWindows()) {
    // TODO: match window class instead of window title.
    if (matches(window.processName, pattern) || matches(window.title, pattern)) {
      return window;
    }
  }

  return Window(0);
}

// case-insensitive substring match.
private bool matches(string sample, string pattern) {
  return indexOf(tolower(sample), tolower(pattern)) > -1;
}

private Window[] topLevelWindows() {
  auto items = readWindowProperty(rootWindow, atom_NET_CLIENT_LIST);
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
 
private string processName(uint pid) {
  auto name = "/proc/" ~ to!string(pid) ~ "/cmdline";
  
  if (exists(name)) {
    return readText(name);
  } else {
    return null;
  }
}

