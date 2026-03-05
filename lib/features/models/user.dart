class User {
  final String id;
  final String name;
  final String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

// Dummy Current User
final User currentUser = User(
  id: '0',
  name: 'Me',
  avatarUrl: 'https://i.pravatar.cc/150?img=0',
);

// Dummy Users List
final List<User> dummyUsers = [
  User(id: '1', name: 'Mỹ Hương', avatarUrl: 'https://i.pravatar.cc/150?img=1'),
  User(id: '2', name: 'peter', avatarUrl: 'https://i.pravatar.cc/150?img=2'),
  User(id: '3', name: 'Ngọc Diểm', avatarUrl: 'https://i.pravatar.cc/150?img=3'),
  User(id: '4', name: 'Diana', avatarUrl: 'https://i.pravatar.cc/150?img=4'),
];
