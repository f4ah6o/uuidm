/// String conversion utilities for UUIDs

///|
/// Convert a byte to a two-character hexadecimal string
fn byte_to_hex(b : Byte) -> String {
  let high = (b.to_int() >> 4) & 0xF
  let low = b.to_int() & 0xF
  let high_char = if high < 10 {
    '0'.to_int() + high
  } else {
    'a'.to_int() + high - 10
  }
  let low_char = if low < 10 {
    '0'.to_int() + low
  } else {
    'a'.to_int() + low - 10
  }
  Int::unsafe_to_char(high_char).to_string() +
  Int::unsafe_to_char(low_char).to_string()
}

///|
/// Convert a hexadecimal character to its numeric value
fn hex_char_to_int(c : Char) -> Int {
  let code = c.to_int()
  if code >= '0'.to_int() && code <= '9'.to_int() {
    code - '0'.to_int()
  } else if code >= 'a'.to_int() && code <= 'f'.to_int() {
    code - 'a'.to_int() + 10
  } else if code >= 'A'.to_int() && code <= 'F'.to_int() {
    code - 'A'.to_int() + 10
  } else {
    abort("Invalid hexadecimal character: " + c.to_string())
  }
}

///|
/// Convert two hexadecimal characters to a byte
/// Note: Currently unused but kept for future string parsing improvements
fn _hex_to_byte(h : Char, l : Char) -> Byte {
  let high = hex_char_to_int(h)
  let low = hex_char_to_int(l)
  (high << 4).lor(low).to_byte()
}

///|
/// Convert UUID to string representation with hyphens
/// Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
pub fn Uuid::to_string(self : Uuid) -> String {
  let bytes = self.0
  byte_to_hex(bytes[0]) +
  byte_to_hex(bytes[1]) +
  byte_to_hex(bytes[2]) +
  byte_to_hex(bytes[3]) +
  "-" +
  byte_to_hex(bytes[4]) +
  byte_to_hex(bytes[5]) +
  "-" +
  byte_to_hex(bytes[6]) +
  byte_to_hex(bytes[7]) +
  "-" +
  byte_to_hex(bytes[8]) +
  byte_to_hex(bytes[9]) +
  "-" +
  byte_to_hex(bytes[10]) +
  byte_to_hex(bytes[11]) +
  byte_to_hex(bytes[12]) +
  byte_to_hex(bytes[13]) +
  byte_to_hex(bytes[14]) +
  byte_to_hex(bytes[15])
}

///|
/// Convert UUID to string representation without hyphens
pub fn Uuid::to_string_simple(self : Uuid) -> String {
  let bytes = self.0
  let mut result = ""
  for i = 0; i < 16; i = i + 1 {
    result = result + byte_to_hex(bytes[i])
  }
  result
}

///|
/// Parse UUID from string representation
/// Accepts both hyphenated (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) and non-hyphenated formats
pub fn from_string(s : String) -> Uuid? {
  // Must be exactly 32 hex characters (without hyphens) or 36 (with hyphens)
  let len = s.length()
  if len != 32 && len != 36 {
    return None
  }

  // Extract hex characters (removing hyphens if present)
  let mut hex_chars = ""
  for i = 0; i < len; i = i + 1 {
    let c = Int::unsafe_to_char(s.code_unit_at(i).to_int())
    if c == '-' {
      // Skip hyphens
    } else if (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F') {
      hex_chars = hex_chars + c.to_string()
    } else {
      // Invalid character
      return None
    }
  }

  // Must have exactly 32 hex characters after removing hyphens
  if hex_chars.length() != 32 {
    return None
  }

  // Convert each pair of hex characters to bytes
  let bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    let high_char = Int::unsafe_to_char(hex_chars.code_unit_at(i * 2).to_int())
    let low_char = Int::unsafe_to_char(hex_chars.code_unit_at(i * 2 + 1).to_int())

    // Check if characters are valid hex
    let high = try_hex_char_to_int(high_char)
    let low = try_hex_char_to_int(low_char)

    match (high, low) {
      (Some(h), Some(l)) => {
        bytes[i] = (h << 4).lor(l).to_byte()
      }
      _ => return None
    }
  }

  Some(Uuid::new(bytes))
}

///|
/// Try to convert a hexadecimal character to its numeric value
/// Returns None if the character is not a valid hex character
fn try_hex_char_to_int(c : Char) -> Int? {
  let code = c.to_int()
  if code >= '0'.to_int() && code <= '9'.to_int() {
    Some(code - '0'.to_int())
  } else if code >= 'a'.to_int() && code <= 'f'.to_int() {
    Some(code - 'a'.to_int() + 10)
  } else if code >= 'A'.to_int() && code <= 'F'.to_int() {
    Some(code - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Parse UUID from string, panics on invalid input
pub fn from_string_exn(s : String) -> Uuid {
  match from_string(s) {
    Some(uuid) => uuid
    None => abort("Invalid UUID string: " + s)
  }
}

///|
/// Convert UUID to URN string representation
/// Format: urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
pub fn Uuid::to_urn(self : Uuid) -> String {
  "urn:uuid:" + self.to_string()
}

///|
/// Parse UUID from URN string representation
pub fn from_urn(s : String) -> Uuid? {
  if s.length() > 9 {
    let uuid_part = s[9:].to_string() catch { _ => return None }
    from_string(uuid_part)
  } else {
    None
  }
}

///|
/// Parse UUID from URN string, panics on invalid input
pub fn from_urn_exn(s : String) -> Uuid {
  match from_urn(s) {
    Some(uuid) => uuid
    None => abort("Invalid UUID URN: " + s)
  }
}
