use Mix.Config

config :features,
  test: false,
  features: []

import_config "#{Mix.env()}.exs"
