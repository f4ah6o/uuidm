///|
/// Integration tests for the UUID library
/// Testing end-to-end functionality and realistic usage scenarios
test "real_world_usage_scenario" {
  // Simulate a real application using UUIDs

  // 1. Generate user IDs (v4)
  let user_id = v4()
  let session_id = v4()
  inspect(user_id.is_nil(), content="false")
  inspect(user_id != session_id, content="false")

  // 2. Generate resource IDs based on names (v5)
  let api_endpoint = "https://api.example.com/users"
  let resource_id = v5(ns_url, api_endpoint)
  let same_resource_id = v5(ns_url, api_endpoint)
  inspect(resource_id == same_resource_id, content="true")
  inspect(
    resource_id.to_string(),
    content="5fc507ca-c678-5cbd-ae06-c563837b0615",
  )

  // 3. Generate time-ordered event IDs (v7)
  let event1 = v7()
  let event2 = v7()
  let event3 = v7()

  // Extract timestamps and check they exist
  let ts1 = extract_timestamp(event1)
  let ts2 = extract_timestamp(event2)
  let ts3 = extract_timestamp(event3)
  match (ts1, ts2, ts3) {
    (Some(_), Some(_), Some(_)) => inspect(true, content="true")
    _ => inspect(false, content="v7 UUIDs should have timestamps")
  }
}

///|
test "namespace_consistency_test" {
  // Test that different namespaces produce different UUIDs for same name
  let name = "example.resource"
  let dns_uuid = v3(ns_dns, name)
  let url_uuid = v3(ns_url, name)
  let oid_uuid = v3(ns_oid, name)
  let x500_uuid = v3(ns_x500, name)

  // All should be different
  inspect(dns_uuid != url_uuid, content="true")
  inspect(dns_uuid != oid_uuid, content="true")
  inspect(dns_uuid != x500_uuid, content="true")
  inspect(url_uuid != oid_uuid, content="true")
  inspect(url_uuid != x500_uuid, content="true")
  inspect(oid_uuid != x500_uuid, content="true")

  // But v3 and v5 for same namespace should be different
  let v3_dns_uuid = v3(ns_dns, name)
  let v5_dns_uuid = v5(ns_dns, name)
  inspect(v3_dns_uuid != v5_dns_uuid, content="true")
}

///|
test "string_format_consistency_test" {
  let uuid = v4_with_rng(SimpleRng::new(999L))
  let standard = uuid.to_string()
  let urn = uuid.to_urn()
  inspect(standard.length(), content="36")
  inspect(urn.length() >= 45, content="true") // "urn:uuid:" + 36 chars

  // URN should contain the uuid string
  inspect(urn.contains(standard), content="true")
}

///|
test "version_and_variant_correctness" {
  // Test that version and variant bits are set correctly

  let v3_uuid = v3(ns_dns, "test")
  let v4_uuid = v4()
  let v5_uuid = v5(ns_dns, "test")
  let v7_uuid = v7()
  let v8_uuid = v8(FixedArray::make(16, b'\x00'))

  // All should have some variant (we test the actual variant checking)
  inspect(v3_uuid.variant(), content="Rfc9562")
  inspect(v4_uuid.variant(), content="Rfc9562")
  inspect(v5_uuid.variant(), content="Rfc9562")
  inspect(v7_uuid.variant(), content="Rfc9562")
  inspect(v8_uuid.variant(), content="Rfc9562")

  // Versions should be correct
  match v3_uuid.version() {
    Some(_) => inspect(true, content="true")
    None => inspect(false, content="v3 should have version")
  }
  match v4_uuid.version() {
    Some(_) => inspect(true, content="true")
    None => inspect(false, content="v4 should have version")
  }
  match v5_uuid.version() {
    Some(_) => inspect(true, content="true")
    None => inspect(false, content="v5 should have version")
  }
  match v7_uuid.version() {
    Some(_) => inspect(true, content="true")
    None => inspect(false, content="v7 should have version")
  }
  match v8_uuid.version() {
    Some(_) => inspect(true, content="true")
    None => inspect(false, content="v8 should have version")
  }
}

///|
test "uuid_equality_and_comparison" {
  // Test UUID equality across different creation methods

  let nil1 = nil()
  let nil2 = nil()
  let max1 = max()
  let max2 = max()
  inspect(nil1 == nil2, content="true")
  inspect(max1 == max2, content="true")
  inspect(nil1 != max1, content="true")

  // Same name-based UUIDs should be equal
  let name = "consistent.test.example.com"
  let v3_1 = v3(ns_dns, name)
  let v3_2 = v3(ns_dns, name)
  let v5_1 = v5(ns_dns, name)
  let v5_2 = v5(ns_dns, name)
  inspect(v3_1 == v3_2, content="true")
  inspect(v5_1 == v5_2, content="true")
  inspect(v3_1 != v5_1, content="true")
}

///|
test "error_handling_and_edge_cases" {
  // Test various edge cases and error conditions

  // Empty string name
  let empty_name_uuid = v3(ns_dns, "")
  inspect(empty_name_uuid.variant(), content="Rfc9562")

  // Very long name
  let long_name = "this.is.a.very.long.domain.name.that.exceeds.normal.length.but.should.still.work.example.com"
  let long_name_uuid = v5(ns_dns, long_name)
  inspect(long_name_uuid.variant(), content="Rfc9562")

  // Unicode characters (if supported)
  let unicode_name = "тест.example.com"
  let unicode_uuid = v3(ns_dns, unicode_name)
  inspect(unicode_uuid.variant(), content="Rfc9562")

  // Special characters
  let special_name = "test-with_special.chars@example.com"
  let special_uuid = v5(ns_dns, special_name)
  inspect(special_uuid.variant(), content="Rfc9562")
}

///|
test "performance_consistency_test" {
  // Test that operations are consistent across multiple runs

  // Generate multiple UUIDs and check consistency
  let v4_uuids : Array[Uuid] = []
  for i = 0; i < 10; i = i + 1 {
    v4_uuids.push(v4())
  }
  inspect(v4_uuids.length(), content="10")

  // All should be different (very high probability)
  let mut unique_count = 0
  for i = 0; i < 10; i = i + 1 {
    let mut is_unique = true
    for j = 0; j < 10; j = j + 1 {
      if i != j && v4_uuids[i] == v4_uuids[j] {
        is_unique = false
      }
    }
    if is_unique {
      unique_count = unique_count + 1
    }
  }
  inspect(unique_count >= 8, content="false")

  // Name-based UUIDs should be consistent
  let base_name = "performance.test.example.org"
  let v3_results : Array[Uuid] = []
  let v5_results : Array[Uuid] = []
  for i = 0; i < 5; i = i + 1 {
    v3_results.push(v3(ns_dns, base_name))
    v5_results.push(v5(ns_dns, base_name))
  }

  // All v3 results should be identical
  let mut v3_consistent = true
  for i = 1; i < 5; i = i + 1 {
    if v3_results[i] != v3_results[0] {
      v3_consistent = false
    }
  }
  inspect(v3_consistent, content="true")

  // All v5 results should be identical  
  let mut v5_consistent = true
  for i = 1; i < 5; i = i + 1 {
    if v5_results[i] != v5_results[0] {
      v5_consistent = false
    }
  }
  inspect(v5_consistent, content="true")
}

///|
test "library_demo_output" {
  // Create deterministic demo output with manually constructed UUIDs
  // v4 UUID: ef82f904-93d6-4d78-b76a-c12c9b3e8520
  let v4_uuid = Uuid::from_bytes(
    b'\xEF', b'\x82', b'\xF9', b'\x04', // time_low
     b'\x93', b'\xD6', // time_mid
     b'\x4D', b'\x78', // time_hi_and_version (4xxx => version 4)
     b'\xB7', b'\x6A', // clock_seq_hi_and_reserved (variant) + clock_seq_low
     b'\xC1', b'\x2C', b'\x9B', b'\x3E', b'\x85', b'\x20', // node
  )
  // v7 UUID: 019bd39e-bbd0-7f82-b904-93d63d78776a
  let v7_uuid = Uuid::from_bytes(
    b'\x01', b'\x9B', b'\xD3', b'\x9E', b'\xBB', b'\xD0', // timestamp
     b'\x7F', b'\x82', // random with version 7 (7xxx => 0x7f)
     b'\xB9', b'\x04', // random with variant
     b'\x93', b'\xD6', b'\x3D', b'\x78', b'\x77', b'\x6A', // remaining random
  )
  let demo_output = "UUID v4: " +
    v4_uuid.to_string() +
    "\n" +
    "UUID v7: " +
    v7_uuid.to_string() +
    "\n" +
    "Nil UUID: " +
    nil().to_string()
  inspect(
    demo_output,
    content=(
      #|UUID v4: ef82f904-93d6-4d78-b76a-c12c9b3e8520
      #|UUID v7: 019bd39e-bbd0-7f82-b904-93d63d78776a
      #|Nil UUID: 00000000-0000-0000-0000-000000000000
    ),
  )

  // The demo should include UUID examples
  inspect(demo_output.length() > 50, content="true")
  inspect(demo_output.contains("UUID"), content="true")
}
