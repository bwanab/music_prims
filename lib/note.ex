defmodule Note do
  @moduledoc """
  Functions for working with musical notes.
  """

  @type t :: %__MODULE__{
    note: {atom(), integer()},
    duration: integer(),
    velocity: integer()
  }

  @type scale :: [t()]

  defstruct [:note, :duration, :velocity]

  # Notes and MIDI mapping
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @flat_notes [:C, :Db, :D, :Eb, :E, :F, :Gb, :G, :Ab, :A, :Bb, :B]
  @sharp_midi_notes Enum.with_index(@notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @flat_midi_notes Enum.with_index(@flat_notes) |> Enum.map(fn {a, b} -> {a, b+12} end)
  @midi_notes @sharp_midi_notes ++ @flat_midi_notes

  @midi_notes_map Enum.into(@midi_notes, %{})

  # Circle of fifths and key mapping
  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]

  @flat_key_map Enum.zip(@circle_of_fifths, @flat_circle_of_fifths) |> Enum.into(%{})
  @normal_flat_key_map @flat_key_map |> Map.merge(%{:F! => :F!, :C! => :C!})
  @sharp_key_map Enum.zip(@flat_circle_of_fifths, @circle_of_fifths) |> Enum.into(%{})

  @doc """
  Create a new note with the given key and octave.
  """
  @spec new({atom(), integer()} | t(), keyword()) :: t()
  def new(note_or_tuple, opts \\ [])

  def new(%__MODULE__{} = note, opts) do
    duration = if Keyword.has_key?(opts, :duration), do: Keyword.get(opts, :duration), else: note.duration
    velocity = if Keyword.has_key?(opts, :velocity), do: Keyword.get(opts, :velocity), else: note.velocity
    %__MODULE__{note: note.note, duration: duration, velocity: velocity}
  end

  def new({key, octave}, opts) do
    # Handle nil values and defaults
    {duration, velocity} = case opts do
      [] -> {nil, nil}  # No options provided, both should be nil
      [duration: nil] -> {nil, 100}  # Only duration provided as nil
      [velocity: nil] -> {4, nil}  # Only velocity provided as nil
      [duration: nil, velocity: nil] -> {nil, nil}  # Both provided as nil
      [velocity: nil, duration: nil] -> {nil, nil}  # Both provided as nil (different order)
      _ ->
        duration = if Keyword.has_key?(opts, :duration), do: Keyword.get(opts, :duration), else: 1.0
        velocity = if Keyword.has_key?(opts, :velocity), do: Keyword.get(opts, :velocity), else: 100
        {duration, velocity}
    end
    %__MODULE__{note: {key, octave}, duration: duration, velocity: velocity}
  end

  @doc """
  Build a note sequence from a key and intervals.
  """
  @spec build_note_seq(atom, [integer], integer) :: scale
  def build_note_seq(key, intervals, octave \\ 4) do
    skey = map_by_flat_key(key)
    raw_seq = Note.chromatic_scale(Note.new({skey, octave}))
    |> Scale.raw_scale(intervals)
    |> map_by_key(key)

    # Convert to Note structs with quarter note durations (1) and velocity of 100
    Enum.map(raw_seq, fn raw_note ->
      Note.new(raw_note, duration: 1, velocity: 100)
    end)
  end

  @spec map_by_key([Note.t()], atom()) :: [Note.t()]
  def map_by_key(seq, key) do
    if MapSet.member?(Scale.normal_flat_set(), key_from_note(key)) do
      Enum.map(seq, fn a -> map_by_sharp_key(a) end)
    else
      Enum.map(seq, fn a -> map_by_flat_key(a) end)
    end
   end

  @doc """
  Get the key from a note.
  """
  @spec key_from_note(t()) :: atom()
  def key_from_note(%__MODULE__{note: {key, _}}), do: key

  @doc """
  Get the octave from a note.
  """
  @spec octave_from_note(t()) :: integer()
  def octave_from_note(%__MODULE__{note: {_, octave}}), do: octave

  @doc """
  Convert a note or list of notes to MIDI value(s).
  """
  @spec to_midi(t() | [t()]) :: integer() | [integer()]
  def to_midi(%__MODULE__{note: {key, octave}}) do
    @midi_notes_map[key] + (octave * 12)
  end
  def to_midi(notes) when is_list(notes), do: Enum.map(notes, &to_midi/1)

  @doc """
  Get the next note in the circle of fifths.
  """
  @spec next_fifth(t()) :: t()
  def next_fifth(%__MODULE__{} = note) do
    {key, octave} = note.note
    next_key = case key do
      :F -> {:C, octave + 1}
      :C -> {:G, octave}
      :G -> {:D, octave}
      :D -> {:A, octave}
      :A -> {:E, octave}
      :E -> {:B, octave}
      :B -> {:F!, octave}
      :F! -> {:C!, octave}
      :C! -> {:G!, octave}
      :G! -> {:D!, octave}
      :D! -> {:A!, octave}
      :A! -> {:F, octave}
    end
    %{note | note: next_key}
  end

  @doc """
  Get the next note in the circle of fourths.
  """
  @spec next_fourth(t()) :: t()
  def next_fourth(%__MODULE__{} = note) do
    {key, octave} = note.note
    next_key = case key do
      :F -> {:A!, octave - 1}
      :C -> {:F, octave}
      :G -> {:C, octave}
      :D -> {:G, octave}
      :A -> {:D, octave}
      :E -> {:A, octave}
      :B -> {:E, octave}
      :F! -> {:B, octave}
      :C! -> {:F!, octave}
      :G! -> {:C!, octave}
      :D! -> {:G!, octave}
      :A! -> {:D!, octave}
    end
    %{note | note: next_key}
  end

  @doc """
  Get the next half step up from the given note.
  """
  @spec next_half_step(t()) :: t()
  def next_half_step(%__MODULE__{note: {key, octave}} = note) do
    next_key = case key do
      :C -> :C!
      :C! -> :D
      :D -> :D!
      :D! -> :E
      :Eb -> :E
      :E -> :F
      :F -> :F!
      :F! -> :G
      :G -> :G!
      :G! -> :A
      :Ab -> :A
      :A -> :A!
      :A! -> :B
      :Bb -> :B
      :B -> %{note | note: {:C, octave + 1}}
    end

    case next_key do
      %__MODULE__{} -> next_key
      key -> %{note | note: {key, octave}}
    end
  end

  @doc """
  Get the next note in the given circle.
  """
  @spec next_nth(t(), [atom()]) :: t()
  def next_nth(%__MODULE__{} = note, circle) do
    {key, octave} = note.note
    idx = Enum.find_index(circle, &(&1 == key))
    next_key = case idx do
      nil -> {key, octave}
      ^idx when idx == length(circle) - 1 -> {Enum.at(circle, 0), octave + 1}
      ^idx -> {Enum.at(circle, idx + 1), octave}
    end
    %{note | note: next_key}
  end

  @doc """
  Move a note or list of notes up or down an octave.
  """
  @spec bump_octave(t() | [t()], :up | :down) :: t() | [t()]
  def bump_octave(%__MODULE__{note: {key, octave}} = note, :up) do
    %{note | note: {key, octave + 1}}
  end
  def bump_octave(%__MODULE__{note: {key, octave}} = note, :down) do
    %{note | note: {key, octave - 1}}
  end
  def bump_octave(notes, direction) when is_list(notes) do
    Enum.map(notes, &bump_octave(&1, direction))
  end

  @doc """
  Move a note at a specific position up or down an octave.
  """
  @spec bump_octave([t()], integer(), :up | :down) :: [t()]
  def bump_octave(notes, position, direction) do
    List.update_at(notes, position, fn note ->
      bump_octave(note, direction)
    end)
  end

  @doc """
  Move a note or list of notes up an octave.
  """
  @spec octave_up(t() | [t()]) :: t() | [t()]
  def octave_up(%__MODULE__{} = note), do: bump_octave(note, :up)
  def octave_up(notes) when is_list(notes), do: Enum.map(notes, &octave_up/1)

  @doc """
  Map a note to its sharp key.
  """
  @spec map_by_sharp_key(t() | atom(), atom()) :: t() | atom()
  def map_by_sharp_key(note_or_key, context \\ :normal)
  def map_by_sharp_key(%__MODULE__{} = note, context) do
    {key, octave} = note.note
    %{note | note: {map_by_sharp_key(key, context), octave}}
  end
  def map_by_sharp_key(key, context) when is_atom(key) do
    key_map = if context == :normal, do: @normal_flat_key_map, else: @flat_key_map
    case Map.get(key_map, key) do
      nil -> key
      val -> val
    end
  end

  @doc """
  Map a note to its flat key.
  """
  @spec map_by_flat_key(t() | atom()) :: t() | atom()
  def map_by_flat_key(%__MODULE__{} = note) do
    {key, octave} = note.note
    %{note | note: {map_by_flat_key(key), octave}}
  end
  def map_by_flat_key(key) when is_atom(key) do
    case Map.get(@sharp_key_map, key) do
      nil -> key
      val -> val
    end
  end

  @doc """
  Get the MIDI note number for a key.
  """
  @spec note_map(atom()) :: integer()
  def note_map(note), do: @midi_notes_map[note]

  @doc """
  Adjust the octave of a scale by the given octave amount.
  E.G. adjust_octave(scale, 1) will increase the octave of each note in the scale by 12.
       adjust_octave(scale, -1) will decrease the octave of each note in the scale by 12.
  """
  @spec adjust_octave(scale(), integer()) :: scale()
  def adjust_octave(scale, octave) when octave == 0, do: scale
  def adjust_octave(scale = [%__MODULE__{} | _], octave) do
    Enum.map(scale, fn %__MODULE__{note: {note, o}} = n -> %{n | note: {note, o + octave}} end)
  end
  def adjust_octave(scale, octave) do
    Enum.map(scale, fn {note, o} -> {note, o + octave} end)
  end

  @doc """
  Build a chromatic scale starting from the given note.
  """
  @spec chromatic_scale(t() | {atom(), integer()}) :: [t()]
  def chromatic_scale(%__MODULE__{} = note) do
    Enum.reduce(0..11, [note], fn _, [last | _] = acc ->
      next = next_half_step(last)
      # Map sharp notes to flat notes where appropriate
      mapped_note = case next.note do
        {:D!, o} -> %{next | note: {:Eb, o}}
        {:G!, o} -> %{next | note: {:Ab, o}}
        {:A!, o} -> %{next | note: {:Bb, o}}
        _ -> next
      end
      [mapped_note | acc]
    end)
    |> Enum.reverse()
  end
  def chromatic_scale({key, octave}) do
    chromatic_scale(new({key, octave}))
  end


  @doc """
  Check if two notes are enharmonically equal.
  Handles both Note structs and {key, octave} tuples.
  """
  @spec enharmonic_equal?(t | {atom, integer}, t | {atom, integer}) :: boolean
  def enharmonic_equal?(note1, note2) do
    midi1 = case note1 do
      %Note{} -> to_midi(note1)
      {key, octave} -> to_midi(new({key, octave}))
    end

    midi2 = case note2 do
      %Note{} -> to_midi(note2)
      {key, octave} -> to_midi(new({key, octave}))
    end

    midi1 == midi2
  end

  @doc """
  Convert a note to its MIDI note number, duration, and velocity.
  """
  @spec note_to_midi(t) :: %{note_number: integer, duration: number | nil, velocity: integer}
  def note_to_midi(%Note{note: {key, octave}, duration: duration, velocity: velocity}) do
    midi_duration = case duration do
      0 -> 0.0
      _ -> 4.0 / duration
    end
    %{
      note_number: @midi_notes_map[key] + (octave * 12),
      duration: midi_duration,
      velocity: velocity || 100
    }
  end

  @doc """
  Convert a MIDI note number to a Note struct.
  """
  @spec midi_to_note(integer, number | nil, integer | nil) :: t
  def midi_to_note(note_number, duration \\ nil, velocity \\ 100) do
    octave = div(note_number - 12, 12)
    key_index = rem(note_number - 12, 12)
    key = Enum.at(@notes, key_index)
    new({key, octave}, duration: duration, velocity: velocity)
  end

  @doc """
  Create a rest note with the given duration.
  """
  @spec rest(number) :: t
  def rest(duration) do
    new({:R, 0}, duration: duration, velocity: 0)
  end

  @doc """
  Create a new note with the given key and octave.
  """
  @spec make_note(atom, integer, keyword) :: t
  def make_note(key, octave, opts \\ []) do
    new({key, octave}, opts)
  end

  @doc """
  Check if a value is a valid note.
  """
  @spec is_note(t) :: boolean
  def is_note(%Note{note: {n, o}}) do
    Enum.any?(circle_of_fifths(), &(&1 == n)) and is_integer(o)
  end

  @doc """
  Convert a list of notes to a keyword list in the old format.
  For backward compatibility with tests.
  """
  @spec to_keyword_list([t]) :: keyword(integer)
  def to_keyword_list(notes) do
    Enum.map(notes, fn
      %Note{note: {key, octave}} -> {key, octave}
      %Note{note: %Note{note: {key, octave}}} -> {key, octave}
      {key, octave} -> {key, octave}
    end)
  end

  @doc """
  Rotate a list of notes by the given amount.
  """
  @spec rotate_notes([t], integer) :: [t]
  def rotate_notes(notes, n) do
    {l, r} = Enum.split(notes, n)
    r ++ Enum.map(l, fn
      %Note{note: {key, octave}} -> new({key, octave + 1})
      {key, octave} -> new({key, octave + 1})
    end)
  end

  @doc """
  Get the circle of fifths.
  """
  @spec circle_of_fifths() :: [atom]
  def circle_of_fifths(), do: @flat_circle_of_fifths


  @spec common_notes(MusicPrims.note_sequence, MusicPrims.note_sequence, boolean) :: integer
  def common_notes(c1, c2, ignore_octave \\ :true)

  def common_notes(c1, c2, ignore_octave) when ignore_octave == :false do
    case List.myers_difference(c1, c2)[:eq] do
      nil -> []
      val -> val
    end
    |> Enum.count
  end

  def common_notes(c1, c2, ignore_octave) when ignore_octave == :true do
    case List.myers_difference(Enum.map(c1, &key_from_note(&1)), Enum.map(c2, &key_from_note(&1)))[:eq] do
      nil -> []
      val -> val
    end
    |> Enum.count
  end


  @spec note_distance(Note.t(), Note.t()) :: integer
  def note_distance(n1, n2) do
    v =
      Stream.iterate(abs(to_midi(n1) - to_midi(n2)), &(&1 - 12))
      |> Stream.drop_while(&(&1 > 12))
      |> Enum.take(1)
      |> List.first
    if v > 6 do 12 - v else v end
  end


  # Implement the Sonority protocol
  defimpl Sonority do
    def duration(note), do: 1 / note.duration
    def type(_), do: :note
    @doc """
    Convert a note to a Lilypond string representation.
    """
    # @spec to_string(t()) :: String.t()
    #def to_string(%__MODULE__{note: {key, octave}, duration: duration}) do
    def show(%Note{note: {key, octave}, duration: duration}, opts \\ []) do
      no_dur = if Keyword.has_key?(opts, :no_dur), do: Keyword.get(opts, :no_dur), else: false

      b = String.downcase(Atom.to_string(key))
      key_str = case String.length(b) do
        1 -> b
        2 -> case String.at(b, 1) do
          "!" -> "#{String.at(b, 0)}is"
          _ -> "#{String.at(b, 0)}es"
        end
      end

      octave_str = case octave do
        6 -> "''''"
        5 -> "'''"
        4 -> "''"
        3 -> "'"
        2 -> ""
        1 -> ","
        0 -> ",,"
        _ -> "''"
      end

      if no_dur do
        "#{key_str}#{octave_str}"
      else
        "#{key_str}#{octave_str}#{duration}"
      end
    end
  end
end
