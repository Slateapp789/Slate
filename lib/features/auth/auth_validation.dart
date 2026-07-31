enum AuthFormIntent { signIn, signUp, resetPassword }

bool isValidAuthEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > 254) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}

String? validateAuthForm({
  required String email,
  required String password,
  required AuthFormIntent intent,
}) {
  if (email.trim().isEmpty) return 'Enter your email address.';
  if (!isValidAuthEmail(email)) return 'Enter a valid email address.';
  if (intent == AuthFormIntent.resetPassword) return null;
  if (password.isEmpty) return 'Enter your password.';
  if (intent == AuthFormIntent.signUp && password.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  return null;
}

String? validateNewPasswordPair(String password, String confirmation) {
  if (password.length < 8) return 'Use at least 8 characters.';
  if (password != confirmation) return 'The passwords do not match.';
  return null;
}

String friendlyAuthErrorMessage(String rawMessage) {
  final message = rawMessage.toLowerCase();
  if (message.contains('invalid login') ||
      message.contains('invalid credentials')) {
    return 'Wrong email or password.';
  }
  if (message.contains('email not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (message.contains('already registered') ||
      message.contains('already been registered')) {
    return 'An account already exists for that email. Try signing in.';
  }
  if (message.contains('password') && message.contains('weak')) {
    return 'Choose a stronger password.';
  }
  if (message.contains('rate limit') || message.contains('too many')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  return 'We could not complete that request. Check your details and try again.';
}
