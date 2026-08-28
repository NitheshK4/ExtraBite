import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationRepository {
  final SupabaseClient? _client;

  ReservationRepository(SupabaseClient client) : _client = client;

  ReservationRepository.fakeForTest() : _client = null;

  /// Trigger the atomic database RPC to reserve food portions.
  /// Returns the created reservation database row mapping.
  Future<Map<String, dynamic>> reserveFood({
    required String listingId,
    required int quantity,
  }) async {
    if (_client == null) {
      return {
        'id': 'res-fake-id',
        'readable_id': 'EB-84920',
        'listing_id': listingId,
        'portions_count': quantity,
        'total_amount': 50.0 * quantity,
        'status': 'confirmed',
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    final response = await _client.rpc(
      'reserve_food',
      params: {
        'p_listing_id': listingId,
        'p_quantity': quantity,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Fetch all reservations created by a specific customer.
  Future<List<Map<String, dynamic>>> fetchCustomerReservations(String customerId) async {
    if (_client == null) return [];
    final response = await _client
        .from('reservations')
        .select('*, food_listings(*, pg_profiles(*))')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  /// Fetch all reservations associated with the owner's food listings.
  /// Supabase RLS policies automatically filter the results to the authenticated owner.
  Future<List<Map<String, dynamic>>> fetchOwnerReservations() async {
    if (_client == null) return [];
    final response = await _client
        .from('reservations')
        .select('*, food_listings(*, pg_profiles(*))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  /// Update the status of a specific reservation (e.g., to ready_for_pickup, picked_up, cancelled).
  Future<Map<String, dynamic>> updateReservationStatus(String reservationId, String newStatus) async {
    if (_client == null) {
      return {
        'id': reservationId,
        'readable_id': reservationId,
        'status': newStatus,
      };
    }
    final isReadableId = reservationId.startsWith('EB-');
    final query = _client.from('reservations').update({'status': newStatus});
    
    final response = await (isReadableId
        ? query.eq('readable_id', reservationId)
        : query.eq('id', reservationId))
        .select()
        .single();
    return response;
  }
}
