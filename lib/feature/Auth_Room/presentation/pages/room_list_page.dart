import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/room_cubit.dart';

class RoomListPage extends StatefulWidget {
  final String userName;

  const RoomListPage({super.key, required this.userName});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoomCubit>().loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF007AFF),
        title: Text(
          "Xin chào ${widget.userName} 👋",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      /// BODY
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<RoomCubit, RoomState>(
            builder: (context, state) {
              if (state is RoomLoading) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (state is RoomLoaded) {
                return ListView.separated(
                  itemCount: state.rooms.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
                    return _RoomCard(roomName: room.name);
                  },
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatefulWidget {
  final String roomName;

  const _RoomCard({required this.roomName});

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isHovering ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isHovering
              ? [
            const BoxShadow(
              blurRadius: 20,
              color: Colors.black12,
            )
          ]
              : [],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 15),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF007AFF),
            child: const Icon(Icons.group, color: Colors.white),
          ),
          title: Text(
            widget.roomName,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text("Nhấn để vào phòng chat"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
      ),
    );
  }
}