defmodule Chord do
  @moduledoc """
  Represents a chord as a sonority with duration.

  A chord can be created either from a list of Note structs or from a chord symbol.
  This module provides functions for creating, modifying, and analyzing chords.
  """
  @type chord_sym :: {{atom(), integer()}, atom()}

  @type t :: %__MODULE__{
    root: MusicPrims.key() | nil,
    quality: atom() | nil,
    notes: [Note.t()] | nil,
    duration: number(),
    bass_note: Note.t() | nil,
    additions: [Note.t()] | nil,
    omissions: [integer()] | nil,
    inversion: integer(),
    velocity: integer(),
    channel: integer()
  } | Sonority.t()

  defstruct [:root, :quality, :notes, :duration, :bass_note, :additions, :omissions, :inversion, :velocity, :channel]


  # Helper function to apply chord inversion
  defp apply_inversion(notes, inversion) when is_integer(inversion) and inversion >= 0 do
    if inversion > 0 and inversion < length(notes) do
      Scale.rotate_notes(notes, inversion)
    else
      notes  # Return original notes if inversion is 0 or invalid
    end
  end

  @doc """
  Creates a new chord from either a list of notes, a chord symbol, or the result from infer_chord_type.

  This function supports backward compatibility with existing code while
  providing enhanced functionality through the new fields.

  ## Parameters
    * First argument:
        * A list of Note structs,
        * A chord symbol tuple of the form {{key, octave}, quality},
        * Or a tuple from infer_chord_type of the form {{root_key, quality}, inversion}
    * `duration` - The duration of the chord in beats
    * `inversion` - The inversion degree (0 = root position, 1 = first, etc.) - only applies to chord symbol

  ## Returns
    * A new Chord struct
  """

  # # # Constructor that takes the result of infer_chord_type
  # @spec new({{atom(), atom()}, integer()}, float()) :: Sonority.t()
  # def new({{key, quality}, inversion}, duration) when is_atom(quality) and is_integer(inversion) do
  #   # Extract the rootless key and octave from the key
  #   {root_key, octave} = case key do
  #     {k, o} when is_atom(k) and is_integer(o) -> {k, o}
  #     k when is_atom(k) -> {k, 4}  # Default octave if not specified
  #   end

  #   # Get standard notes for this chord type
  #   notes = ChordTheory.get_standard_notes(root_key, quality, octave)

  #   # Apply inversion if needed
  #   inverted_notes = apply_inversion(notes, inversion)

  #   %__MODULE__{
  #     notes: inverted_notes,
  #     root: key,
  #     quality: quality,
  #     duration: duration,
  #     inversion: inversion
  #   }
  # end

  # Constructor from notes
  @spec new([Note.t()], integer()) :: Sonority.t()
  def new(notes, duration) when is_list(notes) do
    notes = Enum.map(notes, fn n -> Sonority.copy(n, duration: duration, velocity: n.velocity) end)
    velocity = floor(Enum.sum(Enum.map(notes, fn n -> n.velocity end)) / length(notes))
    [first | _] = notes
    channel = first.channel
    {inferred_root, inferred_quality, inversion} = infer_chord_type(notes)
    %__MODULE__{
      notes: notes,
      root: inferred_root,
      quality: inferred_quality,
      duration: duration,
      inversion: inversion,
      velocity: velocity,
      channel: channel
    }
  end

  # # Constructor from chord symbol with optional inversion
  # @spec new({{atom(), integer()}, atom()}, float(), integer()) :: Sonority.t()
  # def new(chord = {{key, _octave}, quality}, duration, inversion \\ 0) do

  #   notes = chord_to_notes(chord)

  #   # Apply inversion if needed
  #   inverted_notes = apply_inversion(notes, inversion)

  #   %__MODULE__{
  #     root: key,
  #     quality: quality,
  #     notes: inverted_notes,
  #     duration: duration,
  #     inversion: inversion
  #   }
  # end

  @doc """
  Creates a chord from a root note, quality, and optional parameters via keyword list.

  ## Parameters
    * `key` - The root key of the chord
    * `quality` - The chord quality (e.g., :major, :minor)
    * `opts` - Keyword list with optional parameters:
      * `:octave` - The octave for the root note (default: 3)
      * `:duration` - The duration of the chord in beats (default: 1.0)
      * `:inversion` - The inversion degree (0 = root position, 1 = first, etc.) (default: 0)
      * `:velocity` - The MIDI velocity (default: 100)
      * `:channel` - The MIDI channel (default: 0)

  ## Returns
    * A new Chord struct
  """
  @spec new(atom(), atom(), keyword()) :: Sonority.t()
  def new(key, quality, opts \\ []) do
    octave = Keyword.get(opts, :octave, 3)
    duration = Keyword.get(opts, :duration, 1.0)
    inversion = Keyword.get(opts, :inversion, 0)
    velocity = Keyword.get(opts, :velocity, 100)
    channel = Keyword.get(opts, :channel, 0)

    notes = get_standard_notes(key, quality, octave: octave, channel: channel)

    # Apply inversion if needed
    inverted_notes = apply_inversion(notes, inversion)
    inverted_notes = Enum.map(inverted_notes, fn n -> Sonority.copy(n, velocity: velocity, channel: channel) end)

    %__MODULE__{
      root: key,
      quality: quality,
      notes: inverted_notes,
      duration: duration,
      inversion: inversion,
      velocity: velocity,
      channel: channel
    }
  end



  def octave(chord) do
    Enum.at(Sonority.to_notes(chord), 0).octave
  end


  @doc """
  Specifies the bass note for the chord, creating a slash chord.

  ## Parameters
    * `chord` - The Chord struct to modify
    * `bass_note` - The bass note to use (e.g., {:G, 3})

  ## Returns
    * A new Chord struct with the updated bass note
  """
  def with_bass(chord, bass_note) do
    %{chord | bass_note: bass_note}
  end

  @doc """
  Adds additional notes to the chord beyond its standard structure.

  ## Parameters
    * `chord` - The Chord struct to modify
    * `added_notes` - A list of Note structs to add to the chord

  ## Returns
    * A new Chord struct with the additional notes
  """
  def with_additions(chord, added_notes) do
    %{chord | additions: added_notes}
  end

  @doc """
  Specifies notes to omit from the chord's standard structure.

  ## Parameters
    * `chord` - The Chord struct to modify
    * `omitted_degrees` - A list of scale degrees to omit (e.g., [1] to omit the root)

  ## Returns
    * A new Chord struct with the specified omissions
  """
  def with_omissions(chord, omitted_degrees) do
    %{chord | omissions: omitted_degrees}
  end

  @doc """
  Creates a chord from a Roman numeral, key, and optional parameters via keyword list.

  This function allows direct creation of chords from Roman numerals in a specific key.

  ## Parameters
    * `roman_numeral` - The Roman numeral symbol (e.g., :I, :ii, :V7)
    * `key` - The key to interpret the Roman numeral in (e.g., :C for C major)
    * `opts` - Keyword list with optional parameters:
      * `:octave` - The octave for the root note (default: 4)
      * `:duration` - The duration of the chord in beats (default: 1.0)
      * `:scale_type` - The scale type (:major or :minor) to interpret the Roman numeral in (default: :major)
      * `:inversion` - The inversion degree (0 = root position, 1 = first, etc.) (default: 0)
      * `:channel` - The MIDI channel (default: 0)

  ## Returns
    * A new Chord struct

  ## Examples
      # Creates a C major chord (I in C major) in octave 4 with duration 4.0
      iex> chord = Chord.from_roman_numeral(:I, :C, octave: 4, duration: 4.0)
      iex> chord.root
      :C
      iex> chord.quality
      :major

      # Creates a D dominant seventh chord (V7 in G major) in octave 3 with duration 2.0
      iex> chord = Chord.from_roman_numeral(:V7, :G, octave: 3, duration: 2.0)
      iex> chord.root
      :D
      iex> chord.quality
      :dominant_seventh

      # Creates a D# major chord (III in C minor) in octave 4 with duration 1.0
      # Note: D# is enharmonic with Eb but our implementation uses D#
      iex> chord = Chord.from_roman_numeral(:III, :C, octave: 4, duration: 1.0, scale_type: :minor)
      iex> Note.enharmonic_equal?(chord.root, :D!)
      iex> chord.quality
      :major

      # Creates a first inversion C major chord (I⁶ in C major) in octave 4 with duration 1.0
      iex> chord = Chord.from_roman_numeral(:I, :C, octave: 4, duration: 1.0, scale_type: :major, inversion: 1)
      iex> chord.root
      :C
      iex> chord.quality
      :major
      iex> chord.inversion
      1
  """
  def from_roman_numeral(roman_numeral, key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 4)
    duration = Keyword.get(opts, :duration, 1.0)
    scale_type = Keyword.get(opts, :scale_type, :major)
    inversion = Keyword.get(opts, :inversion, 0)
    channel = Keyword.get(opts, :channel, 0)

    # Convert Roman numeral to chord using ChordPrims
    chord_sym = roman_numeral_to_chord(roman_numeral, key, octave, scale_type)

    # Extract root and quality from the chord symbol
    {{root, chord_octave}, quality} = chord_sym

    # Get standard notes for this chord
    notes = get_standard_notes(root, quality, octave: chord_octave, channel: channel)

    # Apply inversion if needed
    inverted_notes = apply_inversion(notes, inversion)

    # Create the chord
    %__MODULE__{
      root: root,
      quality: quality,
      notes: inverted_notes,
      duration: duration,
      inversion: inversion,
      channel: channel
    }
  end

  @spec note_from_roman_numeral(atom(), atom(), integer(), Scale.scale_type, Keyword.t()) :: Note.t()
  @doc """
    returns the note represented by the roman numeral for a given root key
    that is of the given scale type and octave.

    The options are any of the options that Note.copy accepts

    Example:
    iex> note = Chord.note_from_roman_numeral(:IV, :A, 2, :major)
    iex> note.note
    :D
    iex> note.octave
    3

    since :D in the 3rd octave is the 4th major scale note of A in the 2nd octave

  """
  def note_from_roman_numeral(roman_numeral, key, octave, scale_type \\ :major, opts \\ []) do
    {{chord_key, chord_octave}, chord_type} = Chord.roman_numeral_to_chord(roman_numeral, key, octave, scale_type)
    Chord.chord_to_notes(chord_key, octave: chord_octave, scale_type: chord_type)
    |> Enum.at(0)
    |> Sonority.copy(opts)
  end

  @doc """
  Checks if the chord's root is enharmonically equal to the specified note or key.

  This is useful when working with chord progressions where you need to check for
  chords by root, but want to handle enharmonic equivalences properly.

  ## Parameters
    * `chord` - The Chord struct to check
    * `note` - The note or key to compare against, either as a note tuple or atom

  ## Examples

      iex> chord = Chord.from_roman_numeral(:III, :C, octave: 4, duration: 1.0, scale_type: :minor)
      iex> Chord.has_root_enharmonic_with?(chord, :Eb)
      true

      iex> chord = Chord.from_roman_numeral(:III, :C, octave: 4, duration: 1.0, scale_type: :minor)
      iex> Chord.has_root_enharmonic_with?(chord, {:Eb, 4})
      true
  """
  def has_root_enharmonic_with?(chord, note) when is_atom(note) do
    Note.enharmonic_equal?({chord.root, 4}, {note, 4})
  end

  def has_root_enharmonic_with?(chord, {note, octave}) do
    # The octave from the chord's root should be preserved, not the input octave
    # This allows checking if a chord's root matches a note name, regardless of octave
    Note.enharmonic_equal?({chord.root, octave}, {note, octave})
  end


  # Implement the Sonority protocol
  defimpl Sonority do
    def copy(chord, opts \\ []) do
      root = Keyword.get(opts, :root, chord.root)
      quality = Keyword.get(opts, :quality, chord.quality)
      octave = Keyword.get(opts, :octave, Chord.octave(chord))
      duration = Keyword.get(opts, :duration, chord.duration)
      inversion = Keyword.get(opts, :inversion, chord.inversion)
      velocity = Keyword.get(opts, :velocity, chord.velocity)
      channel = Keyword.get(opts, :channel, chord.channel)
      Chord.new(root, quality, octave: octave, duration: duration, inversion: inversion, velocity: velocity, channel: channel)
    end

    def duration(chord), do: chord.duration
    def type(_), do: :chord

    @doc """
    Convert a chord to a Lilypond string representation.
    """
    @spec show(Chord.t(), keyword()) :: String.t()
    def show(chord, _opts \\ []) do
      s = Enum.map(Sonority.to_notes(chord), fn n -> Sonority.show(n, no_dur: true) end) |> Enum.join(" ")
      "< #{s} >#{MidiNote.get_lily_duration(chord.duration)}"
    end

    def to_notes(chord) do
      # Start with base notes
      base_notes = chord.notes || []

      # Apply omissions if any
      notes_after_omissions = if chord.omissions do
        indices_to_remove = MapSet.new(chord.omissions)
        Enum.with_index(base_notes)
        |> Enum.reject(fn {_, idx} -> idx in indices_to_remove end)
        |> Enum.map(fn {note, _} -> note end)
      else
        base_notes
      end

      # Add additions if any
      notes_with_additions = if chord.additions do
        notes_after_omissions ++ chord.additions
      else
        notes_after_omissions
      end

      # Handle bass note if specified (would need to ensure it's at the bottom)
      # For simplicity, we're not implementing this logic fully
      Enum.map(notes_with_additions, fn n -> Sonority.copy(n, duration: chord.duration, velocity: n.velocity, channel: chord.channel) end)
    end

    def channel(chord) do
      chord.channel
    end

  end

  import Scale

  @type chord :: [Note.t()]

  @doc """
  Build a major chord from the given key and octave.
  """
  @spec major_chord(atom, keyword) :: chord
  def major_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 4, 7], octave: octave, channel: channel)
  end

  @doc """
  Build a minor chord from the given key and octave.
  """
  @spec minor_chord(atom, keyword) :: chord
  def minor_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 3, 7], octave: octave, channel: channel)
  end

  @doc """
  Build an augmented chord from the given key and octave.
  """
  @spec augmented_chord(atom, keyword) :: chord
  def augmented_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 4, 8], octave: octave, channel: channel)
  end

  @doc """
  Build a diminished chord from the given key and octave.
  """
  @spec diminished_chord(atom, keyword) :: chord
  def diminished_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 3, 6], octave: octave, channel: channel)
  end

  @doc """
  Build a dominant seventh chord from the given key and octave.
  """
  @spec dominant_seventh_chord(atom, keyword) :: chord
  def dominant_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 4, 7, 10], octave: octave, channel: channel)
  end

  @doc """
  Build a major seventh chord from the given key and octave.
  """
  @spec major_seventh_chord(atom, keyword) :: chord
  def major_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 4, 7, 11], octave: octave, channel: channel)
  end

  @doc """
  Build a minor seventh chord from the given key and octave.
  """
  @spec minor_seventh_chord(atom, keyword) :: chord
  def minor_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 3, 7, 10], octave: octave, channel: channel)
  end

  @doc """
  Build a half-diminished seventh chord from the given key and octave.
  """
  @spec half_diminshed_seventh_chord(atom, keyword) :: chord
  def half_diminshed_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 3, 6, 10], octave: octave, channel: channel)
  end

  @doc """
  Build a diminished seventh chord from the given key and octave.
  """
  @spec diminished_seventh_chord(atom, keyword) :: chord
  def diminished_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 3, 6, 9], octave: octave, channel: channel)
  end

  @doc """
  Build a minor-major seventh chord from the given key and octave.
  """
  @spec minor_major_seventh_chord(atom, keyword) :: chord
  def minor_major_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 3, 7, 11], octave: octave, channel: channel)
  end

  @doc """
  Build an augmented major seventh chord from the given key and octave.
  """
  @spec augmented_major_seventh_chord(atom, keyword) :: chord
  def augmented_major_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 4, 8, 11], octave: octave, channel: channel)
  end

  @doc """
  Build an augmented seventh chord from the given key and octave.
  """
  @spec augmented_seventh_chord(atom, keyword) :: chord
  def augmented_seventh_chord(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    channel = Keyword.get(opts, :channel, 0)
    build_note_seq(key, [0, 4, 8, 10], octave: octave, channel: channel)
  end

  @doc """
  Get the first inversion of a chord.
  """
  @spec first_inversion(chord) :: chord
  def first_inversion(chord) do
    rotate_notes(chord, 1)
  end

  @doc """
  Get the second inversion of a chord.
  """
  @spec second_inversion(chord) :: chord
  def second_inversion(chord) do
    rotate_notes(chord, 2)
  end

  @doc """
  Get the third inversion of a chord.
  """
  @spec third_inversion(chord) :: chord
  def third_inversion(chord) do
    rotate_notes(chord, 3)
  end

  @spec roman_numeral_to_chord(atom(), atom(), integer(), Scale.scale_type()) :: chord
  def roman_numeral_to_chord(sym, key, octave, scale_type) do
    scale = if scale_type == :major do
      major_scale(key, octave: octave)
    else
      minor_scale(key, octave: octave)
    end
    # Extract just the note names from the scale
    # note_names = scale |> Enum.map(fn
    #   %Note{note: n} -> n
    #   {n, _o} -> n
    # end)

    {index, chord_type} = ChordPrims.all_chord_sym_map[sym]
    %Note{note: chord_key, octave: new_octave} = Enum.at(scale, index)

    # Keep the same format as input - full tuple with octave
    {{chord_key, new_octave}, chord_type}
  end
  def roman_numeral_to_chord(sym, {%Note{note: key, octave: octave}, scale_type}) do
    roman_numeral_to_chord(sym, key, octave, scale_type)
  end

  @spec roman_numerals_to_chords([atom], chord) :: [chord]
  def roman_numerals_to_chords(sym_seq, chord) do
    Enum.map(sym_seq, fn sym -> roman_numeral_to_chord(sym, chord) end)
  end

  @spec roman_numerals_to_chords([atom], atom(), integer(), atom()) :: [chord]
  def roman_numerals_to_chords(sym_seq, key, octave, scale_type) do
    Enum.map(sym_seq, fn sym -> roman_numeral_to_chord(sym, key, octave, scale_type) end)
  end

  @spec chord_to_notes(atom, keyword) :: [Note.t()]
  def chord_to_notes(key, opts \\ []) do
    octave = Keyword.get(opts, :octave, 0)
    scale_type = Keyword.get(opts, :scale_type, :major)
    channel = Keyword.get(opts, :channel, 0)
    chord_type_map()[scale_type].(key, octave: octave, channel: channel)
  end

  @spec chords_to_notes([chord_sym]) :: [Note.t()]
  def chords_to_notes(chords) do
    Enum.map(chords, &(chord_to_notes(&1)))
  end

  @spec roman_numeral_to_midi(atom, chord_sym) :: [integer]
  def roman_numeral_to_midi(sym, chord) do
    roman_numeral_to_chord(sym, chord)
    |> chord_to_notes
    |> MidiNote.to_midi
  end

  @spec roman_numerals_to_midi([atom], chord_sym) :: [[integer]]
  def roman_numerals_to_midi(sym_seq, chord) do
    Enum.map(sym_seq, &(roman_numeral_to_midi(&1, chord)))
  end

  @spec chord_common_notes(chord_sym, chord_sym, boolean) :: integer
  def chord_common_notes(c1, c2, ignore_octave \\ :true) do
    Note.common_notes(chord_to_notes(c1), chord_to_notes(c2), ignore_octave)
  end


  @doc """
  compute the full distance that separates two chords.
  For example: {{:C, 4}, :major} to {{:A, 4}, :minor}
    The notes of C4 maj are C,E,G
    The notes of F4 min are A,C,E

    since C and E are shared there's no distance, but the distance from
    G to A is 2 semitones, thus the full distance is 2 for the chord.

  Example 2: {{:C, 4}, :major} to {{:D, 4}, :major}
    The notes of C4 maj are C,E,G
    The notes of D4 maj are D,F!,A

    Each of the pairs {C,D}, {E,F!} and {G,A} are 2 semitones each so
    the full distance is 6

  I truthfully don't know why this is a worthwhile measure and don't remember
  why I added it in the first place.
  """
  def compute_flow(c1, c2) when is_list(c1) and is_list(c2) do
    n = length(c2) - 1
    Enum.map(0..n, &(rotate_any(c2, &1)))
    # |> IO.inspect
    |> Enum.map(fn c2p -> compute_one_flow(c1, c2p) end)
    # |> IO.inspect
    |> Enum.min
  end

  def compute_flow(c1, c2) do
    compute_flow(chord_to_notes(c1), chord_to_notes(c2))
  end

  def compute_flow(p) do
    sum = Enum.zip(p, rotate_any(p, 1))
    |> Enum.map(fn {a, b} ->
      compute_flow(
        roman_numeral_to_chord(a, :G, 0, :major),
        roman_numeral_to_chord(b, :G, 0, :major))
    end)
    |> Enum.sum
    sum / length(p)
  end


  @spec compute_one_flow([MusicPrims.Note], [MusicPrims.Note]) :: integer
  def compute_one_flow(c1, c2) do
    Enum.zip(c1, c2)
    # |> IO.inspect
    |> Enum.map(fn {n1, n2} ->
      Note.note_distance(n1, n2)
    end)
    # |> IO.inspect
    |> Enum.sum
  end
  @doc """
  Rotate a list by the given amount.
  """
  @spec rotate_any([any], integer) :: [any]
  def rotate_any(list, n) do
    {l, r} = Enum.split(list, n)
    r ++ l
  end


  @chord_type_map %{:major => &Chord.major_chord/2,
                    :minor => &Chord.minor_chord/2,
                    :diminished => &Chord.diminished_chord/2,
                    :dominant_seventh => &Chord.dominant_seventh_chord/2,
                    :major_seventh => &Chord.major_seventh_chord/2,
                    :minor_seventh => &Chord.minor_seventh_chord/2
  }

  def chord_type_map() do
    @chord_type_map
  end


  @doc """
  Generates the standard notes for a given chord type.

  ## Parameters
    * `key` - The root key of the chord
    * `quality` - The chord quality (e.g., :major, :minor, :dominant_seventh)
    * `opts` - Keyword list with optional parameters:
      * `:octave` - The octave for the root note (default: 0)
      * `:channel` - The MIDI channel (default: 0)

  ## Returns
    * A list of Note structs representing the chord
  """
  def get_standard_notes(key, quality, opts \\ []) do
    case quality do
      :major -> Chord.major_chord(key, opts)
      :minor -> Chord.minor_chord(key, opts)
      :diminished -> Chord.diminished_chord(key, opts)
      :augmented -> Chord.augmented_chord(key, opts)
      :dominant_seventh -> Chord.dominant_seventh_chord(key, opts)
      :major_seventh -> Chord.major_seventh_chord(key, opts)
      :minor_seventh -> Chord.minor_seventh_chord(key, opts)
      :half_diminished_seventh -> Chord.half_diminshed_seventh_chord(key, opts)
      :diminished_seventh -> Chord.diminished_seventh_chord(key, opts)
      :minor_major_seventh -> Chord.minor_major_seventh_chord(key, opts)
      :augmented_major_seventh -> Chord.augmented_major_seventh_chord(key, opts)
      :augmented_seventh -> Chord.augmented_seventh_chord(key, opts)
      # Default to major if unknown quality
      _ -> Chord.major_chord(key, opts)
    end
  end

def get_intervals(notes) do
  note_nums = Enum.map(notes, &MidiNote.note_to_midi(&1).note_number)
  min = Enum.min(note_nums)
  Enum.with_index(Enum.map(note_nums, &(&1 - min)))
  |> Enum.sort()
end

def get_matches(raw_notes) do
  # first, consolidate the notes to get rid of duplicate notes in different octaves
  {notes, _} = Enum.reduce(raw_notes, {[], MapSet.new([])}, fn n, {note_acc, nset} ->
    if MapSet.member?(nset, n.note) do
      {note_acc, nset}
    else
      {note_acc ++ [n], MapSet.put(nset, n.note)}
    end
   end)

  get_note_nums = fn notes ->
    note_nums = Enum.map(notes, &MidiNote.note_to_midi(&1).note_number)
    min = Enum.min(note_nums)
    Enum.map(note_nums, &(&1 - min))
  end

  Enum.map(
      0..(length(notes) - 1),
      fn rotation_index ->
        rotated_notes = Scale.rotate_notes(notes, rotation_index)
        intervals = get_note_nums.(rotated_notes)
        chord_type = Map.get(MusicPrims.chord_interval_map(), intervals)
        {rotation_index, chord_type, rotated_notes}
      end
    )
    |> Enum.filter(fn {_i, chord_type, _rotated_notes} -> !is_nil(chord_type) end)
end

  @doc """
  Infers the root and quality of a chord from its notes, taking into account
  possible inversions in the chord notes. Thus, [C, F, A] is correctly identified
  as an inverted F chord instead of C.

  ## Parameters
    * `notes` - A list of Note structs to analyze

  ## Returns
    * A tuple of {{root_key, quality}, inversion} where
      root_key is the inferred root note
      quality is the inferred chord quality
      inversion is the degree of inversion (0 = root position, 1 = first inversion, etc.)
  """
  def infer_chord_type(notes) do
    matches = get_matches(notes)
    matches = if length(matches) == 0 do
      # here we say there's no direct rotation of the notes as given, but we will sort them
      # and see if there's a rotation that works.
      note_nums = Enum.map(notes, fn note -> MidiNote.note_to_midi(note) end)
      sorted_notes = Enum.zip(note_nums, notes) |> Enum.sort |> Enum.map(fn {_, n} -> n end)
      get_matches(sorted_notes)
    else
      matches
    end

    if length(matches) > 0 do
      # Get the first match
      {rotation_index, chord_type, rotated_notes} = Enum.at(matches, 0)

      # The root is the first note of the rotated collection that matched a chord pattern
      root_note = Enum.at(rotated_notes, 0).note

      # The inversion is the rotation index used to transform the input notes
      # to get to root position (when rotation_index=0)
      inversion = rotation_index

      {root_note, chord_type, inversion}
    else
      # Return a default value if no matches found
      # Using the first note as root, assuming major quality, and root position
      {List.first(notes).note, :major, 0}
    end
  end

  @doc """
  Returns the scale degrees present in a chord.

  ## Parameters
    * `root` - The root key of the chord
    * `quality` - The chord quality

  ## Returns
    * A list of integers representing scale degrees (1-based)
  """
  def chord_degrees(_root, quality) do
    case quality do
      :major -> [1, 3, 5]
      # b3
      :minor -> [1, 3, 5]
      # b3, b5
      :diminished -> [1, 3, 5]
      # #5
      :augmented -> [1, 3, 5]
      # b7
      :dominant_seventh -> [1, 3, 5, 7]
      :major_seventh -> [1, 3, 5, 7]
      # b3, b7
      :minor_seventh -> [1, 3, 5, 7]
      # b3, b5, b7
      :half_diminished_seventh -> [1, 3, 5, 7]
      # b3, b5, bb7
      :diminished_seventh -> [1, 3, 5, 7]
      # Default
      _ -> [1, 3, 5]
    end
  end

  def enharmonic_equal?(chord1, chord2) do
    Enum.all?(Enum.map(Enum.zip(Sonority.to_notes(chord1), Sonority.to_notes(chord2)),
              fn {a, b} -> Note.enharmonic_equal?(a, b) end))
  end

  def root_note(%__MODULE__{inversion: inversion, notes: notes} = chord) do
    index = if inversion == 0, do: 0, else: length(notes) - inversion
    Enum.at(Sonority.to_notes(chord), index)
   end


end
