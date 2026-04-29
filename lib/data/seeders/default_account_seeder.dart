import 'package:mindcash_app/data/repositories/account_repository.dart';

class DefaultAccountSeeder {
  const DefaultAccountSeeder(this._accountRepository);

  final AccountRepository _accountRepository;

  Future<void> seed() async {
    final existingAccounts = await _accountRepository.listActiveAccounts();

    if (existingAccounts.isNotEmpty) {
      return;
    }

    await _accountRepository.createAccount(name: 'Carteira', type: 'wallet');
  }
}
