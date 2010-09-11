import std.array;

unittest {
  // 7bit ascii character
  assert("a" == fromStringz((cast(char[]) ['a', 0]).ptr));

  // 2-byte utf8 character
  assert("á" == fromStringz((cast(char[]) [0b11000011, 0b10100001, 0]).ptr));

  // TODO: 3-byte utf8 character
  // TODO: 4-byte utf8 character

  // invalid 1-byte code point
  assert("x" == fromStringz((cast(char[]) ['x', 0b11111111, 0]).ptr));
  assert("x" == fromStringz((cast(char[]) ['x', 0b10100000, 0]).ptr));

  // invalid 2-byte code point
  assert("x" == fromStringz((cast(char[]) ['x', 0b11010000, 0b11111111, 0]).ptr));
  assert("x" == fromStringz((cast(char[]) ['x', 0b11010000, 0]).ptr));
  
  // invalid 3-byte code point
  assert("x" == fromStringz((cast(char[]) ['x', 0b11101000, 0b11111111, 0]).ptr));
  assert("x" == fromStringz((cast(char[]) ['x', 0b11101000, 0b10100000, 0b11111111, 0]).ptr));
  assert("x" == fromStringz((cast(char[]) ['x', 0b11101000, 0]).ptr));
  assert("x" == fromStringz((cast(char[]) ['x', 0b11101000, 0b10100000, 0]).ptr));

  // TODO: invalid 4-byte code point
}

// Converts 0-terminated C-style string into D-style string. Assumes the input
// string is encoded as utf8, but skips any invalid code units.
protected string fromStringz(char* stringz) {
  string result;
  auto   output = appender(&result);
  char*  input = stringz;

  while(readCodePoint(output, input)) {}

  return result;
}

private {
  bool readCodePoint(Appender!string output, ref char* input) {
    if (input is null) {
      return false;
    }

    return readCodePointOfLength!1(output, input) ||
           readCodePointOfLength!2(output, input) ||
           readCodePointOfLength!3(output, input) ||
           readCodePointOfLength!4(output, input) ||
           skipInvalidCodePoint(input);
  }

  pure bool isStart(int bytes)(char unit) {
    if (unit == 0) {
      return false;
    }

    static if (bytes == 1) {
      return (unit & 0b10000000) == 0b00000000;
    } else if (bytes == 2) {
      return (unit & 0b11100000) == 0b11000000;
    } else if (bytes == 3) {
      return (unit & 0b11110000) == 0b11100000;
    } else if (bytes == 4) {
      return (unit & 0b11111000) == 0b11110000;
    } else {
      assert(false, "bytes can be only 1, 2, 3 or 4");
    }
  }

  pure bool isContinuation(char unit) {
    return (unit & 0b11000000) == 0b10000000;
  }

  pure bool areContinuations(int number)(char* input) {
    static if (number > 0) {
      foreach(i; 0 .. number) {
        if (!isContinuation(input[i])) {
          return false;
        }
      }
    }

    return true;
  }

  bool readCodePointOfLength(int bytes)(Appender!string output, ref char* input) {
    if (isStart!bytes(*input) && areContinuations!(bytes - 1)(input + 1)) {
      copyCodeUnits(output, input, bytes);
      return true;
    } else {
      return false;
    }
  }

  bool skipInvalidCodePoint(ref char* input) {
    if (input[0] != 0) {
      input += 1;
      return true;
    } else {
      return false;
    }
  }

  void copyCodeUnits(Appender!string output, ref char* input, int number) {
    output.put(cast(string) input[0 .. number]);
    input += number;
  }
}
