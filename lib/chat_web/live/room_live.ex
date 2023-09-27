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
      <div id="chat-messages" phx-update="append" class="flex flex-grow flex-col gap-1 border rounded p-4">
        <div :for={message <- @messages} id={message.uuid}>
        <%!-- handle message.type = :system vs :user --%>
          <%= if message.type == :system do %>
            <p class="qitalic"><%= message.content %></p>
          <% else %>
            <p><strong><%= message.username %></strong>: <%= message.content %></p>
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
      <.input field={@chat[:message]} value={@message} type="textarea" label="Message" required />
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
