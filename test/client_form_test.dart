import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/clients/widgets/client_form.dart';
import 'package:workloop/shared/models/slate_models.dart';

void main() {
  test('client email validation accepts blank and valid addresses', () {
    expect(isValidClientEmail(''), isTrue);
    expect(isValidClientEmail('hello@example.com'), isTrue);
    expect(isValidClientEmail('hello@'), isFalse);
    expect(isValidClientEmail('hello example.com'), isFalse);
  });

  test('duplicate client matching normalises phone and email', () {
    const clients = [
      Client(
        id: 'existing',
        workspaceId: 'workspace',
        name: 'Harper & Co',
        phone: '020 7946 0210',
        email: 'HELLO@EXAMPLE.COM',
      ),
    ];

    expect(
      findDuplicateClient(clients, phone: '020-7946-0210', email: '')?.id,
      'existing',
    );
    expect(
      findDuplicateClient(clients, phone: '', email: 'hello@example.com')?.id,
      'existing',
    );
  });

  test('duplicate client matching can exclude the edited client', () {
    const clients = [
      Client(
        id: 'editing',
        workspaceId: 'workspace',
        name: 'Harper & Co',
        phone: '020 7946 0210',
      ),
    ];

    expect(
      findDuplicateClient(
        clients,
        phone: '020 7946 0210',
        email: '',
        excludingClientId: 'editing',
      ),
      isNull,
    );
  });
}
