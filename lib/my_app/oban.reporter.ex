defmodule MyApp.ObanReporter do
  @moduledoc false

  @doc """
  Attaches a telemetry handler to capture Oban job exceptions.
  """
  @spec attach() :: :ok | {:error, :already_exists}
  def attach do
    :telemetry.attach("oban-errors", [:oban, :job, :exception], &__MODULE__.handle_event/4, [])
  end

  @doc """
  Handles the Oban job exception event.
  """
  @spec handle_event([atom()], map(), map(), term()) :: any()
  def handle_event([:oban, :job, :exception], measure, meta, _) do
    extra =
      meta.job
      |> Map.take([:id, :args, :meta, :queue, :worker])
      |> Map.merge(measure)

    Sentry.capture_exception(meta.reason, stacktrace: meta.stacktrace, extra: extra)
  end
end
