import '../../../core/api/api_client.dart';
import 'models/event_model.dart';

class EventRepository {
  final ApiClient apiClient;

  EventRepository({required this.apiClient});

  // GET /api/v1/content/events (todos: upcoming + recent_past)
  Future<Map<String, List<EventModel>>> getAllEvents() async {
    final response = await apiClient.get('/api/v1/content/events');
    final data = response.data;
    final List<EventModel> upcoming = (data['upcoming'] as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final List<EventModel> past = (data['recent_past'] as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'upcoming': upcoming, 'past': past};
  }

  // GET /api/v1/content/events/upcoming
  Future<List<EventModel>> getUpcomingEvents() async {
    final response = await apiClient.get('/api/v1/content/events/upcoming');
    final data = response.data;
    return (data['events'] as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/content/events/recent_past
  Future<List<EventModel>> getRecentPastEvents() async {
    final response = await apiClient.get('/api/v1/content/events/recent_past');
    final data = response.data;
    return (data['events'] as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/content/events/:id
  Future<EventModel> getEvent(int id) async {
    final response = await apiClient.get('/api/v1/content/events/$id');
    final data = response.data['event'] as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  // POST /api/v1/content/events
  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    final response = await apiClient.post(
      '/api/v1/content/events',
      data: {'event': eventData},
    );
    final data = response.data['event'] as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  // PUT /api/v1/content/events/:id
  Future<EventModel> updateEvent(int id, Map<String, dynamic> eventData) async {
    final response = await apiClient.put(
      '/api/v1/content/events/$id',
      data: {'event': eventData},
    );
    final data = response.data['event'] as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  // DELETE /api/v1/content/events/:id
  Future<void> deleteEvent(int id) async {
    await apiClient.delete('/api/v1/content/events/$id');
  }
}
