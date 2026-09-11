ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter], exclude: [pending: true])

ExUnit.start(capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, :manual)
