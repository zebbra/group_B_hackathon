defmodule MyApp.Prettier do
  @moduledoc """
  Formats the content of `<script>` tags in HEEx templates with prettier.

  Registered as a `Phoenix.LiveView.HTMLFormatter.TagFormatter` in
  `.formatter.exs`, so `mix format` also formats colocated hooks
  (`<script :type={ColocatedHook}>`) and plain inline scripts.

  Prettier runs as `bun run --bun prettier`, which executes `node_modules/.bin/prettier`.
  The `--bun` flag overrides the shebang line in the script (which uses node).

  `--config` is required: prettier looks for its configuration next to the file
  it formats, and the content of a `<script>` tag is written to a temporary file
  outside the project, so `assets/.prettierrc` would never be picked up.

  When prettier cannot format a tag — a syntax error, or no prettier available
  to bun — the tag is left untouched instead of failing the format run, and
  prettier's own diagnostics are passed through on stderr.

  Note that `mix format` without arguments only revisits files modified since
  its last run, and a change here does not invalidate that cache: use
  `mix format --force` to reformat everything after editing this module or
  `assets/.prettierrc`.
  """

  @behaviour Phoenix.LiveView.HTMLFormatter.TagFormatter

  @impl Phoenix.LiveView.HTMLFormatter.TagFormatter
  def render_tag({"script", attrs, content}, _opts) do
    if String.trim(content) == "",
      do: :skip,
      else: run(content, file_name(attrs))
  end

  def render_tag(_tag, _opts), do: :skip

  # sobelow_skip ["Traversal.FileModule"]
  defp run(content, file_name) do
    file =
      Path.join(System.tmp_dir!(), "prettier_#{System.unique_integer([:positive])}_#{file_name}")

    try do
      File.write!(file, content)

      # stderr is deliberately kept out of stdout: prettier writes the formatted
      # code to stdout, while bun reports installs ("Resolving dependencies", ...)
      # and prettier reports syntax errors on stderr. Merging the two would
      # splice that output into the formatted script.
      case prettier_cmd(file) do
        {output, 0} ->
          {:ok, String.trim(output)}

        {_output, status} ->
          IO.puts(:stderr, "prettier exited with #{status} while formatting a <script> tag")
          :skip
      end
    after
      File.rm(file)
    end
  end

  # sobelow_skip ["CI.System"]
  defp prettier_cmd(file) do
    # runs prettier using the script at assets/node_modules/.bin/prettier. we need to pass the config
    # file explicitly because the tmp file is located in a different directory
    # the --bun flag overrides the shebang line in the script to use bun instead of node
    System.cmd(Bun.bin_path(), ["run", "--bun", "prettier", "--config", ".prettierrc", file],
      cd: Path.expand("../../assets", __DIR__),
      stderr_to_stdout: false
    )
  end

  # The extension drives prettier's parser, so colocated TypeScript hooks
  # (`extension="ts"`) are not parsed as plain JavaScript.
  defp file_name(%{"extension" => extension}) when is_binary(extension), do: "colocated.#{extension}"

  defp file_name(%{"manifest" => manifest}) when is_binary(manifest), do: Path.basename(manifest)

  defp file_name(_attrs), do: "colocated.js"
end
