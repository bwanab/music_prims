defmodule MusicPrims do
  require Logger

  @type key :: atom()
  @type rest :: atom()
  @type note_sequence :: [Note.t()]
  @type scale :: note_sequence
  # @type chord :: note_sequence

  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]
  @normal_flat [:G!, :D!, :A!, :F, :Gb, :Db, :Ab, :Eb, :Bb]
  @flats [:Gb, :Db, :Ab, :Eb, :Bb]

  @flat_key_map Enum.zip(@circle_of_fifths, @flat_circle_of_fifths) |> Enum.into(%{})
  @normal_flat_key_map @flat_key_map |> Map.merge(%{:F! => :F!, :C! => :C!})
  @sharp_key_map Enum.zip(@flat_circle_of_fifths, @circle_of_fifths) |> Enum.into(%{})

  @circle_of_fourths [:C] ++ Enum.reverse(Enum.drop(@circle_of_fifths, 1))

  # scale intervals
  @pent_intervals [0, 3, 5, 7, 10]
  @blues_intervals [0, 3, 5, 6, 7, 10]
  @major_intervals [0, 2, 4, 5, 7, 9, 11]
  @modes [major: 0, dorian: 1, phrygian: 2, lydian: 3, mixolodian: 4, minor: 5, locrian: 6]
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
    # Logger.info("#{key1} #{@midi_notes_map[key1]} #{key2} #{@midi_notes_map[key2]}")
    @midi_notes_map[key1] > @midi_notes_map[key2]
  end

  @doc """
  Kind of arbitrary that the octave cutoff is always at C.
  """
  @spec next_nth(Note.t(), [atom]) :: Note.t()
  def next_nth(%Note{note: {key, octave}}, circle) do
    key = map_by_flat_key(key)
    index = Enum.find_index(circle, fn x -> x == key end) + 1
    new_key = Enum.at(circle, if index >= length(circle) do 0 else index end)
    octave_up = if gt(key, new_key) do 1 else 0 end
    Note.new({map_by_sharp_key(new_key, :normal), octave + octave_up})
  end

  @spec next_fifth(Note.t()) :: Note.t()
  def next_fifth(%Note{} = note) do
    next_nth(note, @circle_of_fifths)
  end

  @spec next_fourth(Note.t()) :: Note.t()
  def next_fourth(%Note{} = note) do
    next_nth(note, @circle_of_fourths)
  end

  @spec next_half_step(Note.t()) :: Note.t()
  def next_half_step(%Note{} = note) do
    next_nth(note, @notes)
  end

  @doc """
  Rotate a list of integers by the given amount.
  E.G. rotate([0, 2, 4, 5, 7, 9, 11], 1) will return [2, 4, 5, 7, 9, 11, 12]
  """
  @spec rotate([integer], integer) :: [integer]
  def rotate(intervals, by) do
    Enum.drop(intervals, by) ++ (Enum.take(intervals, by) |> Enum.map(&(&1 + 12)))
  end

  @doc """
  Rotate a list of integers by the given amount and return the result with the first element set to 0.
  E.G. rotate_zero([0, 2, 4, 5, 7, 9, 11], 1) will return [0, 2, 4, 5, 7, 9, 11]
  """
  @spec rotate_zero([integer], integer) :: [integer]
  def rotate_zero(intervals, by) do
    [f|r] = rotate(intervals, by)
    [0|Enum.map(r, &(&1 - f))]
  end

  @doc """
  Rotate a list of notes by the given amount. Thus, the degree of
  rotation is the mode
  E.G. rotate_notes(major_scale(:C, 4), 5) will return scale of A minor
  E.G. rotate_notes(major_scale(:C, 4), @modes[:dorian]) will return dorian scale of C
  """
  @spec rotate_notes([Note.t()], integer) :: [Note.t()]
  def rotate_notes(notes, n) do
    {l, r} = Enum.split(notes, n)
    r ++ Enum.map(l, fn
      %Note{note: {key, octave}} -> Note.new({key, octave + 1})
      {key, octave} -> Note.new({key, octave + 1})
    end)
  end

  @spec rotate_any([any], integer) :: [any]
  def rotate_any(l, by) do
    Enum.drop(l, by) ++ Enum.take(l, by)
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
  def rotate_octave_around([f|rest], key) do
    scale = [f|rest]
    rotate_octave(scale, Enum.find_index(scale, fn note -> note == key end))
  end

  @spec to_midi(Note.t() | note_sequence | [note_sequence]) :: integer | [integer] | [[integer]]
  def to_midi(%Note{note: {n, o}, velocity: _velocity}) do
    @midi_notes_map[n] + o * 12
  end

  def to_midi({n, o}) do
    @midi_notes_map[n] + o * 12
  end

  def to_midi([notes] = note_seq) when is_list(notes) do
    Enum.map(note_seq, fn n -> to_midi(n) end)
  end

  def to_midi(notes) do
    Enum.map(notes, fn n -> to_midi(n) end)
  end


  @spec chromatic_scale(Note.t() | {atom, integer}) :: [Note.t()]
  def chromatic_scale(%Note{} = note) do
    Stream.iterate(note, fn a -> next_half_step(a) end) |> Enum.take(12)
  end

  def chromatic_scale({key, octave}) do
    chromatic_scale(Note.new({key, octave}))
  end

  @doc """
  Get the scale intervals for the given mode.
  """
  @spec scale_interval(atom) :: [integer]
  def scale_interval(mode) do
    mode_num = @modes[mode]
    @major_intervals |> rotate_zero(mode_num)
  end

  @spec note_map(atom) :: integer
  def note_map(note) do
    @midi_notes_map[note]
  end

  @doc """
  return the key for which notes for the given key and mode are the same.
  E.G. for :A, :minor, :major, we would return :C since the notes of A-minor are the
  same as the notes in C major.
       for :D :dorian, :major we would return :C
       for :D :dorian, :minor we would return :A
  """
  @spec equivalent_key(atom, atom, atom) :: atom
  def equivalent_key(key, key_mode, equivlent_mode) do
    index = @modes[equivlent_mode] - @modes[key_mode]
    {rkey, _} = Enum.at(modal_scale(key, 0, key_mode), index).note
    rkey
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

  @spec key_from_note(Note.t() | key) :: key
  def key_from_note(n) when is_atom(n) do n end
  def key_from_note(%Note{note: {key, _o}}) do
    key
  end

  @spec normal_flat() :: MapSet.t
  def normal_flat do MapSet.new(@normal_flat) end

  @spec flats() :: MapSet.t
  def flats do MapSet.new(@flats) end

  @spec map_by_key(note_sequence, key) :: note_sequence
  def map_by_key(seq, key) do
    if MapSet.member?(normal_flat(), key_from_note(key)) do
      Enum.map(seq, fn a -> map_by_sharp_key(a) end)
    else
      Enum.map(seq, fn a -> map_by_flat_key(a) end)
    end
   end

  @doc """
  Map a note or key to its flat equivalent if it is a sharp key.
  """
  @spec map_by_sharp_key(Note.t() | key, atom) :: Note.t() | key
  def map_by_sharp_key(value, context \\ :normal)

  def map_by_sharp_key(%Note{note: {key, octave}} = note, context) do
    mapped_key = map_by_sharp_key(key, context)
    %{note | note: {mapped_key, octave}}
  end

  def map_by_sharp_key(nk, context) do
    key_map = if context == :normal do @normal_flat_key_map else @flat_key_map end
    k = case Map.get(key_map, key_from_note(nk)) do
          nil -> key_from_note(nk)
          val -> val
        end
    if is_tuple(nk) do Note.new({k, elem(nk, 1)}) else k end
  end

  @doc """
  Map a note or key to its sharp equivalent if it is a flat key.
  """
  @spec map_by_flat_key(Note.t() | key) :: Note.t() | key
  def map_by_flat_key(%Note{note: {key, octave}} = note) do
    mapped_key = map_by_flat_key(key)
    %{note | note: {mapped_key, octave}}
  end

  def map_by_flat_key(nk) do
    if MapSet.member?(flats(), key_from_note(nk)) do
      new_key = Map.get(@sharp_key_map, key_from_note(nk))
      if is_tuple(nk) do Note.new({new_key, elem(nk, 1)}) else new_key end
    else
      nk
    end
  end

  @doc """
  Adjust the octave of a scale by the given octave amount.
  E.G. adjust_octave(scale, 1) will increase the octave of each note in the scale by 12.
       adjust_octave(scale, -1) will decrease the octave of each note in the scale by 12.
  """
  @spec adjust_octave(scale, integer) :: scale
  def adjust_octave(scale, octave) when octave == 0 do scale end
  def adjust_octave(scale = [%Note{} | _], octave) do
    Enum.map(scale, fn %Note{note: {note, o}} = n -> %{n | note: {note, o + octave}} end)
  end
  def adjust_octave(scale, octave) do
    Enum.map(scale, fn {note, o} -> {note, o + octave} end)
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

  @doc """
  Build a scale from the given key and mode.
  """
  @spec modal_scale(atom, integer, atom) :: note_sequence
  def modal_scale(key, octave, mode) do
    build_note_seq(key, @major_intervals |> rotate_zero(@modes[mode]) , octave)
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
    raw_seq = chromatic_scale(Note.new({skey, octave}))
    |> raw_scale(intervals)
    |> map_by_key(key)

    # Convert to Note structs with quarter note durations (1) and velocity of 100
    Enum.map(raw_seq, fn raw_note ->
      Note.new(raw_note, duration: 1, velocity: 100)
    end)
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

  @doc """
  Adjust a note's octave up or down by one.
  """
  @spec bump_octave(Note.t() | [Note.t()], :up | :down) :: Note.t() | [Note.t()]
  def bump_octave(%Note{note: {key, octave}} = note, direction) do
    delta = if direction == :up, do: 1, else: -1
    %{note | note: {key, octave + delta}}
  end

  def bump_octave(%Note{note: %Note{note: {key, octave}}} = note, direction) do
    delta = if direction == :up, do: 1, else: -1
    %{note | note: Note.new({key, octave + delta})}
  end

  def bump_octave(notes = [%Note{} | _], direction) do
    Enum.map(notes, &bump_octave(&1, direction))
  end

  @spec bump_octave([Note.t()], integer, :up | :down) :: [Note.t()]
  def bump_octave(notes = [%Note{} | _], pos, direction) do
    List.update_at(notes, pos, &bump_octave(&1, direction))
  end

  # Maintain backward compatibility with existing code
  @spec octave_up(Note.t()) :: Note.t()
  def octave_up(%Note{} = note), do: bump_octave(note, :up)

  @spec octave_up(note_sequence) :: note_sequence
  def octave_up(chord) when is_list(chord), do: bump_octave(chord, :up)

  @spec octave_up(note_sequence, integer) :: note_sequence
  def octave_up(chord, pos) when is_integer(pos), do: bump_octave(chord, pos, :up)

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

  @doc """
  Creates a Note struct from a key and octave
  """
  @spec make_note(key, integer, keyword()) :: Note.t()
  def make_note(key, octave, opts \\ []) do
    Note.new({key, octave}, opts)
  end

  @doc """
  Converts a list of Note structs to a keyword list in the old format
  For backward compatibility with tests
  """
  @spec to_keyword_list([Note.t()]) :: keyword(integer)
  def to_keyword_list(notes) do
    Enum.map(notes, fn
      %Note{note: {key, octave}} -> {key, octave}
      %Note{note: %Note{note: {key, octave}}} -> {key, octave}
      {key, octave} -> {key, octave}
    end)
  end

  def is_note(%Note{note: {n, o}}) do
    Enum.any?(circle_of_5ths(), &(&1 == n)) and is_integer(o)
  end

  def note_to_string(%Note{} = note) do
    Note.to_string(note)
  end


end
