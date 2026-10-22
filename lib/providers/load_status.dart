/// Where a provider is in its request cycle.
enum LoadStatus {
  /// Nothing has been requested yet.
  idle,

  /// A request is in flight.
  loading,

  /// The last request succeeded and [LoadableProvider.data] holds the result.
  success,

  /// The last request failed and [LoadableProvider.error] explains why.
  error,
}
