defmodule HangmanWeb.GameChannel do
  use HangmanWeb, :channel

  def join("game: " <> game_slug, _params, socket) do
    socket = assign(socket, :slug, game_slug)

    {:ok, socket}
  end

  def handle_in("new_guess", params, socket) do
    slug = socket.assigns[:slug]
    {:ok, msg} = Hangman.handle_guess(params["guess"], slug)

    {:reply, :ok, socket}
    broadcast!(socket, "new_guess", %{content: msg})
  end
end
