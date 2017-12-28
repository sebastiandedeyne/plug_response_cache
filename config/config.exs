use Mix.Config

config :response_cache,
  enabled: true,
  store: PlugResponseCache.Stores.Ets,
  profile: PlugResponseCache.Profiles.Default
