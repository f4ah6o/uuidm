# Property-Based Tests for uuidm

This document contains Property-Based Tests (PBT) for the uuidm library with statistical coverage tracking.

## Custom Generators

The following generators provide controlled distribution for testing:
- **Normal (60-70%)**: Typical cases
- **Edge (15-20%)**: Boundary values (nil, max, empty strings)
- **Boundary (10-15%)**: Edge cases

```mbt
/// Generate a random UUID with distribution control
fn pbt_gen_uuid() -> Uuid {
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF

  if freq < 165 {
    // Normal: ~65% random v4
    v4()
  } else if freq < 216 {
    // Edge: ~20% special cases (nil, max)
    let special_bytes = random_bytes(1)
    if (special_bytes[0].to_int() & 1) == 0 { nil() } else { max() }
  } else {
    // Boundary: ~15% custom bytes
    let custom = random_bytes(16)
    v8(custom)
  }
}

/// Generate test names with distribution control
fn pbt_gen_test_name() -> String {
  let bytes = random_bytes(1)
  let freq = bytes[0].to_int() & 0xFF

  if freq < 166 {
    // Normal: ~65% typical strings
    let len_bytes = random_bytes(2)
    let len = ((len_bytes[0].to_int() << 8) | len_bytes[1].to_int()) % 50 + 1
    pbt_gen_random_string(len)
  } else if freq < 217 {
    // Edge: ~20% special cases
    let special_bytes = random_bytes(1)
    let special = (special_bytes[0].to_int() & 0xFF) % 4
    match special {
      0 => ""
      1 => "测试"
      2 => "test@example.com"
      _ => "hello-world"
    }
  } else {
    // Boundary: ~15% long strings
    let len_bytes = random_bytes(2)
    let len = ((len_bytes[0].to_int() << 8) | len_bytes[1].to_int()) % 400 + 100
    pbt_gen_random_string(len)
  }
}

/// Generate a random string of given length
fn pbt_gen_random_string(len : Int) -> String {
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

/// Check if variant is RFC 9562
fn variant_is_rfc9562(uuid : Uuid) -> Bool {
  let bytes = uuid.bytes()
  let variant_bits = (bytes[8].to_int() >> 6) & 0x03
  variant_bits == 2
}

/// Extract version character from UUID string
fn get_version_char(uuid_str : String) -> Char {
  Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
}
```

## Statistical Property-Based Tests

### Round-Trip Tests with Coverage Tracking

```mbt
test "pbt_round_trip_string_with_coverage" {
  let mut nil_count = 0
  let mut max_count = 0
  let mut normal_count = 0

  // Test with controlled distribution
  for i = 0; i < 200; i = i + 1 {
    let uuid = pbt_gen_uuid()

    if uuid.is_nil() { nil_count = nil_count + 1 }
    if uuid.is_max() { max_count = max_count + 1 }
    if not(uuid.is_nil()) && not(uuid.is_max()) { normal_count = normal_count + 1 }

    let str = uuid.to_string()
    match from_string(str) {
      Some(restored) => assert_eq(restored, uuid)
      None => abort("Failed to parse: " + str)
    }
  }

  // Verify edge case coverage
  inspect(nil_count > 0, content="true")
  inspect(max_count > 0, content="true")
  inspect(normal_count > 100, content="true")
}
```

### URN Round-Trip with Coverage

```mbt
test "pbt_round_trip_urn_with_coverage" {
  let mut nil_count = 0
  let mut max_count = 0

  for i = 0; i < 200; i = i + 1 {
    let uuid = pbt_gen_uuid()

    if uuid.is_nil() { nil_count = nil_count + 1 }
    if uuid.is_max() { max_count = max_count + 1 }

    let urn = uuid.to_urn()
    match from_urn(urn) {
      Some(restored) => assert_eq(restored, uuid)
      None => abort("Failed to parse URN: " + urn)
    }
  }

  inspect(nil_count > 0, content="true")
  inspect(max_count > 0, content="true")
}
```

### UUID String Length Coverage

```mbt
test "pbt_uuid_string_length_coverage" {
  let mut nil_count = 0
  let mut max_count = 0
  let mut v4_count = 0

  for i = 0; i < 200; i = i + 1 {
    let uuid = pbt_gen_uuid()

    if uuid.is_nil() { nil_count = nil_count + 1 }
    if uuid.is_max() { max_count = max_count + 1 }

    let uuid_str = uuid.to_string()
    if get_version_char(uuid_str) == '4' { v4_count = v4_count + 1 }

    let str = uuid.to_string()
    assert_eq(str.length(), 36)
  }

  inspect(nil_count > 0, content="true")
  inspect(max_count > 0, content="true")
  inspect(v4_count > 50, content="true")
}
```

### Version Distribution Tracking

```mbt
test "pbt_version_distribution" {
  let mut v3_count = 0
  let mut v4_count = 0
  let mut v5_count = 0
  let mut v7_count = 0
  let mut v8_count = 0

  // Test different versions
  let uuids = [
    v3(ns_dns, "test"),
    v4(), v4(), v4(),
    v5(ns_dns, "test"),
    v7(), v7(), v7(),
    v8(random_bytes(16)),
  ]

  for uuid in uuids {
    let uuid_str = uuid.to_string()
    let version_char = get_version_char(uuid_str)

    match version_char {
      '3' => v3_count = v3_count + 1
      '4' => v4_count = v4_count + 1
      '5' => v5_count = v5_count + 1
      '7' => v7_count = v7_count + 1
      '8' => v8_count = v8_count + 1
      _ => ()
    }

    assert_true(variant_is_rfc9562(uuid), msg="UUID should have RFC 9562 variant")
  }

  inspect(v3_count >= 1, content="true")
  inspect(v4_count >= 3, content="true")
  inspect(v5_count >= 1, content="true")
  inspect(v7_count >= 3, content="true")
  inspect(v8_count >= 1, content="true")
}
```

### Name-Based UUID Diversity

```mbt
test "pbt_name_based_uuid_diversity" {
  let mut empty_count = 0
  let mut unicode_count = 0
  let mut normal_count = 0

  let test_names = [
    "",
    "测试",
    "test",
    "example.com",
  ]

  for name in test_names {
    if name == "" { empty_count = empty_count + 1 }
    let has_unicode = name.length() > 0 && Int::unsafe_to_char(name.code_unit_at(0).to_int()) > '\u{007F}'
    if has_unicode { unicode_count = unicode_count + 1 }
    if name.length() >= 4 && name != "" { normal_count = normal_count + 1 }

    let v3_uuid = v3(ns_dns, name)
    let v5_uuid = v5(ns_dns, name)

    assert_true(v3_uuid != v5_uuid, msg="v3 and v5 should differ")
  }

  inspect(empty_count >= 1, content="true")
  inspect(unicode_count >= 1, content="true")
  inspect(normal_count >= 2, content="true")
}
```

### V7 Timestamp Coverage

```mbt
test "pbt_v7_timestamp_coverage" {
  let mut zero_ts = 0
  let mut small_ts = 0
  let mut large_ts = 0

  let test_timestamps = [
    0L,
    1L,
    1000L,
    123456789L,
    0xFFFFFFFFFFFFL
  ]

  for ts in test_timestamps {
    if ts == 0L { zero_ts = zero_ts + 1 }
    if ts > 0L && ts < 10000L { small_ts = small_ts + 1 }
    if ts > 100000L { large_ts = large_ts + 1 }

    let uuid = v7_with_timestamp(ts)
    match extract_timestamp(uuid) {
      Some(extracted) => assert_eq(extracted, ts)
      None => abort("V7 UUID should have extractable timestamp")
    }

    let uuid_str = uuid.to_string()
    let version_char = get_version_char(uuid_str)
    assert_eq(version_char, '7')
  }

  inspect(zero_ts >= 1, content="true")
  inspect(small_ts >= 2, content="true")
  inspect(large_ts >= 2, content="true")
}
```

### Bytes Reversibility Coverage

```mbt
test "pbt_bytes_reversibility_coverage" {
  let mut zero_count = 0
  let mut max_count = 0

  let zero_bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  let max_bytes : FixedArray[Byte] = FixedArray::make(16, b'\xFF')

  let byte_arrays = [zero_bytes, max_bytes, random_bytes(16)]

  for bytes in byte_arrays {
    if bytes[0] == b'\x00' && bytes[1] == b'\x00' { zero_count = zero_count + 1 }
    if bytes[0] == b'\xFF' && bytes[1] == b'\xFF' { max_count = max_count + 1 }

    let uuid1 = Uuid::new(bytes)
    let bytes2 = uuid1.bytes()
    let uuid2 = Uuid::new(bytes2)

    assert_eq(uuid1, uuid2)
  }

  inspect(zero_count >= 1, content="true")
  inspect(max_count >= 1, content="true")
}
```

### UUID String Valid Characters

```mbt
test "pbt_uuid_string_valid_characters" {
  let mut nil_count = 0
  let mut max_count = 0

  for i = 0; i < 200; i = i + 1 {
    let uuid = pbt_gen_uuid()

    if uuid.is_nil() { nil_count = nil_count + 1 }
    if uuid.is_max() { max_count = max_count + 1 }

    let uuid_str = uuid.to_string()
    for j = 0; j < uuid_str.length(); j = j + 1 {
      let c = Int::unsafe_to_char(uuid_str.code_unit_at(j).to_int())
      let is_hyphen = c == '-'
      let is_hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')
      assert_true(is_hyphen || is_hex, msg="Invalid character")
    }
  }

  inspect(nil_count > 0, content="true")
  inspect(max_count > 0, content="true")
}
```

### V4 UUIDs Well-Formed

```mbt
test "pbt_v4_uuids_well_formed" {
  let mut rfc9562_count = 0

  for i = 0; i < 100; i = i + 1 {
    let uuid = v4()
    let uuid_str = uuid.to_string()

    if variant_is_rfc9562(uuid) { rfc9562_count = rfc9562_count + 1 }

    assert_eq(uuid_str.length(), 36)

    let check_hyphen = fn(pos : Int) -> Bool {
      Int::unsafe_to_char(uuid_str.code_unit_at(pos).to_int()) == '-'
    }
    assert_true(check_hyphen(8))
    assert_true(check_hyphen(13))
    assert_true(check_hyphen(18))
    assert_true(check_hyphen(23))

    let version_char = get_version_char(uuid_str)
    assert_eq(version_char, '4')
    assert_true(variant_is_rfc9562(uuid))
  }

  inspect(rfc9562_count == 100, content="true")
}
```
