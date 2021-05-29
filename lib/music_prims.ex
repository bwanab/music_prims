defmodule MusicPrims do
  require Logger

  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @circle_of_fourths [:C] ++ Enum.reverse(Enum.drop(@circle_of_fifths, 1))

  # scale intervals
  @pent_intervals [0, 3, 5, 7, 10]
  @blues_intervals [0, 3, 5, 6, 7, 10]
  @major_intervals [0, 2, 4, 5, 7, 9, 11]
  @modes [:major, :dorian, :phrygian, :lydian, :mixolodian, :minor, :lociran]
  @scale_intervals Enum.into(Enum.zip(@modes, @major_intervals), %{})
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @midi_notes Enum.with_index(@notes) |> Enum.map(fn {a, b} -> {a, b+24} end)

  @notes_by_midi Enum.into(Enum.map(@midi_notes, fn {note, midi} -> {midi, note} end), %{})
  @midi_notes_map Enum.into(@midi_notes, %{})

  # chord intervals
  @major_triad [0, 4, 7]
  @minor_triad [0, 3, 7]
  @augmented_triad [0, 4, 8]
  @diminished_triad [0, 3, 6]

  @spec key(:major | :minor, integer, :sharps | :flats) :: atom
  def key(mode, n_accidentals, which) when mode == :major and which == :sharps do
    Enum.at(@circle_of_fifths, n_accidentals)
  end
  def key(mode, n_accidentals, which) when mode == :major and which == :flats do
    Enum.at(@circle_of_fourths, n_accidentals)
  end
  def key(mode, n_accidentals, which) when mode == :minor and which == :sharps do
    Enum.at(@circle_of_fifths, n_accidentals+3)
  end
  def key(mode, n_accidentals, which) when mode == :minor and which == :flats do
    Enum.at(@circle_of_fourths, n_accidentals+3)
  end

  @spec circle_of_5ths() :: [atom]
  def circle_of_5ths() do
    @circle_of_fifths
  end
  @spec circle_of_4ths() :: [atom]
  def circle_of_4ths() do
    @circle_of_fourths
  end

  @spec gt(atom, atom) :: boolean
  def gt(key1, key2) do
    # Logger.info("#{key1} #{@midi_notes_map[key1]} #{key2} #{@midi_notes_map[key2]}")
    @midi_notes_map[key1] > @midi_notes_map[key2]
  end

  @doc """
  Kind of arbitrary that the octave cutoff is always at C.
  """
  @spec next_nth({atom, integer}, [atom]) :: {atom, integer}
  def next_nth({key, octave}, circle) do
    index = Enum.find_index(circle, fn x -> x == key end) + 1
    new_key = Enum.at(circle, if index >= length(circle) do 0 else index end)
    octave_up = if gt(key, new_key) do 1 else 0 end
    {new_key, octave + octave_up}
    end

  @spec next_fifth({atom, integer}) :: {atom, integer}
  def next_fifth({key, octave}) do
    next_nth({key, octave}, @circle_of_fifths)
  end

  @spec next_fourth({atom, integer}) :: {atom, integer}
  def next_fourth({key, octave}) do
    next_nth({key, octave}, @circle_of_fourths)
  end

  @spec rotate(keyword(integer), integer) :: keyword(integer)
  def rotate(scale, by) do
    Enum.drop(scale, by) ++ Enum.take(scale, by)
  end

  @spec rotate_octave(keyword(integer), integer) :: keyword(integer)
  def rotate_octave([f|rest], by) when is_tuple(f) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn {note, midi} -> {note, midi + 12} end)
  end
  def rotate_octave([f|rest], by) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn midi -> midi + 12 end)
  end

  @spec rotate_octave_around(keyword(integer), atom) :: keyword(integer)
  def rotate_octave_around([f|rest], key) when is_tuple(f) do
    scale = [f|rest]
    rotate_octave(scale, Enum.find_index(scale, fn {note, _} -> note == key end))
  end

  @spec chromatic_scale(atom) :: keyword(integer)
  def chromatic_scale(key) do
    midi = @midi_notes_map[key]
    cmidi = @midi_notes_map[:C]
    interval = midi - cmidi
    rotate_octave(@midi_notes, interval)
  end

  # def scale_interval(scale, interval) do
  #   {note, _} = Enum.at(scale, interval)
  #   note
  # end

  @spec scale_interval(atom) :: integer
  def scale_interval(mode) do
    @scale_intervals[mode]
  end

  @spec note_map(atom) :: integer
  def note_map(note) do
    @midi_notes_map[note]
  end

  @doc """
  return the key for which notes for the given key and mode are the same.
  E.G. for :A, :minor, we would return :C since the notes of A-minor are the
  same as the notes in C major.
  """
  @spec major_key(atom, atom) :: atom
  def major_key(key, mode) do
    index = note_map(key) - scale_interval(mode)
    @notes_by_midi[if index >= 24 do index else index + 12 end]
  end

  @spec raw_scale(keyword(integer), [integer]) :: keyword(integer)
  def raw_scale(chromatic_scale, intervals) do
    Enum.map(intervals, fn interval -> Enum.at(chromatic_scale, interval) end)
  end

  @spec adjust_octave(keyword(integer), integer) :: keyword(integer)
  def adjust_octave(scale, octave) when octave == 0 do scale end
  def adjust_octave(scale, octave) do
    Enum.map(scale, fn {note, midi} -> {note, midi + 12 * octave} end)
  end

  def scale(key, mode \\ :major, octave \\ 0) do
    major_key(key, mode)
    |> build_scale(key, @major_intervals, octave)
  end

  @spec major_scale(atom, integer) :: keyword(integer)
  def major_scale(key, octave \\ 0) do
    scale(key, :major, octave)
  end

  @spec minor_scale(atom, integer) :: keyword(integer)
  def minor_scale(key, octave \\ 0) do
    scale(key, :minor, octave)
  end

  @spec dorian_scale(atom, integer) :: keyword(integer)
  def dorian_scale(key, octave \\ 0) do
    scale(key, :dorian, octave)
  end

  @spec blues_scale(atom, integer) :: keyword(integer)
  def blues_scale(key, octave \\ 0) do
    build_scale(key, key, @blues_intervals, octave)
  end

  @spec pent_scale(atom, integer) :: keyword(integer)
  def pent_scale(key, octave \\ 0) do
    build_scale(key, key, @pent_intervals, octave)
  end

  @spec build_scale(atom, atom, [integer], integer) :: keyword(integer)
  def build_scale(chrome_key, key, intervals, octave \\ 0) do
    chromatic_scale(chrome_key)
    |> raw_scale(intervals)
    |> rotate_octave_around(key)
    |> adjust_octave(octave)
  end

  @spec major_chord(atom, integer) :: keyword(integer)
  def major_chord(key, octave \\ 0) do
    build_scale(key, key, @major_triad, octave)
  end
  @spec minor_chord(atom, integer) :: keyword(integer)
  def minor_chord(key, octave \\ 0) do
    build_scale(key, key, @minor_triad, octave)
  end

  @spec octave_up(keyword(integer), integer) :: keyword(integer)
  def octave_up(chord, pos) do
    note = Enum.at(chord, pos)
    List.replace_at(chord, pos, {elem(note, 0), elem(note, 1) + 12})
  end

  @spec first_inversion(keyword(integer)) :: keyword(integer)
  def first_inversion(scale) do
    rotate(scale, 1)
    |> octave_up(2)
  end

  @spec second_inversion(keyword(integer)) :: keyword(integer)
  def second_inversion(scale) do
    rotate(scale, 2)
    |> octave_up(1)
    |> octave_up(2)
  end

  @doc """
  produces a sequence of midi notes for the given scale function(f) in the key
  with num octaves.

  Example:

  MusicPrims.scale_seq(:D, 4, &MusicPrims.pent_scale/2)
  [26, 29, 31, 33, 36, 38, 41, 43, 45, 48, 50, 53, 55, 57, 60, 62, 65, 67, 69, 72,
   74, 77, 79, 81, 84]

  """
  @spec scale_seq(atom, integer, fun) :: [integer]
  def scale_seq(key, num, f) do
    Enum.map(0..num, fn x -> Enum.map(f.(key, x), fn {_, m} -> m end) end)
    |> List.flatten
  end

  @spec scale_notes([integer]) :: keyword(integer)
  def scale_notes(intervals) do
    Enum.map(intervals, fn interval -> Enum.at(@midi_notes, interval) end)
  end

  @spec scale_notes_note([integer]) :: [atom]
  def scale_notes_note(scale) do
    Enum.map(scale_notes(scale), fn {note, _midi} -> note end)
  end

  @spec scale_notes_midi([integer]) :: [integer]
  def scale_notes_midi(scale) do
    Enum.map(scale_notes(scale), fn {_note, midi} -> midi end)
  end

end
