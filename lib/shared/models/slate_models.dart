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

List<String> _stringListFrom(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
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
  final String? address;
  final String? notes;
  final String? importantNotes;
  final String status;
  final String preferredContactMethod;
  final String? source;
  final DateTime? birthday;
  final List<String> tags;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;

  const Client({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.importantNotes,
    this.status = 'active',
    this.preferredContactMethod = 'phone',
    this.source,
    this.birthday,
    this.tags = const [],
    this.lastActivityAt,
    this.createdAt,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed client',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      importantNotes: map['important_notes'] as String?,
      status: map['status'] as String? ?? 'active',
      preferredContactMethod:
          map['preferred_contact_method'] as String? ?? 'phone',
      source: map['source'] as String?,
      birthday: _dateTimeFrom(map['birthday']),
      tags: _stringListFrom(map['tags']),
      lastActivityAt: _dateTimeFrom(map['last_activity_at']),
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'notes': notes,
    'important_notes': importantNotes,
    'status': status,
    'preferred_contact_method': preferredContactMethod,
    'source': source,
    if (birthday != null)
      'birthday': birthday!.toIso8601String().split('T').first,
    'tags': tags,
    if (lastActivityAt != null)
      'last_activity_at': lastActivityAt!.toIso8601String(),
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

class Expense {
  final String id;
  final String workspaceId;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final String? notes;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.workspaceId,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.notes,
    this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      amount: _doubleFrom(map['amount']),
      category: map['category'] as String? ?? 'Other',
      expenseDate:
          _dateTimeFrom(map['expense_date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      notes: map['notes'] as String?,
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'amount': amount,
    'category': category,
    'expense_date': expenseDate.toIso8601String().split('T').first,
    'notes': notes,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class SlateTask {
  final String id;
  final String workspaceId;
  final String title;
  final String status;
  final String priority;
  final String reminderTiming;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? contactId;
  final String? appointmentId;
  final String? clientName;

  const SlateTask({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.status = 'open',
    this.priority = 'medium',
    this.reminderTiming = 'none',
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.contactId,
    this.appointmentId,
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
      reminderTiming: map['reminder_timing'] as String? ?? 'none',
      dueDate: _dateTimeFrom(map['due_date']),
      createdAt: _dateTimeFrom(map['created_at']),
      updatedAt: _dateTimeFrom(map['updated_at']),
      contactId: map['contact_id'] as String?,
      appointmentId: map['appointment_id'] as String?,
      clientName: contact?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'title': title,
    'status': status,
    'priority': priority,
    'reminder_timing': reminderTiming,
    if (dueDate != null)
      'due_date': dueDate!.toIso8601String().split('T').first,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    'contact_id': contactId,
    'appointment_id': appointmentId,
  };
}

class TaskChecklistItem {
  final String id;
  final String workspaceId;
  final String taskId;
  final String title;
  final bool completed;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskChecklistItem({
    required this.id,
    required this.workspaceId,
    required this.taskId,
    required this.title,
    this.completed = false,
    this.position = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskChecklistItem.fromMap(Map<String, dynamic> map) {
    return TaskChecklistItem(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String? ?? '',
      taskId: map['task_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
      position: _intFrom(map['position']),
      createdAt: _dateTimeFrom(map['created_at']),
      updatedAt: _dateTimeFrom(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspace_id': workspaceId,
    'task_id': taskId,
    'title': title,
    'completed': completed,
    'position': position,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

class BusinessProfile {
  final String id;
  final String workspaceId;
  final String handle;
  final String? bio;
  final String? coverPhotoUrl;
  final List<String> galleryImageUrls;
  final List<String> reviewQuotes;
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
    this.galleryImageUrls = const [],
    this.reviewQuotes = const [],
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
      galleryImageUrls: _stringListFrom(map['gallery_image_urls']),
      reviewQuotes: _stringListFrom(map['review_quotes']),
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
    'gallery_image_urls': galleryImageUrls,
    'review_quotes': reviewQuotes,
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
