int? _modularDelayDisposeMilisenconds;

int get modularDelayDisposeMilisenconds => _modularDelayDisposeMilisenconds ?? 500;

void setModularDelayDisposeMiliseconds(int miliseconds) {
  _modularDelayDisposeMilisenconds = miliseconds;
}
