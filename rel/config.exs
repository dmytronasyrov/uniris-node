~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

erlang_cookie = :sha256
  |> :crypto.hash(System.get_env("ERLANG_COOKIE") || "/hdNA305fOYse3Rhak3qXn7CFJ/2zugbChgrnVm/M4HKRXGp0PDi7BFJpUaEaqaN")
  |> Base.encode16
  |> String.to_atom

use Distillery.Releases.Config,
    default_release: :server,
    default_environment: Mix.env()

release :server do
  set version: current_version(:uniris)
  set applications: [
    runtime_tools: :transient,
    sasl: :transient,
    logger: :transient,
    observer: :transient,
    wx: :transient,
    observer_cli: :permanent,
    uniris: :permanent
  ]
end

environment :dev do
  set dev_mode: false
  set include_erts: true
  set include_system_libs: true
  set include_src: false
  set cookie: erlang_cookie
  set vm_args: "rel/vm.args/stage.vm.args"
  set pre_configure_hooks: "rel/hooks/pre_configure.d"
  set overlays: [
    {:copy, "rel/dev_runtime_config.exs", "runtime_config.exs"}
  ]
  set config_providers: [
    {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/runtime_config.exs"]}
  ]
end

environment :prod do
  set dev_mode: false
  set include_erts: true
  set include_system_libs: true
  set include_src: true
  set cookie: erlang_cookie
  set vm_args: "rel/vm.args/prod.vm.args"
  set pre_configure_hooks: "rel/hooks/pre_configure.d"
  set overlays: [
    {:copy, "rel/main_runtime_config.exs", "runtime_config.exs"}
  ]
  set config_providers: [
    {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/runtime_config.exs"]}
  ]
end