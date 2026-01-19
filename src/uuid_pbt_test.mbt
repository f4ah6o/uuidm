/// Property-Based Testing for UUID library
/// Tests various properties using randomized inputs

///|
/// Generate a random UUID for PBT
fn gen_uuid() -> Uuid {
  v4()
}

///|
/// Generate a random UUID string (hyphenated format)
fn gen_uuid_string() -> String {
  gen_uuid().to_string()
}

///|
/// Generate random bytes for UUID creation
fn gen_uuid_bytes() -> FixedArray[Byte] {
  random_bytes(16)
}

///|
/// Helper: Check if variant is RFC 9562
fn variant_is_rfc9562(uuid : Uuid) -> Bool {
  // RFC 9562 variant has bit pattern 10x at octet 8
  // We can check this by looking at the variant byte
  let bytes = uuid.bytes()
  let variant_bits = (bytes[8].to_int() >> 6) & 0x03
  variant_bits == 2
}

// ============================================================
// Round-Trip Property Tests
// ============================================================

///|
/// Round-Trip: to_string -> from_string should preserve UUID
test "round_trip_string_to_uuid" {
  // Test with multiple random UUIDs
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let str = uuid.to_string()
    match from_string(str) {
      Some(restored) => {
        if restored != uuid {
          abort("Round-trip failed: " + str)
        }
      }
      None => abort("Failed to parse UUID string: " + str)
    }
  }
}

///|
/// Round-Trip: to_urn -> from_urn should preserve UUID
test "round_trip_urn_to_uuid" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let urn = uuid.to_urn()
    match from_urn(urn) {
      Some(restored) => {
        if restored != uuid {
          abort("URN round-trip failed: " + urn)
        }
      }
      None => abort("Failed to parse UUID URN: " + urn)
    }
  }
}

///|
/// Round-Trip: bytes -> from_bytes should preserve UUID
test "round_trip_bytes_to_uuid" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let bytes = uuid.bytes()
    let restored = Uuid::new(bytes)
    if restored != uuid {
      abort("Bytes round-trip failed")
    }
  }
}

// ============================================================
// Idempotent Property Tests
// ============================================================

///|
/// Idempotent: v3 should produce same UUID for same inputs
test "v3_idempotent_same_namespace_name" {
  // Test with various names
  let names = ["test", "example.com", "hello", "world", "测试", "🌟"]
  for name in names {
    let uuid1 = v3(ns_dns, name)
    let uuid2 = v3(ns_dns, name)
    if uuid1 != uuid2 {
      abort("v3 not idempotent for: " + name)
    }
  }
}

///|
/// Idempotent: v5 should produce same UUID for same inputs
test "v5_idempotent_same_namespace_name" {
  let names = ["test", "example.com", "hello", "world", "测试", "🌟"]
  for name in names {
    let uuid1 = v5(ns_dns, name)
    let uuid2 = v5(ns_dns, name)
    if uuid1 != uuid2 {
      abort("v5 not idempotent for: " + name)
    }
  }
}

///|
/// Idempotent: v4 produces valid UUIDs
test "v4_produces_valid_uuids" {
  // Generate multiple UUIDs and verify they are valid
  for i = 0; i < 20; i = i + 1 {
    let uuid = v4()

    // Should have correct version
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '4' {
      abort("v4 UUID does not have version 4")
    }

    // Should have RFC 9562 variant
    if not(variant_is_rfc9562(uuid)) {
      abort("v4 UUID does not have RFC 9562 variant")
    }

    // Should not be nil or max
    if uuid.is_nil() {
      abort("v4 UUID should not be nil")
    }
    if uuid.is_max() {
      abort("v4 UUID should not be max")
    }
  }
}

// ============================================================
// Invariant Property Tests
// ============================================================

///|
/// Invariant: All UUID strings should be 36 characters
test "uuid_string_length_is_36" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let str = uuid.to_string()
    if str.length() != 36 {
      abort("UUID string length is not 36: " + str.to_string())
    }
  }
}

///|
/// Invariant: Hyphens should be at positions 8, 13, 18, 23
test "uuid_hyphens_at_correct_positions" {
  for i = 0; i < 100; i = i + 1 {
    let str = gen_uuid_string()
    // Check hyphen positions
    if Int::unsafe_to_char(str.code_unit_at(8).to_int()) != '-' {
      abort("No hyphen at position 8: " + str)
    }
    if Int::unsafe_to_char(str.code_unit_at(13).to_int()) != '-' {
      abort("No hyphen at position 13: " + str)
    }
    if Int::unsafe_to_char(str.code_unit_at(18).to_int()) != '-' {
      abort("No hyphen at position 18: " + str)
    }
    if Int::unsafe_to_char(str.code_unit_at(23).to_int()) != '-' {
      abort("No hyphen at position 23: " + str)
    }
  }
}

///|
/// Invariant: All generated UUIDs should be RFC 9562 variant
test "uuid_variant_is_rfc9562" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    if not(variant_is_rfc9562(uuid)) {
      abort("UUID variant is not RFC 9562")
    }
  }
}

///|
/// Invariant: v4 UUIDs should have version 4
test "v4_uuid_version_is_4" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = v4()
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '4' {
      abort("v4 UUID does not have version 4")
    }
  }
}

///|
/// Invariant: v3 UUIDs should have version 3
test "v3_uuid_version_is_3" {
  let names = ["test", "example.com", "hello", "世界"]
  for name in names {
    let uuid = v3(ns_dns, name)
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '3' {
      abort("v3 UUID does not have version 3 for: " + name)
    }
  }
}

///|
/// Invariant: v5 UUIDs should have version 5
test "v5_uuid_version_is_5" {
  let names = ["test", "example.com", "hello", "世界"]
  for name in names {
    let uuid = v5(ns_dns, name)
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '5' {
      abort("v5 UUID does not have version 5 for: " + name)
    }
  }
}

///|
/// Invariant: v7 UUIDs should have version 7
test "v7_uuid_version_is_7" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = v7()
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '7' {
      abort("v7 UUID does not have version 7")
    }
  }
}

///|
/// Invariant: v8 UUIDs should have version 8
test "v8_uuid_version_is_8" {
  for i = 0; i < 10; i = i + 1 {
    let bytes = gen_uuid_bytes()
    let uuid = v8(bytes)
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '8' {
      abort("v8 UUID does not have version 8")
    }
  }
}

///|
/// Invariant: All UUIDs should be 128 bits (16 bytes)
test "uuid_is_16_bytes" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let bytes = uuid.bytes()
    if bytes.length() != 16 {
      abort("UUID is not 16 bytes")
    }
  }
}

// ============================================================
// V7 Specific Property Tests
// ============================================================

///|
/// V7 Property: Timestamp should be extractable from v7 UUIDs
test "v7_timestamp_is_extractable" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = v7()
    match extract_timestamp(uuid) {
      Some(ts) => {
        // Timestamp should be positive (or at least not error)
        if ts < 0L {
          abort("V7 timestamp is negative")
        }
      }
      None => abort("V7 UUID should have extractable timestamp")
    }
  }
}

///|
/// V7 Property: v7_sequence should produce monotonically increasing timestamps
test "v7_sequence_is_monotonic" {
  let count = 50
  let uuids = v7_sequence(count)

  // Extract timestamps and verify they're monotonically increasing
  let mut prev_ts : Int64? = None
  for uuid in uuids {
    match extract_timestamp(uuid) {
      Some(ts) => {
        match prev_ts {
          Some(prev) => {
            if ts < prev {
              abort("V7 sequence is not monotonic")
            }
          }
          None => ()
        }
        prev_ts = Some(ts)
      }
      None => abort("V7 UUID should have extractable timestamp")
    }
  }
}

///|
/// V7 Property: v7_with_timestamp should preserve timestamp
test "v7_with_timestamp_preserves_timestamp" {
  let test_timestamps = [0L, 1L, 1000L, 123456789L, 0xFFFFFFFFFFFFL]

  for ts in test_timestamps {
    let uuid = v7_with_timestamp(ts)
    match extract_timestamp(uuid) {
      Some(extracted) => {
        if extracted != ts {
          abort("V7 timestamp not preserved: expected " + ts.to_string() + ", got " + extracted.to_string())
        }
      }
      None => abort("V7 UUID should have extractable timestamp")
    }
  }
}

///|
/// V3 Property: Different names should produce different v3 UUIDs
test "v3_different_names_different_uuids" {
  let name1 = "test1"
  let name2 = "test2"

  let uuid1 = v3(ns_dns, name1)
  let uuid2 = v3(ns_dns, name2)

  if uuid1 == uuid2 {
    abort("Different names should produce different v3 UUIDs")
  }
}

///|
/// V5 Property: Different names should produce different v5 UUIDs
test "v5_different_names_different_uuids" {
  let name1 = "test1"
  let name2 = "test2"

  let uuid1 = v5(ns_dns, name1)
  let uuid2 = v5(ns_dns, name2)

  if uuid1 == uuid2 {
    abort("Different names should produce different v5 UUIDs")
  }
}

///|
/// Property: Different namespaces should produce different UUIDs
test "different_namespaces_different_uuids" {
  let name = "test.example"
  let dns_uuid = v3(ns_dns, name)
  let url_uuid = v3(ns_url, name)
  let oid_uuid = v3(ns_oid, name)
  let x500_uuid = v3(ns_x500, name)

  if dns_uuid == url_uuid {
    abort("Different namespaces should produce different UUIDs")
  }
  if dns_uuid == oid_uuid {
    abort("Different namespaces should produce different UUIDs")
  }
  if dns_uuid == x500_uuid {
    abort("Different namespaces should produce different UUIDs")
  }
}

// ============================================================
// Edge Case Tests
// ============================================================

///|
/// Edge case: nil UUID has expected properties
test "nil_uuid_properties" {
  let nil_uuid = nil()

  if not(nil_uuid.is_nil()) {
    abort("nil UUID should be nil")
  }

  if nil_uuid.to_string() != "00000000-0000-0000-0000-000000000000" {
    abort("nil UUID string is incorrect")
  }

  // Nil UUID has all zeros, so variant is NCS (0b0xx)
  let bytes = nil_uuid.bytes()
  let variant_bits = (bytes[8].to_int() >> 6) & 0x03
  if variant_bits != 0 {
    abort("nil UUID should have NCS variant")
  }
}

///|
/// Edge case: max UUID has expected properties
test "max_uuid_properties" {
  let max_uuid = max()

  if not(max_uuid.is_max()) {
    abort("max UUID should be max")
  }

  if max_uuid.to_string() != "ffffffff-ffff-ffff-ffff-ffffffffffff" {
    abort("max UUID string is incorrect")
  }
}

///|
/// Edge case: Empty string with v3 should still produce valid UUID
test "v3_empty_string_valid" {
  let uuid = v3(ns_dns, "")

  // Should have correct version and variant
  let uuid_str = uuid.to_string()
  let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
  if version_char != '3' {
    abort("v3 with empty string should have version 3")
  }

  if not(variant_is_rfc9562(uuid)) {
    abort("v3 UUID should have RFC 9562 variant")
  }
}

///|
/// Edge case: to_string_simple produces 32 hex characters
test "to_string_simple_length" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let str = uuid.to_string_simple()
    if str.length() != 32 {
      abort("to_string_simple should produce 32 characters, got: " + str.length().to_string())
    }
  }
}

///|
/// Edge case: v8_counter produces deterministic results
test "v8_counter_deterministic" {
  let counter = 12345L
  let node_id = 1
  let app_id = 42

  let uuid1 = v8_counter(counter, node_id, app_id)
  let uuid2 = v8_counter(counter, node_id, app_id)

  if uuid1 != uuid2 {
    abort("v8_counter should be deterministic for same inputs")
  }
}

///|
/// Edge case: v8_mixed produces valid v8 UUIDs
test "v8_mixed_valid_v8" {
  let timestamp = 123456789L
  let custom = 999

  let uuid = v8_mixed(timestamp, custom)

  let uuid_str = uuid.to_string()
  let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
  if version_char != '8' {
    abort("v8_mixed should produce version 8 UUID")
  }

  if not(variant_is_rfc9562(uuid)) {
    abort("v8_mixed should produce RFC 9562 variant")
  }
}

///|
/// Property: v3 and v5 should produce different UUIDs for same input
test "v3_v5_different_for_same_input" {
  let name = "example.com"
  let v3_uuid = v3(ns_dns, name)
  let v5_uuid = v5(ns_dns, name)

  if v3_uuid == v5_uuid {
    abort("v3 and v5 should produce different UUIDs for same input")
  }
}

///|
/// Property: UUID string contains only valid hex characters and hyphens
test "uuid_string_valid_characters" {
  for i = 0; i < 100; i = i + 1 {
    let uuid_str = gen_uuid_string()
    for j = 0; j < uuid_str.length(); j = j + 1 {
      let c = Int::unsafe_to_char(uuid_str.code_unit_at(j).to_int())
      let is_hyphen = c == '-'
      let is_hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')
      if not(is_hyphen || is_hex) {
        abort("UUID string contains invalid character: " + c.to_string())
      }
    }
  }
}

///|
/// Property: Version character is always at position 14
test "version_character_at_position_14" {
  // Test v3
  let uuid_v3 = v3(ns_dns, "test")
  let uuid_str_v3 = uuid_v3.to_string()
  let version_char_v3 = Int::unsafe_to_char(uuid_str_v3.code_unit_at(14).to_int())
  if version_char_v3 != '3' {
    abort("Version character mismatch for v3")
  }

  // Test v4
  let uuid_v4 = v4()
  let uuid_str_v4 = uuid_v4.to_string()
  let version_char_v4 = Int::unsafe_to_char(uuid_str_v4.code_unit_at(14).to_int())
  if version_char_v4 != '4' {
    abort("Version character mismatch for v4")
  }

  // Test v5
  let uuid_v5 = v5(ns_dns, "test")
  let uuid_str_v5 = uuid_v5.to_string()
  let version_char_v5 = Int::unsafe_to_char(uuid_str_v5.code_unit_at(14).to_int())
  if version_char_v5 != '5' {
    abort("Version character mismatch for v5")
  }

  // Test v7
  let uuid_v7 = v7()
  let uuid_str_v7 = uuid_v7.to_string()
  let version_char_v7 = Int::unsafe_to_char(uuid_str_v7.code_unit_at(14).to_int())
  if version_char_v7 != '7' {
    abort("Version character mismatch for v7")
  }

  // Test v8
  let uuid_v8 = v8(gen_uuid_bytes())
  let uuid_str_v8 = uuid_v8.to_string()
  let version_char_v8 = Int::unsafe_to_char(uuid_str_v8.code_unit_at(14).to_int())
  if version_char_v8 != '8' {
    abort("Version character mismatch for v8")
  }
}

///|
/// Property: UUID bytes are reversible
test "uuid_bytes_reversible" {
  for i = 0; i < 100; i = i + 1 {
    let uuid1 = gen_uuid()
    let bytes = uuid1.bytes()

    // Create new UUID from bytes
    let uuid2 = Uuid::new(bytes)

    // Should be identical
    if uuid1 != uuid2 {
      abort("UUID bytes are not reversible")
    }

    // String representations should also match
    if uuid1.to_string() != uuid2.to_string() {
      abort("UUID string representations don't match after byte round-trip")
    }
  }
}

///|
/// Property: URN format is correct
test "urn_format_is_correct" {
  for i = 0; i < 100; i = i + 1 {
    let uuid = gen_uuid()
    let urn = uuid.to_urn()

    // Should start with "urn:uuid:"
    if not(urn.has_prefix("urn:uuid:")) {
      abort("URN does not start with 'urn:uuid:': " + urn)
    }

    // Should be 45 characters total (9 + 36)
    if urn.length() != 45 {
      abort("URN length is incorrect: " + urn.length().to_string())
    }

    // Extract UUID part and verify it matches original
    let uuid_part = urn[9:].to_string() catch { _ => abort("URN substring failed") }
    if uuid_part != uuid.to_string() {
      abort("URN UUID part does not match original UUID")
    }
  }
}

///|
/// Property: v4 UUIDs have proper format and content
test "v4_uuids_are_well_formed" {
  // Generate multiple UUIDs and check they have proper format
  for i = 0; i < 50; i = i + 1 {
    let uuid = v4()
    let uuid_str = uuid.to_string()

    // Check length
    if uuid_str.length() != 36 {
      abort("v4 UUID string length is not 36")
    }

    // Check hyphen positions
    if Int::unsafe_to_char(uuid_str.code_unit_at(8).to_int()) != '-' {
      abort("v4 UUID missing hyphen at position 8")
    }
    if Int::unsafe_to_char(uuid_str.code_unit_at(13).to_int()) != '-' {
      abort("v4 UUID missing hyphen at position 13")
    }
    if Int::unsafe_to_char(uuid_str.code_unit_at(18).to_int()) != '-' {
      abort("v4 UUID missing hyphen at position 18")
    }
    if Int::unsafe_to_char(uuid_str.code_unit_at(23).to_int()) != '-' {
      abort("v4 UUID missing hyphen at position 23")
    }

    // Check version is 4
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char != '4' {
      abort("v4 UUID does not have version 4")
    }

    // Check variant is RFC 9562
    if not(variant_is_rfc9562(uuid)) {
      abort("v4 UUID does not have RFC 9562 variant")
    }
  }
}

// ============================================================
// Statistical Property-Based Tests (with coverage tracking)
// ============================================================
// These tests track statistics on input distribution to ensure
// good coverage of edge cases, boundary values, and normal cases.

///|
/// Statistical PBT: Round-trip with coverage tracking
test "stat_round_trip_string_with_coverage" {
  let mut nil_count = 0
  let mut max_count = 0
  let mut normal_count = 0

  // Include edge cases in the distribution
  let test_uuids = [
    nil(),  // Edge: nil
    max(),  // Edge: max
    v4(), v4(), v4(), v4(),  // Normal: v4
    v7(), v7(), v7(), v7(),  // Normal: v7
  ]

  for uuid in test_uuids {
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
  inspect(nil_count == 1, content="true")
  inspect(max_count == 1, content="true")
  inspect(normal_count >= 8, content="true")
}

///|
/// Statistical PBT: UUID string length with coverage
test "stat_uuid_string_length_with_coverage" {
  let mut nil_count = 0
  let mut max_count = 0
  let mut v4_count = 0
  let mut v7_count = 0

  let test_uuids = [
    nil(), max(), v4(), v4(), v4(), v7(), v7(), v7(),
  ]

  for uuid in test_uuids {
    if uuid.is_nil() { nil_count = nil_count + 1 }
    if uuid.is_max() { max_count = max_count + 1 }

    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    if version_char == '4' { v4_count = v4_count + 1 }
    if version_char == '7' { v7_count = v7_count + 1 }

    assert_eq(uuid_str.length(), 36)
  }

  inspect(nil_count > 0, content="true")
  inspect(max_count > 0, content="true")
  inspect(v4_count >= 3, content="true")
  inspect(v7_count >= 3, content="true")
}

///|
/// Statistical PBT: Version distribution tracking
test "stat_version_distribution" {
  let mut v3_count = 0
  let mut v4_count = 0
  let mut v5_count = 0
  let mut v7_count = 0
  let mut v8_count = 0

  // Test different versions
  let uuids = [
    v3(ns_dns, "test"),  // v3
    v4(), v4(), v4(),    // v4 (multiple)
    v5(ns_dns, "test"),  // v5
    v7(), v7(), v7(),    // v7 (multiple)
    v8(random_bytes(16)), // v8
  ]

  for uuid in uuids {
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())

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

///|
/// Statistical PBT: Name-based UUID diversity
test "stat_name_based_uuid_diversity" {
  let mut empty_count = 0
  let mut unicode_count = 0
  let mut normal_count = 0

  let test_names = [
    "",           // Edge: empty
    "测试",        // Edge: Unicode
    "🌟test",      // Edge: emoji + ASCII
    "test",       // Normal
    "example.com", // Normal
  ]

  for name in test_names {
    if name == "" { empty_count = empty_count + 1 }
    // Check for Unicode by looking for characters outside ASCII range
    let has_unicode = name.length() > 0 && (
      Int::unsafe_to_char(name.code_unit_at(0).to_int()) > '\u{007F}' ||
      (name.length() > 1 && Int::unsafe_to_char(name.code_unit_at(1).to_int()) > '\u{007F}')
    )
    if has_unicode { unicode_count = unicode_count + 1 }
    if name.length() >= 4 && name != "" { normal_count = normal_count + 1 }

    // Test v3
    let v3_uuid = v3(ns_dns, name)
    let v3_str = v3_uuid.to_string()
    let v3_char = Int::unsafe_to_char(v3_str.code_unit_at(14).to_int())
    assert_eq(v3_char, '3')

    // Test v5
    let v5_uuid = v5(ns_dns, name)
    let v5_str = v5_uuid.to_string()
    let v5_char = Int::unsafe_to_char(v5_str.code_unit_at(14).to_int())
    assert_eq(v5_char, '5')

    // Different algorithms should produce different UUIDs
    assert_true(v3_uuid != v5_uuid, msg="v3 and v5 should differ")
  }

  inspect(empty_count >= 1, content="true")
  inspect(unicode_count >= 2, content="true")
  inspect(normal_count >= 3, content="true")
}

///|
/// Statistical PBT: V7 timestamp range coverage
test "stat_v7_timestamp_coverage" {
  let mut zero_ts = 0
  let mut small_ts = 0
  let mut large_ts = 0

  let test_timestamps = [
    0L,             // Edge: zero
    1L,             // Edge: minimal positive
    1000L,          // Small
    123456789L,     // Medium
    0xFFFFFFFFFFFFL // Edge: max 48-bit
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

    // Verify version is 7
    let uuid_str = uuid.to_string()
    let version_char = Int::unsafe_to_char(uuid_str.code_unit_at(14).to_int())
    assert_eq(version_char, '7')
  }

  inspect(zero_ts >= 1, content="true")
  inspect(small_ts >= 2, content="true")
  inspect(large_ts >= 2, content="true")
}

///|
/// Statistical PBT: Bytes reversibility with edge cases
test "stat_bytes_reversibility_coverage" {
  let mut zero_count = 0
  let mut max_count = 0
  let mut pattern_count = 0

  // Test various byte patterns
  let zero_bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  let max_bytes : FixedArray[Byte] = FixedArray::make(16, b'\xFF')
  let pattern_bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    pattern_bytes[i] = i.to_byte()
  }

  let byte_arrays = [zero_bytes, max_bytes, pattern_bytes, random_bytes(16)]

  for bytes in byte_arrays {
    if bytes[0] == b'\x00' && bytes[1] == b'\x00' { zero_count = zero_count + 1 }
    if bytes[0] == b'\xFF' && bytes[1] == b'\xFF' { max_count = max_count + 1 }
    if bytes[0] != b'\x00' && bytes[0] != b'\xFF' { pattern_count = pattern_count + 1 }

    let uuid1 = Uuid::new(bytes)
    let bytes2 = uuid1.bytes()
    let uuid2 = Uuid::new(bytes2)

    assert_eq(uuid1, uuid2)
  }

  inspect(zero_count >= 1, content="true")
  inspect(max_count >= 1, content="true")
}
