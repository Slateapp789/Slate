import 'package:flutter_test/flutter_test.dart';
import 'package:slate/shared/models/slate_models.dart';

void main() {
  group('Slate models', () {
    test('Client preserves CRM fields across map boundaries', () {
      final client = Client.fromMap({
        'id': 'client-1',
        'workspace_id': 'workspace-1',
        'name': 'Sarah Morgan',
        'phone': '07123 456789',
        'email': 'sarah@example.com',
        'notes': 'Prefers mornings',
        'status': 'active',
      });

      expect(client.name, 'Sarah Morgan');
      expect(client.toMap()['workspace_id'], 'workspace-1');
      expect(client.toMap()['notes'], 'Prefers mornings');
    });

    test('Appointment reads joined client and service names', () {
      final appointment = Appointment.fromMap({
        'id': 'appt-1',
        'workspace_id': 'workspace-1',
        'contact_id': 'client-1',
        'service_id': 'service-1',
        'start_time': '2026-05-28T09:00:00Z',
        'end_time': '2026-05-28T10:00:00Z',
        'status': 'scheduled',
        'price': 45,
        'contacts': {'name': 'Sarah Morgan'},
        'services': {'name': 'Cut and finish'},
      });

      expect(appointment.clientName, 'Sarah Morgan');
      expect(appointment.serviceName, 'Cut and finish');
      expect(appointment.price, 45);
    });

    test('Payment keeps simple payment language on invoice-backed rows', () {
      final payment = Payment.fromMap({
        'id': 'pay-1',
        'workspace_id': 'workspace-1',
        'invoice_number': 'PAY-001',
        'status': 'paid',
        'issue_date': '2026-05-28',
        'total': '70.50',
        'amount_paid': 70.5,
        'contacts': {'name': 'Alex'},
      });

      expect(payment.number, 'PAY-001');
      expect(payment.total, 70.5);
      expect(payment.clientName, 'Alex');
    });

    test('Payment serializes back to the invoice-backed database shape', () {
      final payment = Payment.fromMap({
        'id': 'pay-2',
        'workspace_id': 'workspace-1',
        'contact_id': 'client-1',
        'payment_number': 'PAY-002',
        'status': 'sent',
        'issue_date': '2026-05-29',
        'due_date': '2026-06-05',
        'total': 120,
        'amount_paid': 0,
        'notes': 'Package deposit',
      });

      final map = payment.toMap();

      expect(map['invoice_number'], 'PAY-002');
      expect(map['issue_date'], '2026-05-29');
      expect(map['due_date'], '2026-06-05');
      expect(map['contact_id'], 'client-1');
      expect(map['total'], 120);
    });

    test('SlateTask reads linked client data and date fields', () {
      final task = SlateTask.fromMap({
        'id': 'task-1',
        'workspace_id': 'workspace-1',
        'title': 'Follow up about package',
        'status': 'open',
        'priority': 'high',
        'due_date': '2026-06-02',
        'contact_id': 'client-1',
        'contacts': {'name': 'Maya'},
      });

      expect(task.clientName, 'Maya');
      expect(task.dueDate, DateTime(2026, 6, 2));
      expect(task.toMap()['due_date'], '2026-06-02');
    });

    test('Service preserves public profile visibility fields', () {
      final service = Service.fromMap({
        'id': 'service-1',
        'workspace_id': 'workspace-1',
        'name': 'Consultation',
        'duration_mins': '45',
        'price': '35',
        'description': 'Initial consult',
        'show_on_profile': false,
      });

      expect(service.durationMins, 45);
      expect(service.price, 35);
      expect(service.showOnProfile, isFalse);
      expect(service.toMap()['show_on_profile'], isFalse);
    });

    test('BusinessProfile defaults new V1 public profile controls safely', () {
      final profile = BusinessProfile.fromMap({
        'id': 'profile-1',
        'workspace_id': 'workspace-1',
        'handle': 'slate-demo',
      });

      expect(profile.bookingMode, 'manual');
      expect(profile.reviewsEnabled, isFalse);
      expect(profile.galleryEnabled, isFalse);
      expect(profile.payNowEnabled, isFalse);
    });

    test('BookingRequest reads selected service and preferred timing', () {
      final request = BookingRequest.fromMap({
        'id': 'request-1',
        'workspace_id': 'workspace-1',
        'name': 'Nadia',
        'phone': '07123 000000',
        'service_id': 'service-1',
        'preferred_time_text': 'Friday afternoon',
        'message': 'First visit',
        'status': 'contacted',
        'services': {'name': 'Initial consultation'},
      });

      expect(request.serviceName, 'Initial consultation');
      expect(request.preferredTimeText, 'Friday afternoon');
      expect(request.status, 'contacted');
      expect(request.toMap()['preferred_time_text'], 'Friday afternoon');
    });
  });
}
