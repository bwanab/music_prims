defmodule MusicPrims do
  require Logger

  @moduledoc """
  Functions for working with musical primitives.
  """

  @type key :: atom()
  @type rest :: atom()
#  @type note :: Note.t()
#  @type note_sequence :: [note]
  # @type chord :: note_sequence

  # Scale intervals
  #@modes [major: 0, dorian: 1, phrygian: 2, lydian: 3, mixolodian: 4, minor: 5, locrian: 6]

  # Circle of fifths and key mapping
  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]
  #@normal_flat [:G!, :D!, :A!, :F, :Gb, :Db, :Ab, :Eb, :Bb]
  #@flats [:Gb, :Db, :Ab, :Eb, :Bb]

  @circle_of_fourths [:C] ++ Enum.reverse(Enum.drop(@circle_of_fifths, 1))

  # Notes and MIDI mapping
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @flat_notes [:C, :Db, :D, :Eb, :E, :F, :Gb, :G, :Ab, :A, :Bb, :B]
  @sharp_midi_notes Enum.with_index(@notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @flat_midi_notes Enum.with_index(@flat_notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @midi_notes @sharp_midi_notes ++ @flat_midi_notes

  @midi_notes_map Enum.into(@midi_notes, %{})

  # interesting intervals
  @minor_7th 10
  @major_7th 11
  @diminished_7th 9

  # chord intervals
  @major_triad [0, 4, 7]
  @minor_triad [0, 3, 7]
  @augmented_triad [0, 4, 8]
  @diminished_triad [0, 3, 6]

  @dominant_seventh @major_triad ++ [@minor_7th]
  @major_seventh @major_triad ++ [@major_7th]
  @minor_seventh @minor_triad ++ [@minor_7th]
  @half_diminshed_seventh @diminished_triad ++ [@minor_7th]
  @diminished_seventh @diminished_triad ++ [@diminished_7th]
  @minor_major_seventh @minor_triad ++ [@major_7th]
  @augmented_major_seventh @augmented_triad ++ [@major_7th]
  @augmented_seventh @augmented_triad ++ [@minor_7th]

  def chord_interval_map do
    %{
    @major_triad => :major,
    @minor_triad => :minor,
    @augmented_triad => :augmented,
    @diminished_triad => :diminished,
    @dominant_seventh => :dominant_seventh,
    @major_seventh => :major_seventh,
    @minor_seventh => :minor_seventh,
    @half_diminshed_seventh => :half_diminshed_seventh,
    @diminished_seventh => :diminished_seventh,
    @minor_major_seventh => :minor_major_seventh,
    @augmented_major_seventh => :augmented_major_seventh,
    @augmented_seventh => :augmented_seventh,
    }
  end

  def midi_notes do
    @midi_notes
  end

  @spec key(:major | :minor, integer, :sharps | :flats) :: atom
  def key(mode, n_accidentals, which) when mode == :major and which == :sharps do
    Enum.at(@circle_of_fifths, n_accidentals) |> map_by_sharp_key
  end
  def key(mode, n_accidentals, which) when mode == :major and which == :flats do
    Enum.at(@circle_of_fourths, n_accidentals)  |> map_by_sharp_key(:flat)
  end
  def key(mode, n_accidentals, which) when mode == :minor and which == :sharps do
    Enum.at(@circle_of_fifths, n_accidentals+3)  |> map_by_sharp_key
  end
  def key(mode, n_accidentals, which) when mode == :minor and which == :flats do
    Enum.at(@circle_of_fourths, n_accidentals+3)  |> map_by_sharp_key(:flat)
  end

  @spec circle_of_5ths() :: [atom]
  def circle_of_5ths() do @flat_circle_of_fifths end

  @spec circle_of_4ths() :: [atom]
  def circle_of_4ths() do @circle_of_fourths end

  @spec gt(atom, atom) :: boolean
  def gt(key1, key2) do
    @midi_notes_map[key1] > @midi_notes_map[key2]
  end

  # Delegate note operations to Note module
  #defdelegate next_fifth(note), to: Note
  #defdelegate next_fourth(note), to: Note
  #defdelegate next_half_step(note), to: Note
  #defdelegate next_nth(note, circle), to: Note
  defdelegate map_by_sharp_key(note_or_key, context \\ :normal), to: Note
  defdelegate map_by_flat_key(note), to: Note

end
