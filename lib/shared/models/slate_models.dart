DateTime? _dateTimeFrom(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double _doubleFrom(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _intFrom(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic>? _nestedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class Workspace {
  final String id;
  final String name;
  final String? industry;
  final DateTime? createdAt;

  const Workspace({
    required this.id,
    required this.name,
    this.industry,
    this.createdAt,
  });

  factory Workspace.fromMap(Map<String, dynamic> map) {
    return Workspace(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Your Business',
      industry: map['industry'] as String?,
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (industry != null) 'industry': industry,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class Client {
  final String id;
  final String workspaceId;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final String status;
  final DateTime? createdAt;

  const Client({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    this.status = 'active',
    this.createdAt,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed client',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'phone': phone,
    'email': email,
    'notes': notes,
    'status': status,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class Service {
  final String id;
  final String workspaceId;
  final String name;
  final int durationMins;
  final double price;
  final String? description;
  final bool showOnProfile;

  const Service({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.durationMins,
    required this.price,
    this.description,
    this.showOnProfile = true,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Service',
      durationMins: _intFrom(map['duration_mins'], 60),
      price: _doubleFrom(map['price']),
      description: map['description'] as String?,
      showOnProfile: map['show_on_profile'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'duration_mins': durationMins,
    'price': price,
    'description': description,
    'show_on_profile': showOnProfile,
  };
}

class Appointment {
  final String id;
  final String workspaceId;
  final String? contactId;
  final String? serviceId;
  final String? title;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final double price;
  final String? notes;
  final String? location;
  final String? recurrenceRule;
  final String? clientName;
  final String? serviceName;

  const Appointment({
    required this.id,
    required this.workspaceId,
    this.contactId,
    this.serviceId,
    this.title,
    required this.startTime,
    this.endTime,
    this.status = 'scheduled',
    this.price = 0,
    this.notes,
    this.location,
    this.recurrenceRule,
    this.clientName,
    this.serviceName,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    final contact = _nestedMap(map['contacts']);
    final service = _nestedMap(map['services']);
    return Appointment(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      contactId: map['contact_id'] as String?,
      serviceId: map['service_id'] as String?,
      title: map['title'] as String?,
      startTime:
          _dateTimeFrom(map['start_time']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endTime: _dateTimeFrom(map['end_time']),
      status: map['status'] as String? ?? 'scheduled',
      price: _doubleFrom(map['price']),
      notes: map['notes'] as String?,
      location: map['location'] as String?,
      recurrenceRule: map['recurrence_rule'] as String?,
      clientName: contact?['name'] as String?,
      serviceName: service?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'contact_id': contactId,
    'service_id': serviceId,
    'title': title,
    'start_time': startTime.toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toIso8601String(),
    'status': status,
    'price': price,
    'notes': notes,
    'location': location,
    'recurrence_rule': recurrenceRule,
  };
}

class Payment {
  final String id;
  final String workspaceId;
  final String? contactId;
  final String number;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final double total;
  final double amountPaid;
  final String? notes;
  final String? clientName;

  const Payment({
    required this.id,
    required this.workspaceId,
    this.contactId,
    required this.number,
    required this.status,
    required this.issueDate,
    this.dueDate,
    required this.total,
    this.amountPaid = 0,
    this.notes,
    this.clientName,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    final contact = _nestedMap(map['contacts']);
    return Payment(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      contactId: map['contact_id'] as String?,
      number:
          map['invoice_number'] as String? ??
          map['payment_number'] as String? ??
          '',
      status: map['status'] as String? ?? 'pending',
      issueDate:
          _dateTimeFrom(map['issue_date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueDate: _dateTimeFrom(map['due_date']),
      total: _doubleFrom(map['total']),
      amountPaid: _doubleFrom(map['amount_paid']),
      notes: map['notes'] as String?,
      clientName: contact?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'contact_id': contactId,
    'invoice_number': number,
    'status': status,
    'issue_date': issueDate.toIso8601String().split('T').first,
    if (dueDate != null)
      'due_date': dueDate!.toIso8601String().split('T').first,
    'total': total,
    'amount_paid': amountPaid,
    'notes': notes,
  };
}

class SlateTask {
  final String id;
  final String workspaceId;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String? contactId;
  final String? clientName;

  const SlateTask({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.status = 'open',
    this.priority = 'medium',
    this.dueDate,
    this.contactId,
    this.clientName,
  });

  factory SlateTask.fromMap(Map<String, dynamic> map) {
    final contact = _nestedMap(map['contacts']);
    return SlateTask(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      priority: map['priority'] as String? ?? 'medium',
      dueDate: _dateTimeFrom(map['due_date']),
      contactId: map['contact_id'] as String?,
      clientName: contact?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'title': title,
    'status': status,
    'priority': priority,
    if (dueDate != null)
      'due_date': dueDate!.toIso8601String().split('T').first,
    'contact_id': contactId,
  };
}

class BusinessProfile {
  final String id;
  final String workspaceId;
  final String handle;
  final String? bio;
  final String? coverPhotoUrl;
  final bool reviewsEnabled;
  final bool galleryEnabled;
  final bool payNowEnabled;
  final String bookingMode;
  final String? noticeText;
  final DateTime? noticeStart;
  final DateTime? noticeEnd;

  const BusinessProfile({
    required this.id,
    required this.workspaceId,
    required this.handle,
    this.bio,
    this.coverPhotoUrl,
    this.reviewsEnabled = false,
    this.galleryEnabled = false,
    this.payNowEnabled = false,
    this.bookingMode = 'manual',
    this.noticeText,
    this.noticeStart,
    this.noticeEnd,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      handle: map['handle'] as String? ?? '',
      bio: map['bio'] as String?,
      coverPhotoUrl: map['cover_photo_url'] as String?,
      reviewsEnabled: map['reviews_enabled'] as bool? ?? false,
      galleryEnabled: map['gallery_enabled'] as bool? ?? false,
      payNowEnabled: map['pay_now_enabled'] as bool? ?? false,
      bookingMode: map['booking_mode'] as String? ?? 'manual',
      noticeText: map['notice_text'] as String?,
      noticeStart: _dateTimeFrom(map['notice_start']),
      noticeEnd: _dateTimeFrom(map['notice_end']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'handle': handle,
    'bio': bio,
    'cover_photo_url': coverPhotoUrl,
    'reviews_enabled': reviewsEnabled,
    'gallery_enabled': galleryEnabled,
    'pay_now_enabled': payNowEnabled,
    'booking_mode': bookingMode,
    'notice_text': noticeText,
    if (noticeStart != null) 'notice_start': noticeStart!.toIso8601String(),
    if (noticeEnd != null) 'notice_end': noticeEnd!.toIso8601String(),
  };
}

class BookingRequest {
  final String id;
  final String workspaceId;
  final String name;
  final String phone;
  final String? serviceId;
  final String? serviceName;
  final int? serviceDurationMins;
  final double? servicePrice;
  final String? preferredTimeText;
  final String? message;
  final String status;
  final DateTime? createdAt;

  const BookingRequest({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.phone,
    this.serviceId,
    this.serviceName,
    this.serviceDurationMins,
    this.servicePrice,
    this.preferredTimeText,
    this.message,
    this.status = 'pending',
    this.createdAt,
  });

  factory BookingRequest.fromMap(Map<String, dynamic> map) {
    final service = _nestedMap(map['services']);
    return BookingRequest(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      serviceId: map['service_id'] as String?,
      serviceName: service?['name'] as String?,
      serviceDurationMins: _intFrom(service?['duration_mins'], 0) == 0
          ? null
          : _intFrom(service?['duration_mins']),
      servicePrice: service?['price'] == null
          ? null
          : _doubleFrom(service?['price']),
      preferredTimeText: map['preferred_time_text'] as String?,
      message: map['message'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'phone': phone,
    'service_id': serviceId,
    'preferred_time_text': preferredTimeText,
    'message': message,
    'status': status,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class SlateNotification {
  final String id;
  final String workspaceId;
  final String type;
  final String title;
  final String body;
  final String? deepLink;
  final bool read;
  final DateTime? createdAt;

  const SlateNotification({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.title,
    required this.body,
    this.deepLink,
    this.read = false,
    this.createdAt,
  });

  factory SlateNotification.fromMap(Map<String, dynamic> map) {
    return SlateNotification(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      deepLink: map['deep_link'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }
}
