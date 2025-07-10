abstract class IUserRepository {
  Future<List<String>> getUsers();
  Future<String?> getUserByName(String name);
}

class UserRepository implements IUserRepository {
  UserRepository();

  @override
  Future<List<String>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ['Alice', 'Bob', 'Charlie', 'Diana'];
  }

  @override
  Future<String?> getUserByName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final users = await getUsers();
    return users.firstWhere(
      (user) => user.toLowerCase() == name.toLowerCase(),
      orElse: () => 'Usuário não encontrado',
    );
  }

  void dispose() {}
}
