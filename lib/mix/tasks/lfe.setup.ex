defmodule Mix.Tasks.Lfe.Setup do
  use Mix.Task

  @shortdoc "Downloads and sets up LFE for a LFE project"

  @moduledoc """
  A LFE project depend on the LFE compiler, which has to be downloaded and installed itself.
  This can be done either manually, by running `mix lfe.deps.setup` in the newly generatd project,
  or automatically by running this task in the project's root:

      mix lfe.setup
  """

  @doc """
  Runs this task.
  """
  def run(_) do
    Mix.Shell.cmd("mix deps.get", fn output -> IO.write(output) end)
    Mix.Shell.cmd("mix local.rebar --force", fn output -> IO.write(output) end)

    local_rebar = Mix.Rebar.local_rebar_path(:rebar3)

    File.cd!(Path.join("deps", "lfe"), fn ->
      Mix.Shell.cmd("#{local_rebar} compile", fn output -> IO.write(output) end)
    end)
  end
end
