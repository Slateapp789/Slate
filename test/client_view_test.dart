import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/clients/client_view.dart';

void main() {
  test('pill drag positions map to all four client views', () {
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

  test('pill drag positions clamp safely at either edge', () {
    expect(
      clientViewAtHorizontalPosition(position: -30, width: 400),
      ClientView.all,
    );
    expect(
      clientViewAtHorizontalPosition(position: 440, width: 400),
      ClientView.inactive,
    );
  });

  test('left swipes move from All to Active to Leads to Inactive', () {
    expect(
      clientViewAfterSwipe(
        current: ClientView.all,
        dragDistance: -80,
        velocity: 0,
      ),
      ClientView.active,
    );
    expect(
      clientViewAfterSwipe(
        current: ClientView.active,
        dragDistance: -80,
        velocity: 0,
      ),
      ClientView.leads,
    );
    expect(
      clientViewAfterSwipe(
        current: ClientView.leads,
        dragDistance: -80,
        velocity: 0,
      ),
      ClientView.inactive,
    );
    expect(
      clientViewAfterSwipe(
        current: ClientView.inactive,
        dragDistance: -80,
        velocity: 0,
      ),
      ClientView.inactive,
    );
  });

  test('right swipes move from Inactive to Leads to Active to All', () {
    expect(
      clientViewAfterSwipe(
        current: ClientView.inactive,
        dragDistance: 80,
        velocity: 0,
      ),
      ClientView.leads,
    );
    expect(
      clientViewAfterSwipe(
        current: ClientView.leads,
        dragDistance: 80,
        velocity: 0,
      ),
      ClientView.active,
    );
    expect(
      clientViewAfterSwipe(
        current: ClientView.active,
        dragDistance: 80,
        velocity: 0,
      ),
      ClientView.all,
    );
  });

  test('short slow gestures do not change the selected view', () {
    expect(
      clientViewAfterSwipe(
        current: ClientView.active,
        dragDistance: 24,
        velocity: 180,
      ),
      ClientView.active,
    );
  });

  test('quick flicks switch views even when the distance is short', () {
    expect(
      clientViewAfterSwipe(
        current: ClientView.all,
        dragDistance: -20,
        velocity: -600,
      ),
      ClientView.active,
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
