defmodule Uniris.Crypto.Supervisor do
  @moduledoc false
  use Supervisor

  alias Uniris.Crypto.Ed25519.LibSodiumPort

  alias Uniris.Crypto.Keystore
  alias Uniris.Crypto.KeystoreLoader

  alias Uniris.Utils

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: Uniris.CryptoSupervisor)
  end

  def init(_) do
    seed = Uniris.Crypto.get_crypto_seed()
    load_storage_nonce()

    optional_children = [
      {Keystore, [seed: seed]},
      KeystoreLoader
    ]
    children = [LibSodiumPort | Utils.configurable_children(optional_children)]
    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp load_storage_nonce do
    rel_filepath = Application.get_env(:uniris, Uniris.Crypto)[:storage_nonce_file]
    abs_filepath = Application.app_dir(:uniris, rel_filepath)

    case File.read(abs_filepath) do
      {:ok, storage_nonce} -> :persistent_term.put(:storage_nonce, storage_nonce)
      _ -> :ok
    end
  end
end
