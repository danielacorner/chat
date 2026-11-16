defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <p>Currently chatting in <strong><%= @room_id %></strong> as <strong><%= @username %></strong></p>

    <div
      id="chat-container"
      class="h-full flex flex-row flex-grow space-between gap-2 my-2"
    >
      <div id="chat-messages" phx-update="append" phx-hook="ScrollToBottom" class="flex flex-grow flex-col gap-1 border rounded p-2 overflow-y-auto min-w-0">
        <div :for={message <- @messages} id={message.uuid} class="message">
          <%= if message.type == :system do %>
            <p class="italic text-zinc-500 px-2 py-1"><%= message.content %></p>
          <% else %>
            <div class="group relative rounded-md px-2 py-1 hover:bg-zinc-100 transition-colors">
              <p class="message-username text-sm"><strong><%= message.username %></strong></p>
              <div class="message-content whitespace-pre-wrap break-words pr-8"><%= message.content %></div>
              <button
                type="button"
                data-copy-message
                title="Copy message"
                aria-label="Copy message"
                class="copy-button absolute top-1 right-1 flex items-center gap-1 rounded px-1.5 py-1 text-xs text-zinc-500 bg-white/80 ring-1 ring-zinc-200 opacity-0 group-hover:opacity-100 focus:opacity-100 hover:text-zinc-900 transition-opacity"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" /></svg>
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <div id="user-list">
        <h2 class="text-xl">Users online</h2>
        <ul>
          <li :for={username <- @user_list} id={username}>
            <%= username %>
          </li>
        </ul>
      </div>
    </div>
    <.simple_form for={@chat} phx-submit="save" phx-change="change" class="chat-form">
      <.input field={@chat[:message]} value={@message} type="textarea" label="Message (Enter to send, Shift+Enter for a new line)" required phx-hook="SubmitOnEnter" />
      <.button type="submit" phx-disable-with="Sending ...">Send</.button>
    </.simple_form>
    """
  end

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:#{room_id}"
    username = MnemonicSlugs.generate_slug(2)

    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, username, %{})
    end

    form =
      %{}
      # |> Post.changeset(%{})
      |> to_form(as: "chat")

    {:ok,
     assign(socket,
       room_id: room_id,
       message: "",
       chat: form,
       topic: topic,
       username: username,
       messages: [],
       user_list: [],
       temporary_assigns: [messages: []]
     )}
  end

  # @impl true
  # def handle_event("validate", _params, socket) do
  #   {:noreply, socket}
  # end

  @impl true
  def handle_event("save", %{"chat" => %{"message" => message}}, socket) do
    message = %{
      type: :user,
      uuid: UUID.uuid4(),
      content: message,
      username: socket.assigns.username
    }

    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("change", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{leaves: leaves, joins: joins}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined"}
      end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} left"}
      end)

    user_list =
      ChatWeb.Presence.list(socket.assigns.topic)
      |> Map.keys()

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end
end
