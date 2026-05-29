import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final String firstName;
  final String businessName;
  final String industry;
  final String handle;
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic> workingHours;
  final double revenueTarget;
  final Map<String, dynamic>?
  firstBooking; // {clientName, serviceName, date, hour, minute}

  const OnboardingState({
    this.firstName = '',
    this.businessName = '',
    this.industry = '',
    this.handle = '',
    this.services = const [],
    this.workingHours = const {},
    this.revenueTarget = 0,
    this.firstBooking,
  });

  OnboardingState copyWith({
    String? firstName,
    String? businessName,
    String? industry,
    String? handle,
    List<Map<String, dynamic>>? services,
    Map<String, dynamic>? workingHours,
    double? revenueTarget,
    Map<String, dynamic>? firstBooking,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      businessName: businessName ?? this.businessName,
      industry: industry ?? this.industry,
      handle: handle ?? this.handle,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
      revenueTarget: revenueTarget ?? this.revenueTarget,
      firstBooking: firstBooking ?? this.firstBooking,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setName(String firstName, String businessName) {
    state = state.copyWith(firstName: firstName, businessName: businessName);
  }

  void setIndustry(String industry) {
    state = state.copyWith(industry: industry);
  }

  void setHandle(String handle) {
    state = state.copyWith(handle: handle);
  }

  void setServices(List<Map<String, dynamic>> services) {
    state = state.copyWith(services: services);
  }

  void setWorkingHours(Map<String, dynamic> hours) {
    state = state.copyWith(workingHours: hours);
  }

  void setRevenueTarget(double target) {
    state = state.copyWith(revenueTarget: target);
  }

  void setFirstBooking(Map<String, dynamic> booking) {
    state = state.copyWith(firstBooking: booking);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
