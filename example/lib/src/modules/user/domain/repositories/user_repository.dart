import 'package:example/src/modules/user/domain/repositories/i_user_repository.dart';

class UserRepository implements IUserRepository {
  @override
  String getSurname() {
    return "Muniz";
  }
}
