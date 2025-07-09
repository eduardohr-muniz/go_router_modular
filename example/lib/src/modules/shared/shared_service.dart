class SharedService {
  SharedService() {
    print('🔗 [SHARED_SERVICE] SharedService criado');
  }

  void log(String message) {
    print('🔗 [SHARED_SERVICE] $message');
  }

  void dispose() {
    print('🔗 [SHARED_SERVICE] SharedService disposto');
  }
}
