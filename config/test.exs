use Mix.Config

config :features,
  test: System.get_env("FEATURES_TEST") == "true",
  features: [:enabled_feature]
