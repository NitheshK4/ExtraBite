import 'package:supabase_flutter/supabase_flutter.dart';

class PgProfileRepository {
  final SupabaseClient? _client;

  PgProfileRepository(SupabaseClient client) : _client = client;

  /// Named constructor for tests without SupabaseClient.
  PgProfileRepository.fakeForTest() : _client = null;

  /// Fetch a PG profile by owner's user ID.
  Future<Map<String, dynamic>?> fetchOwnerPg(String ownerId) async {
    if (_client == null) return null;
    try {
      final response = await _client
          .from('pg_profiles')
          .select()
          .eq('owner_id', ownerId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Create or update a PG profile.
  /// Sets is_approved to false by default (pending admin review).
  Future<Map<String, dynamic>> submitPgProfile({
    required String ownerId,
    required String pgName,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? description,
    String? imageUrl,
  }) async {
    final rowData = {
      'owner_id': ownerId,
      'pg_name': pgName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': 'Vijayawada',
      'neighborhood': 'VIT-AP',
      'is_approved': false,
      'is_active': true,
      'is_rejected': false,
      'rejection_reason': null,
      'contact_phone': phone ?? '9999999999',
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    if (_client == null) {
      // Return fake/mock profile for testing
      return {
        'id': 'fake_pg_123',
        ...rowData,
      };
    }

    // Instead of upsert on Conflict which requires specific DB support,
    // we query first. If a record exists, we update; otherwise, we insert.
    final existing = await fetchOwnerPg(ownerId);
    final Map<String, dynamic> response;
    if (existing != null) {
      response = await _client
          .from('pg_profiles')
          .update(rowData)
          .eq('owner_id', ownerId)
          .select()
          .single();
    } else {
      response = await _client
          .from('pg_profiles')
          .insert(rowData)
          .select()
          .single();
    }
    return response;
  }
}
