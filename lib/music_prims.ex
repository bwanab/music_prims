defmodule MusicPrims do
  require Logger

  @type key :: atom
  @type note :: {key, integer}
  @type note_sequence :: keyword(integer)
  @type scale :: note_sequence
  @type chord :: note_sequence

  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]
  @normal_flat [:G!, :D!, :A!, :F, :Gb, :Db, :Ab, :Eb, :Bb] |> MapSet.new
  @flats [:Gb, :Db, :Ab, :Eb, :Bb] |> MapSet.new

  @flat_key_map Enum.zip(@circle_of_fifths, @flat_circle_of_fifths) |> Enum.into(%{})
  @normal_flat_key_map @flat_key_map |> Map.merge(%{:F! => :F!, :C! => :C!})
  @sharp_key_map Enum.zip(@flat_circle_of_fifths, @circle_of_fifths) |> Enum.into(%{})

  @circle_of_fourths [:C] ++ Enum.reverse(Enum.drop(@circle_of_fifths, 1))

  # scale intervals
  @pent_intervals [0, 3, 5, 7, 10]
  @blues_intervals [0, 3, 5, 6, 7, 10]
  @major_intervals [0, 2, 4, 5, 7, 9, 11]
  @modes [major: 0, dorian: 1, phrygian: 2, lydian: 3, mixolodian: 4, minor: 5,lociran: 6]
  @scale_intervals Enum.into(Enum.zip(@modes, @major_intervals), %{})
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @flat_notes [:C, :Db, :D, :Eb, :E, :F, :Gb, :G, :Ab, :A, :Bb, :B]
  @sharp_midi_notes Enum.with_index(@notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @flat_midi_notes Enum.with_index(@flat_notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @midi_notes @sharp_midi_notes ++ @flat_midi_notes

  @notes_by_midi Enum.into(Enum.map(@midi_notes, fn {note, midi} -> {midi, note} end), %{})
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

  @spec key(:major | :minor, integer, :sharps | :flats) :: atom
  def key(mode, n_accidentals, which) when mode == :major and which == :sharps do
    Enum.at(@circle_of_fifths, n_accidentals) |> map_by_sharp_key
  end
  def key(mode, n_accidentals, which) when mode == :major and which == :flats do
    Enum.at(@circle_of_fourths, n_accidentals)  |> map_by_sharp_key
  end
  def key(mode, n_accidentals, which) when mode == :minor and which == :sharps do
    Enum.at(@circle_of_fifths, n_accidentals+3)  |> map_by_sharp_key
  end
  def key(mode, n_accidentals, which) when mode == :minor and which == :flats do
    Enum.at(@circle_of_fourths, n_accidentals+3)  |> map_by_sharp_key
  end

  @spec circle_of_5ths() :: [atom]
  def circle_of_5ths() do @circle_of_fifths end

  @spec circle_of_4ths() :: [atom]
  def circle_of_4ths() do @circle_of_fourths end

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
    key = map_by_flat_key(key)
    index = Enum.find_index(circle, fn x -> x == key end) + 1
    new_key = Enum.at(circle, if index >= length(circle) do 0 else index end)
    octave_up = if gt(key, new_key) do 1 else 0 end
    {map_by_sharp_key(new_key, :normal), octave + octave_up}
    end

  @spec next_fifth({atom, integer}) :: {atom, integer}
  def next_fifth({key, octave}) do
    next_nth({key, octave}, @circle_of_fifths)
  end

  @spec next_fourth({atom, integer}) :: {atom, integer}
  def next_fourth({key, octave}) do
    next_nth({key, octave}, @circle_of_fourths)
  end

  @spec next_half_step({atom, integer}) :: {atom, integer}
  def next_half_step({key, octave}) do
    next_nth({key, octave}, @notes)
  end

  @spec rotate([integer], integer) :: [integer]
  def rotate(intervals, by) do
    Enum.drop(intervals, by) ++ (Enum.take(intervals, by) |> Enum.map(&(&1 + 12)))
  end

  @spec rotate_zero([integer], integer) :: [integer]
  def rotate_zero(intervals, by) do
    [f|r] = rotate(intervals, by)
    [0|Enum.map(r, &(&1 - f))]
  end

  @spec rotate_notes([note], integer) :: [note]
  def rotate_notes(notes, by) do
    Enum.drop(notes, by) ++ (Enum.take(notes, by) |> Enum.map(fn {n, o} -> {n, o + 1} end))
  end

  @spec rotate_octave(note_sequence, integer) :: note_sequence
  def rotate_octave([f|rest], by) when is_tuple(f) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn {note, midi} -> {note, midi + 12} end)
  end
  def rotate_octave([f|rest], by) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn midi -> midi + 12 end)
  end

  @spec rotate_octave_around(note_sequence, atom) :: note_sequence
  def rotate_octave_around([f|rest], key) when is_tuple(f) do
    scale = [f|rest]
    rotate_octave(scale, Enum.find_index(scale, fn {note, _} -> note == key end))
  end

  @spec to_midi(note) :: integer
  def to_midi({n, o}) do
    @midi_notes_map[n] + o * 12
  end

  @spec to_midi(note_sequence) :: [integer]
  def to_midi(notes) do
    Enum.map(notes, fn n -> to_midi(n) end)
  end

  @spec chromatic_scale(note) :: scale
  def chromatic_scale(note) do
    Stream.iterate(note, fn a -> next_half_step(a) end) |> Enum.take(12)
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

  @spec raw_scale(scale, [integer]) :: scale
  def raw_scale(chromatic_scale, intervals) do
    Enum.map(intervals, fn interval ->
      if interval < 12 do
        Enum.at(chromatic_scale, interval)
      else
        Enum.at(chromatic_scale, interval - 12)
        |> octave_up
      end
    end)
  end

  @spec key_from_note(note | key) :: key
  def key_from_note(n) when is_atom(n) do n end
  def key_from_note({key, _o}) do
    key
  end

  @spec map_by_key(note_sequence, key) :: note_sequence
  def map_by_key(seq, key) do
    if MapSet.member?(@normal_flat, key_from_note(key)) do
      Enum.map(seq, fn a -> map_by_sharp_key(a) end)
    else
      seq
    end
  end

  @spec map_by_sharp_key(note | key, atom) :: note | key
  def map_by_sharp_key(nk, context \\ :normal) do
    key_map = if context == :normal do @normal_flat_key_map else @flat_key_map end
    k = Map.get(key_map, key_from_note(nk))
    if is_tuple(nk) do {k, elem(nk, 1)} else k end
   end

  @spec map_by_flat_key(key) :: key
  def map_by_flat_key(key) do
    if MapSet.member?(@flats, key_from_note(key)) do
      Map.get(@sharp_key_map, key)
    else
      key
    end
  end

  @spec adjust_octave(scale, integer) :: scale
  def adjust_octave(scale, octave) when octave == 0 do scale end
  def adjust_octave(scale, octave) do
    Enum.map(scale, fn {note, midi} -> {note, midi + 12 * octave} end)
   end

  # def scale(key, mode \\ :major, octave \\ 0) do
  #   major_key(key, mode)
  #   |> build_note_seq(key, @major_intervals, octave)
  # end

  @spec major_intervals_map() :: %{integer => integer}
  def major_intervals_map() do
    Enum.with_index(@major_intervals)
    |> Enum.map(fn {interval, idx} -> {idx, interval} end)
    |> Enum.into(%{})
  end

  @spec major_scale(atom, integer) :: scale
  def major_scale(key, octave \\ 0) do
    build_note_seq(key, @major_intervals, octave)
  end

  @spec minor_scale(atom, integer) :: note_sequence
  def minor_scale(key, octave \\ 0) do
    build_note_seq(key, @major_intervals
    |> rotate_zero(@modes[:minor]) , octave)
  end

  @spec dorian_scale(atom, integer) :: note_sequence
  def dorian_scale(key, octave \\ 0) do
    build_note_seq(key, @major_intervals |> rotate_zero(@modes[:dorian]) , octave)
  end

  @spec blues_scale(atom, integer) :: note_sequence
  def blues_scale(key, octave \\ 0) do
    build_note_seq(key, @blues_intervals, octave)
  end

  @spec pent_scale(atom, integer) :: note_sequence
  def pent_scale(key, octave \\ 0) do
    build_note_seq(key, @pent_intervals, octave)
  end

  @spec build_note_seq(key, [integer], integer) :: note_sequence
  def build_note_seq(key, intervals, octave \\ 0) do
    skey = map_by_flat_key(key)
    chromatic_scale({skey, octave})
    |> raw_scale(intervals)
    |> map_by_key(skey)
  end

  @spec major_chord(atom, integer) :: note_sequence
  def major_chord(key, octave \\ 0) do
    build_note_seq(key, @major_triad, octave)
  end

  @spec minor_chord(atom, integer) :: note_sequence
  def minor_chord(key, octave \\ 0) do
    build_note_seq(key, @minor_triad, octave)
  end

  @spec augmented_chord(atom, integer) :: note_sequence
  def augmented_chord(key, octave \\ 0) do
    build_note_seq(key, @augmented_triad, octave)
  end

  @spec diminished_chord(atom, integer) :: note_sequence
  def diminished_chord(key, octave \\ 0) do
    build_note_seq(key, @diminished_triad, octave)
  end

  @spec dominant_seventh_chord(atom, integer) :: note_sequence
  def dominant_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @dominant_seventh, octave)
  end

  @spec major_seventh_chord(atom, integer) :: note_sequence
  def major_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @major_seventh, octave)
  end

  @spec minor_seventh_chord(atom, integer) :: note_sequence
  def minor_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @minor_seventh, octave)
  end

  @spec half_diminshed_seventh_chord(atom, integer) :: note_sequence
  def half_diminshed_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @half_diminshed_seventh, octave)
  end

  @spec diminished_seventh_chord(atom, integer) :: note_sequence
  def diminished_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @diminished_seventh, octave)
  end

  @spec minor_major_seventh_chord(atom, integer) :: note_sequence
  def minor_major_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @minor_major_seventh, octave)
  end

  @spec augmented_major_seventh_chord(atom, integer) :: note_sequence
  def augmented_major_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @augmented_major_seventh, octave)
  end

  @spec augmented_seventh_chord(atom, integer) :: note_sequence
  def augmented_seventh_chord(key, octave \\ 0) do
    build_note_seq(key, @augmented_seventh, octave)
  end

  @spec octave_up(note) :: note
  def octave_up({note, octave}) do
    {note, octave + 1}
  end

  @spec octave_up(note_sequence, integer) :: note_sequence
  def octave_up(chord, pos) do
    List.replace_at(chord, pos, Enum.at(chord, pos) |> octave_up)
  end

  @spec first_inversion(note_sequence) :: note_sequence
  def first_inversion(chord) do
    rotate_notes(chord, 1)
  end

  @spec second_inversion(note_sequence) :: note_sequence
  def second_inversion(chord) do
    rotate_notes(chord, 2)
  end

  @doc """
  Used with chords that are larger than triads.
  """
  @spec third_inversion(note_sequence) :: note_sequence
  def third_inversion(chord) do
    rotate_notes(chord, 3)
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
    Enum.map(0..num, fn x -> f.(key, x) end)
    |> List.flatten
    |> to_midi
  end

  @spec scale_notes([integer]) :: note_sequence
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

  def is_note({n, o}) do
    Enum.any?(circle_of_5ths(), &(&1 == n)) and is_integer(o)
  end

  def note_to_string({n, _o}) do
    inspect(n) |> String.replace("!", "#") |> String.replace(":", "")
  end


end
