import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/clients/client_view.dart';

void main() {
  test('navigation drag positions map to all four client views', () {
    expect(
      clientViewAtHorizontalPosition(position: 10, width: 400),
      ClientView.all,
    );
    expect(
      clientViewAtHorizontalPosition(position: 150, width: 400),
      ClientView.active,
    );
    expect(
      clientViewAtHorizontalPosition(position: 250, width: 400),
      ClientView.leads,
    );
    expect(
      clientViewAtHorizontalPosition(position: 390, width: 400),
      ClientView.inactive,
    );
  });

  test('navigation drag positions clamp safely at either edge', () {
    expect(
      clientViewAtHorizontalPosition(position: -30, width: 400),
      ClientView.all,
    );
    expect(
      clientViewAtHorizontalPosition(position: 440, width: 400),
      ClientView.inactive,
    );
  });

  test('client status matching keeps active and inactive separate', () {
    expect(
      clientStatusMatchesView(status: 'active', view: ClientView.active),
      isTrue,
    );
    expect(
      clientStatusMatchesView(status: 'inactive', view: ClientView.active),
      isFalse,
    );
    expect(
      clientStatusMatchesView(status: 'inactive', view: ClientView.inactive),
      isTrue,
    );
    expect(
      clientStatusMatchesView(status: 'lead', view: ClientView.leads),
      isTrue,
    );
  });
}
