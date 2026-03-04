import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'feature/auth_room/data/auth_repository_impl.dart';
import 'feature/auth_room/data/room_repository_impl.dart';
import 'feature/auth_room/presentation/cubit/auth_cubit.dart';
import 'feature/auth_room/presentation/cubit/room_cubit.dart';
import 'feature/auth_room/presentation/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(AuthRepositoryImpl())),
        BlocProvider(create: (_) => RoomCubit(RoomRepositoryImpl())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
      ),
    );
  }
}