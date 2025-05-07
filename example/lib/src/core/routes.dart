class Routes {
  static const Duration d = Duration(milliseconds: 700);
  //#PARAMS
  static String userNameParam = 'user_name';

  //# AUTH
  static String authModule = "/auth";
  static String splashRelative = "/splash";
  static String splash = _parsePath("$authModule/$splashRelative");

  static String loginRelative = "/login";
  static String login = _parsePath("$authModule/$loginRelative");

  //#USER
  static String userModule = "/user";

  static String userRelative = "/";
  static String user = _parsePath("$userModule$userRelative");

  static String userNameRelative = "/user_name/:$userNameParam";
  static String userName(String name) =>
      _parsePath("$userModule/user_name/$name");

  static String _parsePath(String path) {
    return path.replaceAll(RegExp(r'/+'), '/');
  }
}
