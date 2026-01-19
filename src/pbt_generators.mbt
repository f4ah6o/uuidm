/// Custom Property-Based Testing Generators for uuidm
///
/// 分布制御付きジェネレータ:
/// - Normal (60-70%): 通常ケース
/// - Edge (15-20%): エッジケース (nil, max, 空文字列, etc.)
/// - Boundary (10-15%): 境界値

///|
/// Generate a random UUID with distribution control
/// Normal: v4() random UUIDs
/// Edge: nil and max UUIDs
/// Boundary: deterministic v4 pattern
fn gen_uuid() -> Uuid {
  // Use random bytes for distribution control
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF
  if freq < 165 {
    // Normal: ~65% random v4
    v4()
  } else if freq < 216 {
    // Edge: ~20% special cases (nil, max)
    let special_bytes = random_bytes(1)
    if (special_bytes[0].to_int() & 1) == 0 {
      nil()
    } else {
      max()
    }
  } else {
    // Boundary: ~15% custom bytes
    let custom = random_bytes(16)
    v8(custom)
  }
}

///|
/// Generate a UUID string with distribution control
fn gen_uuid_string() -> String {
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF
  if freq < 179 {
    // Normal: ~70% standard format
    gen_uuid().to_string()
  } else if freq < 230 {
    // Edge: ~20% URN format
    gen_uuid().to_urn()
  } else {
    // Boundary: ~10% simple format (no hyphens)
    gen_uuid().to_string_simple()
  }
}

///|
/// Generate test names with distribution control
fn gen_test_name() -> String {
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF
  if freq < 166 {
    // Normal: ~65% typical strings
    let len_bytes = random_bytes(2)
    let len = ((len_bytes[0].to_int() << 8) | len_bytes[1].to_int()) % 50 + 1
    gen_random_string(len)
  } else if freq < 217 {
    // Edge: ~20% special cases
    let special_bytes = random_bytes(1)
    let special = (special_bytes[0].to_int() & 0xFF) % 4
    match special {
      0 => ""
      1 => "测试"
      2 => "🌟"
      _ => "test@example.com"
    }
  } else {
    // Boundary: ~15% long strings
    let len_bytes = random_bytes(2)
    let len = ((len_bytes[0].to_int() << 8) | len_bytes[1].to_int()) % 400 + 100
    gen_random_string(len)
  }
}

///|
/// Generate a random string of given length
fn gen_random_string(len : Int) -> String {
  let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
  let mut result = ""
  for i = 0; i < len; i = i + 1 {
    let idx_bytes = random_bytes(1)
    let idx = (idx_bytes[0].to_int() & 0xFF) % chars.length()
    let c = Int::unsafe_to_char(chars.code_unit_at(idx).to_int())
    result = result + c.to_string()
  }
  result
}

///|
/// Generate a V7 timestamp with distribution control
fn gen_v7_timestamp() -> Int64 {
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF
  if freq < 166 {
    // Normal: ~65% current timestamp ± random offset
    let base = @env.now().reinterpret_as_int64()
    let offset_bytes = random_bytes(4)
    let offset = ((offset_bytes[0].to_int() << 24) |
    (offset_bytes[1].to_int() << 16) |
    (offset_bytes[2].to_int() << 8) |
    offset_bytes[3].to_int()).to_int64()
    // Scale to ±1 day
    let scaled = offset % 172800000 - 86400000
    base + scaled
  } else if freq < 217 {
    // Edge: ~20% zero or small values
    let edge_bytes = random_bytes(1)
    let edge = edge_bytes[0].to_int() & 1
    if edge == 0 {
      0L
    } else {
      ((edge_bytes[0].to_int() & 0xFF) % 1000 + 1).to_int64()
    }
  } else {
    // Boundary: ~15% large values
    let high_bytes = random_bytes(4)
    let high = ((high_bytes[0].to_int() << 24) |
    (high_bytes[1].to_int() << 16) |
    (high_bytes[2].to_int() << 8) |
    high_bytes[3].to_int()).to_int64()
    0xFFFFFFFFFFFFL - high % 1000000
  }
}

///|
/// Generate UUID bytes with distribution control
fn gen_uuid_bytes() -> FixedArray[Byte] {
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF
  if freq < 179 {
    // Normal: ~70% random
    random_bytes(16)
  } else if freq < 217 {
    // Edge: ~15% special patterns
    let special_bytes = random_bytes(1)
    let special = special_bytes[0].to_int() & 1
    if special == 0 {
      FixedArray::make(16, b'\x00')
    } else {
      FixedArray::make(16, b'\xFF')
    }
  } else {
    // Boundary: ~15% patterned (incrementing)
    let result : FixedArray[Byte] = FixedArray::make(16, b'\x00')
    for i = 0; i < 16; i = i + 1 {
      result[i] = i.to_byte()
    }
    result
  }
}

///|
/// Check if variant is RFC 9562 (for testing)
fn variant_is_rfc9562(uuid : Uuid) -> Bool {
  let bytes = uuid.bytes()
  let variant_bits = (bytes[8].to_int() >> 6) & 0x03
  variant_bits == 2
}
