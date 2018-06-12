defmodule Mix.Tasks.Lfe.New do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Creates a new LFE project"
  @switches [
    setup: :boolean
  ]

  @moduledoc """
  Creates a new LFE project.

  This task is based on the source code of the `Mix.Tasks.New` task.

  It expects the path of the project as argument.

      mix new PATH [--setup]

  A project at the given PATH will be created.
  The application name and module name will be retrieved from the path.

  ## Examples

      mix new my_lfe_project

  The LFE projects depend on the LFE compiler, which has to be downloaded and installed itself.
  This can be done either manually, by running `mix lfe.deps.setup` in the newly generatd project,
  or automatically by running this task the following way:

      mix new my_lfe_project --setup

  """

  @doc """
  Runs this task.
  """
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    case argv do
      [] ->
        Mix.raise("Expected PATH to be given, please use \"mix lfe.new PATH\"")

      [path | _] ->
        app = Path.basename(Path.expand(path))
        check_application_name!(app)

        mod = Macro.underscore(app)
        check_mod_name_availability!(mod)

        check_directory_existence!(path)
        File.mkdir_p!(path)

        File.cd!(path, fn -> generate(app, mod, path, opts) end)
    end
  end

  defp check_application_name!(name) do
    unless name =~ Regex.recompile!(~r/^[a-z][a-z0-9_]*$/) do
      Mix.raise(
        "Application name must start with a letter and have only lowercase " <>
          "letters, numbers and underscore, got: #{inspect(name)}."
      )
    end
  end

  defp check_mod_name_availability!(name) do
    name = String.to_atom(name)

    if Code.ensure_loaded?(name) do
      Mix.raise("Module name #{inspect(name)} is already taken, please choose another name")
    end
  end

  defp check_directory_existence!(path) do
    msg = "The directory #{inspect(path)} already exists. Are you sure you want to continue?"

    if File.dir?(path) and not Mix.shell().yes?(msg) do
      Mix.raise("Please select another directory for installation!")
    end
  end

  defp generate(app, mod, path, opts) do
    assigns = [
      app: app,
      mod: mod,
      mix_mod: Macro.camelize(app),
      version: get_version(System.version())
    ]

    create_file("README.md", readme_template(assigns))
    create_file(".gitignore", gitignore_template(assigns))
    create_file("mix.exs", mix_exs_template(assigns))

    create_directory("config")
    create_file("config/config.exs", config_template(assigns))

    create_directory("src")
    create_file("src/#{app}.lfe", src_template(assigns))

    create_directory("test")
    create_file("test/#{app}-tests.lfe", test_template(assigns))

    if opts[:setup] do
      Mix.Shell.cmd("mix deps.get", fn output -> IO.write(output) end)
      Mix.Shell.cmd("mix local.rebar --force", fn output -> IO.write(output) end)

      local_rebar = Mix.Rebar.local_rebar_path(:rebar3)

      File.cd!(Path.join("deps", "lfe"), fn ->
        Mix.Shell.cmd("#{local_rebar} compile", fn output -> IO.write(output) end)
      end)
    end

    """
    Your LFE Mix project was created successfully.
    You can use "mix" to compile it, test it, and more:

        #{cd_path(path)}mix lfe.test

    Run "mix help" for more commands.
    """
    |> String.trim_trailing()
    |> Mix.shell().info()
  end

  defp get_version(version) do
    {:ok, version} = Version.parse(version)

    "#{version.major}.#{version.minor}" <>
      case version.pre do
        [h | _] -> "-#{h}"
        [] -> ""
      end
  end

  defp cd_path("."), do: ""
  defp cd_path(path), do: "cd #{path}\n    "

  embed_template(:readme, """
  # <%= @mod %>

  **TODO: Add description**

  <%= if @app do %>

  ## Installation

  If [available in Hex](https://hex.pm/docs/publish), the package can be installed
  by adding `<%= @app %>` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:<%= @app %>, "~> 0.1.0"}
    ]
  end
  ```
  <% end %>
  """)

  embed_template(:gitignore, """
  # The directory Mix will write compiled artifacts to.
  /_build/

  # The directory Mix downloads your dependencies sources to.
  /deps/

  # Where 3rd-party dependencies like ExDoc output generated docs.
  /doc/

  # Ignore .fetch files in case you like to edit your project deps locally.
  /.fetch

  # If the VM crashes, it generates a dump, let's ignore it too.
  erl_crash.dump

  # Also ignore archive artifacts (built via "mix archive.build").
  *.ez

  <%= if @app do %>
  # Ignore package tarball (built via "mix hex.build").
  <%= @app %>-*.tar
  <% end %>
  """)

  embed_template(:mix_exs, """
  defmodule <%= @mix_mod %>.MixProject do
    use Mix.Project

    def project do
      [
        app: :<%= @app %>,
        version: "0.1.0",
        language: :erlang,
        start_permanent: Mix.env() == :prod,
        compilers: Mix.compilers() ++ [:lfe],
        deps: deps()
      ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
      [
        extra_applications: []
      ]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
      [
        {:mix_lfe, "0.2.0-rc2", only: [:dev, :test]}
      ]
    end
  end
  """)

  embed_template(:config, ~S"""
  # This file is responsible for configuring your application
  # and its dependencies with the aid of the Mix.Config module.
  use Mix.Config

  # This configuration is loaded before any dependency and is restricted
  # to this project. If another project depends on this project, this
  # file won't be loaded nor affect the parent project. For this reason,
  # if you want to provide default values for your application for
  # 3rd-party users, it should be done in your "mix.exs" file.
  # You can configure your application as:
  #
  #     config :<%= @app %>, key: :value
  #
  # and access this configuration in your application as:
  #
  #     Application.get_env(:<%= @app %>, :key)
  #
  # You can also configure a 3rd-party app:
  #
  #     config :logger, level: :info
  #
  # It is also possible to import configuration files, relative to this
  # directory. For example, you can emulate configuration per environment
  # by uncommenting the line below and defining dev.exs, test.exs and such.
  # Configuration from the imported file will override the ones defined
  # here (which is why it is important to import them last).
  #
  #     import_config "#{Mix.env()}.exs"
  """)

  embed_template(:src, """
  ;; Documentation for the module.
  (defmodule <%= @mod %>
    (export (example_square 1)))

  ;; Documentation for the `example_square` function.
  (defun example_square (x) (* x x))
  """)

  embed_template(:test, """
  (defmodule <%= @mod %>-tests
    (behaviour ltest-unit)
    (export all)
    (import
      (from ltest
        (check-failed-assert 2)
        (check-wrong-assert-exception 2))))

  (include-lib "./deps/ltest/include/ltest-macros.lfe")

  (deftest example_square-test
    (is-equal 64 (<%= @mod %>:example_square 8)))
  """)
end
