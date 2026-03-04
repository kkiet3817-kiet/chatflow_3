import '../domain/entities/user.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String name) async {
    await Future.delayed(const Duration(seconds: 1));
    return User(name: name);
  }
}