defmodule ChatWeb.PageLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <.button phx-click="random_room" phx-value-room="random_room">Create a Random Room</.button>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
      {:ok, assign(socket, query: "", results: %{})}
  end

  @impl true
  def handle_event("random_room", _params, socket) do
    random_slug = "/" <> MnemonicSlugs.generate_slug(2)
    Logger.info(random_slug)
    Logger.info("click!")
    {:noreply, push_redirect(socket, to: random_slug)}
  end

end
