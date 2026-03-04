import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/room.dart';
import '../../data/room_repository.dart';

abstract class RoomState {}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomLoaded extends RoomState {
  final List<Room> rooms;
  RoomLoaded(this.rooms);
}

class RoomCubit extends Cubit<RoomState> {
  final RoomRepository repository;

  RoomCubit(this.repository) : super(RoomInitial());

  void loadRooms() async {
    emit(RoomLoading());
    final rooms = await repository.getRooms();
    emit(RoomLoaded(rooms));
  }
}