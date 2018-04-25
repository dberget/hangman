defmodule Hangman.GameServer do
  use GenServer

  # client api
  def start_link(host) do
    GenServer.start_link(
      __MODULE__,
      %{host: host, word: [], guesses: [], correct_guesses: [], complete: false},
      name: via_tuple(host.id)
    )
  end

  def new_word(word, host) do
    GenServer.call(via_tuple(host.id), {:new_word, word})
  end

  def correct_guess(letter, host) do
    GenServer.call(via_tuple(host.id), {:correct_guess, letter})
  end

  def wrong_guess(letter, host) do
    GenServer.call(via_tuple(host.id), {:wrong_guess, letter})
  end

  def complete(host) do
    GenServer.call(via_tuple(host.id), {:complete})
  end

  def get_state(host) do
    GenServer.call(via_tuple(host.id), {:get_state})
  end

  defp via_tuple(host_id) do
    {:via, Registry, {:hangman_server, host_id}}
  end

  ## Server Callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_call({:new_word, word}, _from, state) do
    new_state = %{state | word: word}

    {:reply, {:ok, word}, new_state}
  end

  def handle_call({:correct_guess, letter}, _from, state) do
    correct_guesses = List.insert_at(state.correct_guesses, letter.index, letter.value)

    new_state = %{
      state
      | guesses: [letter.value | state.guesses],
        correct_guesses: correct_guesses
    }

    {:reply, {:correct, letter}, new_state}
  end

  def handle_call({:wrong_guess, letter}, _from, state) do
    new_state = %{state | guesses: [letter | state.guesses]}

    {:reply, {:wrong, letter}, new_state}
  end

  def handle_call({:complete}, _from, state) do
    new_state = %{state | complete: true}

    {:reply, {:complete, state.word}, new_state}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, {:ok, state}, state}
  end
end