import '../domain/entities/room.dart';
import 'room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  @override
  Future<List<Room>> getRooms() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Room(id: '1', name: 'chat'),
      Room(id: '2', name: 'Flutter'),
      Room(id: '3', name: 'gaming'),
    ];
  }
}