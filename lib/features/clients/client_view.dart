enum ClientView { all, active, leads, inactive }

const clientViewOrder = <ClientView>[
  ClientView.all,
  ClientView.active,
  ClientView.leads,
  ClientView.inactive,
];

bool clientStatusMatchesView({
  required String status,
  required ClientView view,
}) {
  return switch (view) {
    ClientView.all => true,
    ClientView.active => status == 'active',
    ClientView.leads => status == 'lead',
    ClientView.inactive => status == 'inactive',
  };
}

ClientView clientViewAtHorizontalPosition({
  required double position,
  required double width,
}) {
  if (width <= 0) return ClientView.all;
  final itemWidth = width / clientViewOrder.length;
  final index = (position / itemWidth).floor().clamp(
    0,
    clientViewOrder.length - 1,
  );
  return clientViewOrder[index];
}
