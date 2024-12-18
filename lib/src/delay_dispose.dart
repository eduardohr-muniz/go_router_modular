int? _modularDelayDisposeMilisenconds;

int get modularDelayDisposeMilisenconds => _modularDelayDisposeMilisenconds ?? 2000;

void setModularDelayDisposeMiliseconds(int miliseconds) {
  _modularDelayDisposeMilisenconds = miliseconds;
}
