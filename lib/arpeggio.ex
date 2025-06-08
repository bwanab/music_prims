defmodule Arpeggio do
  @moduledoc """
  Represents an arpeggio as a sequence of notes played in a specific pattern.

  An arpeggio will be defined as a chord with the addition of a pattern and a duration.
  This module provides functions for creating, modifying, and analyzing arpeggios.

  The pattern will be either a pattern type from this list:
  - :up
  - :down
  - :up_down
  - :down_up
  - :explicit

  The explicit pattern will be a list of integers that represent the note indices to play.
  The duration will be a float that represents the duration of the arpeggio in the same units
  of time as the duration of a note as defined in the Note module.

  Like Note, Chord and Rest, Arpeggio will implement the Sonority protocol.
  """

  @type pattern :: :up | :down | :up_down | :down_up | [integer()]

  @type t :: %__MODULE__{
    chord: Chord.t(),
    pattern: pattern(),
    duration: number(),
    channel: Integer
  }

  defstruct [:chord, :pattern, :duration, :channel]

  # def arpeggiate(notes, pattern) do
  #   case pattern do
  #     :up -> Enum.with_index(notes) |> Enum.map(fn {_note, index} -> notes[index] end)
  #     :down -> Enum.with_index(notes) |> Enum.map(fn {note, index} -> notes[notes |> length - index - 1] end)
  #     :up_down -> Enum.with_index(notes) |> Enum.map(fn {note, index} -> if rem(index, 2) == 0 do notes[index] else notes[notes |> length - index - 1] end end)
  #     :down_up -> Enum.with_index(notes) |> Enum.map(fn {note, index} -> if rem(index, 2) == 0 do notes[notes |> length - index - 1] else notes[index] end end)
  #     :explicit -> Enum.with_index(notes) |> Enum.map(fn {note, index} -> notes[pattern[index]] end)
  #   end
  # end

  # def arpeggiate(notes, pattern, duration) do
  #   notes
  #   |> Arpeggio.arpeggiate(pattern)
  #   |> Arpeggio.new(duration)
  # end

  def new(chord, pattern, duration) do
    %Arpeggio{chord: chord, pattern: pattern, duration: duration}
  end


  def repeat(arpeggio, times) do
    Enum.reduce(1..times, [], fn _n,l -> l ++ Sonority.to_notes(arpeggio) end)
  end

  defimpl Sonority do
    def duration(arpeggio), do: arpeggio.duration
    def type(_), do: :arpeggio

    @spec show(Arpeggio.t(), keyword()) :: String.t()
    def show(arpeggio, _opts \\ []) do
      Enum.map(Sonority.to_notes(arpeggio), fn n -> Sonority.show(n) end) |> Enum.join(" ")
    end

    def to_notes(arpeggio) when is_list(arpeggio.pattern) do
      to_notes(arpeggio, arpeggio.pattern)
    end

    def to_notes(arpeggio) when is_atom(arpeggio.pattern) do
      length = arpeggio.chord.notes |> length
      pattern = case arpeggio.pattern do
                  :up -> Enum.to_list(1..length)
                  :down -> Enum.to_list(length..1//-1)
                  :up_down -> Enum.to_list(1..length) ++ Enum.to_list(length-1..1//-1)
                  :down_up -> Enum.to_list(length..1//-1) ++ Enum.to_list(2..length)
                end
      to_notes(arpeggio, pattern)
    end

    defp to_notes(arpeggio, pattern) do
      notes = Sonority.to_notes(arpeggio.chord) |> Enum.map(fn n -> Note.copy(n, duration: arpeggio.duration) end)
      Enum.map(pattern, fn p -> Enum.at(notes, p - 1) end)
    end

    def channel(arpeggio) do
      arpeggio.chord.channel
    end

  end


end
