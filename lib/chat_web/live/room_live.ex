defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <p>Currently chatting in <strong><%= @room_id %></strong></p>

    <div
      id="chat-container"
      class="h-full flex flex-col flex-grow space-between gap-2 border rounded p-4 my-2"
    >
      <div id="chat-messages" phx-update="append" class="flex flex-grow flex-col gap-1">
        <div :for={message <- @messages} id={message.uuid}>
          <p ><%= message.content %></p>
        </div>
      </div>

      <.simple_form for={@chat} phx-change="validate" phx-submit="save">
        <.input field={@chat[:message]} type="textarea" label="Message" required />
        <.button type="submit" phx-disable-with="Sending ...">Send</.button>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:#{room_id}"
    ChatWeb.Endpoint.subscribe(topic)

    form =
      %{}
      # |> Post.changeset(%{})
      |> to_form(as: "chat")

    {:ok,
     assign(socket,
       room_id: room_id,
       chat: form,
       topic: topic,
       messages: [%{uuid: UUID.uuid4(), content: "Welcome to #{room_id}!"}],
       temporary_assigns: [messages: []]
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message}
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end
end
