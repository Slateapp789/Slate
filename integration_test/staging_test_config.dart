const _productionProjectRef = 'imtbyrvsonzvtddswbtb';

const stagingUrl = String.fromEnvironment('SUPABASE_URL');
const stagingAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const stagingProjectRef = String.fromEnvironment('E2E_STAGING_PROJECT_REF');
const stagingWritesAllowed = bool.fromEnvironment('E2E_ALLOW_WRITES');

void requireSafeStagingWriteTarget() {
  if (!stagingWritesAllowed) return;
  if (stagingProjectRef.isEmpty) {
    throw StateError(
      'E2E_STAGING_PROJECT_REF is required when E2E_ALLOW_WRITES is true.',
    );
  }
  if (stagingProjectRef == _productionProjectRef) {
    throw StateError('Refusing write-capable E2E against production.');
  }

  final expectedUrl = 'https://$stagingProjectRef.supabase.co';
  if (_withoutTrailingSlash(stagingUrl) != expectedUrl) {
    throw StateError(
      'SUPABASE_URL must exactly match the declared staging project ref.',
    );
  }
}

String _withoutTrailingSlash(String value) {
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
