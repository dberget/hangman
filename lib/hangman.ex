defmodule Hangman do
  alias Hangman.{GameServer, HangmanSupervisor, Api}

  defstruct [
    :user,
    :errors,
    :valid,
    :guess,
    :guesses,
    :correct_guesses,
    :word,
    :indexes,
    complete: false,
    correct: false
  ]

  @moduledoc """
  Main game context.
  """
  def start_game(game) do
    {:ok, _pid} = DynamicSupervisor.start_child(HangmanSupervisor, {GameServer, game})

    :ok
  end

  def set_word(_word, user) do
    %{word: word, definition: definition} = Api.get_word()

    {:ok, _word} = GameServer.new_word(word, definition, user)
  end

  def new_round(user), do: {:ok, _msg} = GameServer.new_round(user)
  def get_state(user), do: GameServer.get_state(user)

  def handle_guess(letter, user) do
    {:ok, %{word: word, guesses: guess_list}} = GameServer.get_state(user)

    %Hangman{user: user, guess: letter, guesses: guess_list, word: word}
    |> valid_guess?
    |> handle_save_guess
    |> check_complete
    |> handle_errors
    |> handle_response
  end

  def is_running_or_start(game) do
    case GameServer.game_running?(game) do
      nil ->
        start_game(game)

      pid ->
        {:ok, pid}
    end
  end

  defp valid_guess?(%Hangman{guesses: guess_list, guess: guess} = game_struct) do
    valid? = !Enum.member?(guess_list, guess) && String.valid?(guess) && String.length(guess) == 1

    %Hangman{game_struct | valid: valid?}
  end

  defp handle_save_guess(%Hangman{valid: false} = game_struct), do: game_struct

  defp handle_save_guess(game_struct) do
    game_struct
    |> guess_correct?()
    |> get_indexes()
    |> save_guess
  end

  defp check_complete(%Hangman{valid: false} = game_struct), do: game_struct

  defp check_complete(%Hangman{correct: false} = game_struct), do: game_struct

  defp check_complete(%Hangman{user: user} = game_struct) do
    {:ok, %{word: word, correct_guesses: guesses}} = GameServer.get_state(user)

    formatted_word_no_spaces =
      String.split(word, " ") |> Enum.join() |> String.split("", trim: true)

    complete? = formatted_word_no_spaces == guesses || formatted_word_no_spaces -- guesses === []

    if complete?, do: GameServer.complete(user)

    %Hangman{game_struct | complete: complete?}
  end

  defp guess_correct?(%Hangman{word: word, guess: guess} = game_struct) do
    %Hangman{game_struct | correct: Enum.member?(word_to_list(word), guess)}
  end

  defp save_guess(%Hangman{valid: false} = game_struct), do: game_struct

  defp save_guess(
         %Hangman{indexes: indexes, user: user, correct: true, guess: guess} = game_struct
       ) do
    Enum.each(indexes, &GameServer.correct_guess(%{value: guess, index: &1}, user))

    game_struct
  end

  defp save_guess(%Hangman{user: user, guess: guess, correct: false} = game_struct) do
    GameServer.wrong_guess(guess, user)

    game_struct
  end

  defp get_indexes(%Hangman{correct: false} = game_struct), do: game_struct

  defp get_indexes(%Hangman{word: word, guess: letter} = game_struct) do
    indexes =
      word |> word_to_list |> Enum.with_index() |> Enum.filter(&(elem(&1, 0) == letter))
      |> Enum.map(&elem(&1, 1))

    %Hangman{game_struct | indexes: indexes}
  end

  defp word_to_list(word) do
    String.split(word, "", trim: true)
  end

  defp handle_errors(%Hangman{errors: nil} = game_struct), do: game_struct
  defp handle_errors(%Hangman{errors: errors}), do: IO.inspect(errors)

  defp handle_response(%Hangman{user: slug}), do: get_state(slug)
end
