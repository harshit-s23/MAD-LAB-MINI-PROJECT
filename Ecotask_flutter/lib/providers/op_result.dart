/// Outcome of a provider action, carrying a user-presentable message.
class OpResult {
  const OpResult.ok([this.message]) : success = true;
  const OpResult.fail(this.message) : success = false;

  final bool success;
  final String? message;
}
