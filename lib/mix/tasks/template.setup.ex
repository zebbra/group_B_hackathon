if Mix.env() != :prod do
  defmodule Mix.Tasks.Template.Setup do
    @shortdoc "Renames the template project to your application name"

    @moduledoc """
    Renames the template project to your application name using Igniter.

    After the rename is applied, `mix template.finalize` runs automatically: it
    deletes this mix task, discards the template's git history, and creates a
    fresh initial commit. Pass `--no-git` to keep the existing git history.

    Usage:
      mix template.setup MyApp
      mix template.setup MyApp --no-git
    """

    use Igniter.Mix.Task

    alias Rewrite.Source

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        positional: [:module],
        schema: [git: :boolean],
        defaults: [git: true],
        example: "mix template.setup MyApp"
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      case parse_module_name(igniter) do
        {:ok, module_name} ->
          run(igniter, module_name)

        :error ->
          Igniter.add_issue(
            igniter,
            "Expected a single valid module name (e.g. MyApp). Example: mix template.setup MyApp"
          )
      end
    end

    defp parse_module_name(igniter) do
      igniter
      |> candidates()
      |> Enum.map(&normalize_name/1)
      |> Enum.find_value(:error, fn name ->
        if valid_module_name?(name), do: {:ok, name}
      end)
    end

    defp candidates(igniter) do
      [
        Map.values(igniter.args.positional),
        igniter.args.argv,
        System.argv()
      ]
      |> List.flatten()
      |> Enum.filter(&is_binary/1)
    end

    defp normalize_name(name) do
      String.trim(name, ~s("'))
    end

    defp valid_module_name?(name) do
      name != "" and String.match?(name, ~r/^[A-Z][A-Za-z0-9]*(?:\.[A-Z][A-Za-z0-9]*)*$/)
    end

    defp run(igniter, module_name) do
      otp_app = Macro.underscore(module_name)
      replacements = build_replacements(module_name, otp_app)
      finalize_argv = if igniter.args.options[:git], do: [], else: ["--no-git"]

      igniter
      |> replace_in_files(replacements)
      |> update_readme(module_name)
      |> move_files(otp_app)
      |> Igniter.add_task("template.finalize", finalize_argv)
      |> Igniter.add_notice("Template renamed to #{module_name} (#{otp_app}).")
      |> Igniter.add_notice("""
      You must manually delete the following folders:
      - lib/my_app
      - lib/my_app_web
      - test/my_app
      - test/my_app_web
      - helm/charts/my_app
      """)
    end

    defp build_replacements(module_name, otp_app) do
      [
        {"MyAppWeb", module_name <> "Web"},
        {"MyApp", module_name},
        {"my_app_web", otp_app <> "_web"},
        {"my_app", otp_app},
        {"my-app", String.replace(otp_app, "_", "-")},
        {"MY_APP", String.upcase(otp_app)}
      ]
    end

    defp replace_in_files(igniter, replacements) do
      Enum.reduce(template_files(), igniter, fn path, igniter ->
        igniter
        |> Igniter.include_existing_file(path, required?: false)
        |> Igniter.update_file(
          path,
          &do_replace_in_file(&1, replacements),
          required?: false
        )
      end)
    end

    defp do_replace_in_file(source, replacements) do
      content = Source.get(source, :content)

      updated =
        Enum.reduce(replacements, content, fn {from, to}, acc ->
          String.replace(acc, from, to)
        end)

      Source.update(source, :content, updated)
    end

    defp update_readme(igniter, module_name) do
      Igniter.update_file(
        igniter,
        "README.md",
        fn source ->
          content = Source.get(source, :content)

          pattern =
            ~r/## Template customization checklist[\s\S]*?## Authentication \(Magic Link \+ optional OIDC SSO\)/

          replacement =
            "## Project setup\n\nThis project was initialized for #{module_name} using `mix template.setup`.\n\n## Authentication (Magic Link + optional OIDC SSO)"

          updated = Regex.replace(pattern, content, replacement)
          Source.update(source, :content, updated)
        end,
        required?: false
      )
    end

    defp move_files(igniter, otp_app) do
      Enum.reduce(paths_to_move(), igniter, fn path, igniter ->
        new_path = String.replace(path, "my_app", otp_app)

        if File.dir?(path) do
          move_dir_contents(igniter, path, new_path)
        else
          Igniter.move_file(igniter, path, new_path)
        end
      end)
    end

    defp move_dir_contents(igniter, src, dest) do
      src
      |> Path.join("**/*")
      |> Path.wildcard(match_dot: true)
      |> Enum.reject(&File.dir?/1)
      |> Enum.reduce(igniter, fn file, igniter ->
        relative = Path.relative_to(file, src)
        Igniter.move_file(igniter, file, Path.join(dest, relative))
      end)
    end

    defp template_files do
      [
        "lib/**/*.{ex,exs,heex}",
        "test/**/*.{ex,exs,heex}",
        "config/**/*.{ex,exs}",
        "assets/{css,js,vendor}/**/*.{js,ts,css}",
        "assets/*.{js,ts,json}",
        "priv/**/*.{po,pot,md,txt,json}",
        "rel/**/*",
        "README.md",
        "mix.exs",
        "Dockerfile",
        ".gitignore",
        ".doctor.exs",
        ".formatter.exs",
        ".igniter.exs",
        ".github/**/*.{yml,yaml}",
        "helm/charts/**/*.{yml,yaml,tpl,md}"
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.reject(fn path ->
        File.dir?(path) or path == "lib/mix/tasks/template.setup.ex"
      end)
    end

    defp paths_to_move do
      [
        "lib/my_app",
        "lib/my_app_web",
        "lib/my_app.ex",
        "lib/my_app_web.ex",
        "test/my_app",
        "test/my_app_web",
        "helm/charts/my_app"
      ]
    end
  end

  defmodule Mix.Tasks.Template.Finalize do
    @shortdoc "Finalizes the template setup (run automatically by template.setup)"

    @moduledoc """
    Runs after `mix template.setup` has applied its changes: deletes the
    template's mix tasks, discards the template's git history, and creates a
    fresh initial commit for the renamed project.

    Pass `--no-git` to keep the existing git history.
    """

    use Mix.Task

    @task_file "lib/mix/tasks/template.setup.ex"

    @impl Mix.Task
    def run(argv) do
      {opts, _argv} = OptionParser.parse!(argv, strict: [git: :boolean])

      File.rm_rf!(@task_file)
      Mix.shell().info("Deleted #{@task_file}.")

      if Keyword.get(opts, :git, true), do: reset_git_history()
    end

    defp reset_git_history do
      if System.find_executable("git") do
        File.rm_rf!(".git")
        git!(["init"])
        git!(["add", "-A"])
        git!(["commit", "-m", "Initial commit"])
        Mix.shell().info("Reset git history and created a fresh initial commit.")
      else
        Mix.shell().error("git executable not found — skipped resetting git history.")
      end
    end

    defp git!(args) do
      case System.cmd("git", args, stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {output, status} ->
          Mix.raise("git #{Enum.join(args, " ")} failed (#{status}):\n#{output}")
      end
    end
  end
end
