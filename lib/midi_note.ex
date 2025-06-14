defmodule MidiNote do
  @moduledoc """
  Module for handling MIDI note representations and conversions.
  """

  @type t :: %__MODULE__{
    note_number: integer,
    duration: number | nil,
    velocity: integer,
    channel: integer
  }

  defstruct [:note_number, :duration,  :velocity, :channel]


  # Notes and MIDI mapping - reused from Note module
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @sharp_midi_notes Enum.with_index(@notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @flat_notes [:C, :Db, :D, :Eb, :E, :F, :Gb, :G, :Ab, :A, :Bb, :B]
  @flat_midi_notes Enum.with_index(@flat_notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @midi_notes @sharp_midi_notes ++ @flat_midi_notes
  @midi_notes_map Enum.into(@midi_notes, %{})

  @doc """
  Get the MIDI note map
  """
  @spec note_map(atom()) :: integer()
  def note_map(note), do: @midi_notes_map[note]


  @doc """
  Convert a note to its MIDI note number, duration, and velocity.
  """
  @spec note_to_midi(Note.t) :: t
  def note_to_midi(%Note{note: key, octave: octave, duration: duration, velocity: velocity, channel: channel}) do
    %__MODULE__{
      note_number: @midi_notes_map[key] + (octave * 12),
      duration: duration,
      velocity: velocity || 100,
      channel: channel || 0
    }
  end

  def get_duration(number_of_quarter_notes) do
    cond do
        number_of_quarter_notes == 0 -> 0
        number_of_quarter_notes == 4 -> 1
        within_percent?(number_of_quarter_notes, 0.375, 0.05) -> -16
        within_percent?(number_of_quarter_notes, 0.75, 0.05) -> -8
        within_percent?(number_of_quarter_notes, 1.5, 0.05) -> -4
        within_percent?(number_of_quarter_notes, 3, 0.05) -> -2
        true -> closest_power_of_two(floor(4 / number_of_quarter_notes))
    end
  end

  def get_lily_duration(num_quarter_notes, time_sig_denominator \\ 4) do
    num_whole_notes = floor(num_quarter_notes / time_sig_denominator)
    rem = num_quarter_notes - time_sig_denominator * num_whole_notes
    rem_dur = get_duration(rem)
    cond do
      num_whole_notes == 0 ->
        if rem_dur < 0 do
          "#{floor(-rem_dur)}."
        else
          "#{floor(rem_dur)}"
        end
      true ->
        cond do
          rem_dur < 0 ->
            "#{floor(time_sig_denominator * 2)}*#{floor(num_quarter_notes * 2)}"
          rem_dur == 0 and num_whole_notes == 1 ->
            "1"
          rem_dur == 0 ->
            "1*#{num_whole_notes}"
          true ->
            "#{time_sig_denominator}*#{floor(num_quarter_notes)}"
        end
    end
  end



  def midi_to_note(%__MODULE__{note_number: note_number, duration: duration, velocity: velocity, channel: channel}) do
    midi_to_note(note_number, duration, velocity, channel)
  end

  @doc """
  Convert a MIDI note number to a Note struct.
  """
  @spec midi_to_note(integer, number | nil, integer | nil, integer) :: Note.t
  def midi_to_note(note_number, number_of_quarter_notes, velocity \\ 100, channel \\ 0) do
    octave = div(note_number - 12, 12)
    key_index = rem(note_number - 12, 12)
    key = Enum.at(@notes, key_index)
    Note.new(key, octave: octave, duration: number_of_quarter_notes, velocity: velocity, channel: channel)
  end

  @doc """
  Convert a note or list of notes to MIDI value(s).
  """
  @spec to_midi(Note.t() | [Note.t()]) :: integer() | [integer()]
  def to_midi(%Note{note: key, octave: octave}) do
    @midi_notes_map[key] + (octave * 12)
  end
  def to_midi(notes) when is_list(notes), do: Enum.map(notes, &to_midi/1)

  def closest_power_of_two(num) when is_number(num) and num > 0 do
    # Calculate the power using logarithm base 2
    power = :math.log2(num) |> round()

    # Return 2 raised to that power
    :math.pow(2, power) |> round()
  end

  def within_percent?(number, target, percent) when is_number(number) and is_number(target) and is_number(percent) do
    lower_bound = target * (1 - percent)
    upper_bound = target * (1 + percent)

    number >= lower_bound and number <= upper_bound
  end


end
