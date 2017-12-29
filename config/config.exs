use Mix.Config

config :plug_response_cache,
  enabled: true,
  store: PlugResponseCache.Stores.Ets,
  profile: PlugResponseCache.Profiles.Default
