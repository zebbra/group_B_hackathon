defmodule MyApp.SentryEventFilter do
  @moduledoc false

  @doc false
  @spec filter_event(Sentry.Event.t()) :: Sentry.Event.t() | false
  def filter_event(%Sentry.Event{original_exception: exception} = event) do
    cond do
      Plug.Exception.status(exception) < 500 ->
        false

      match?(%Ash.Error.Query.NotFound{}, exception) ->
        false

      match?(%Ash.Error.Invalid{}, exception) ->
        false

      # Fall back to the default event filter.
      Sentry.DefaultEventFilter.exclude_exception?(exception, event.source) ->
        false

      true ->
        event
    end
  end
end
