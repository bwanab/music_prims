defmodule Chord do
  @moduledoc """
  Represents a chord as a sonority with duration.

  A chord can be created either from a list of Note structs or from a chord symbol.
  This module provides functions for creating, modifying, and analyzing chords.
  """

  @type t :: %__MODULE__{
    root: MusicPrims.key() | nil,
    quality: atom() | nil,
    notes: [Note.t()] | nil,
    duration: float(),
    bass_note: Note.t() | nil,
    additions: [Note.t()] | nil,
    omissions: [integer()] | nil,
    inversion: integer(),
    velocity: integer()
  } | Sonority.t()

  defstruct [:root, :quality, :notes, :duration, :bass_note, :additions, :omissions, :inversion, :velocity]

  # Helper function to apply chord inversion
  defp apply_inversion(notes, inversion) when is_integer(inversion) and inversion >= 0 do
    if inversion > 0 and inversion < length(notes) do
      MusicPrims.rotate_notes(notes, inversion)
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

  # Constructor that takes the result of infer_chord_type
  @spec new({{atom(), atom()}, integer()}, float()) :: Sonority.t()
  def new({{key, quality}, inversion}, duration) when is_atom(quality) and is_integer(inversion) do
    # Extract the rootless key and octave from the key
    {root_key, octave} = case key do
      {k, o} when is_atom(k) and is_integer(o) -> {k, o}
      k when is_atom(k) -> {k, 4}  # Default octave if not specified
    end

    # Get standard notes for this chord type
    notes = ChordTheory.get_standard_notes(root_key, quality, octave)

    # Apply inversion if needed
    inverted_notes = apply_inversion(notes, inversion)

    %__MODULE__{
      notes: inverted_notes,
      root: key,
      quality: quality,
      duration: duration,
      inversion: inversion
    }
  end

  # Constructor from notes
  @spec new([Note.t()], float()) :: Sonority.t()
  def new(notes, duration) when is_list(notes) do
    {{inferred_root, inferred_quality}, inversion} = ChordTheory.infer_chord_type(notes)
    %__MODULE__{
      notes: notes,
      root: inferred_root,
      quality: inferred_quality,
      duration: duration,
      inversion: inversion
    }
  end

  # Constructor from chord symbol with optional inversion
  @spec new({{atom(), integer()}, atom()}, float(), integer()) :: Sonority.t()
  def new(chord = {{key, _octave}, quality}, duration, inversion \\ 0) do
    notes = ChordPrims.chord_to_notes(chord)

    # Apply inversion if needed
    inverted_notes = apply_inversion(notes, inversion)

    %__MODULE__{
      root: key,
      quality: quality,
      notes: inverted_notes,
      duration: duration,
      inversion: inversion
    }
  end

  @doc """
  Creates a chord from a root note, quality, and optional octave, duration and inversion.

  ## Parameters
    * `key` - The root key of the chord
    * `quality` - The chord quality (e.g., :major, :minor)
    * `octave` - The octave for the root note (default: 0)
    * `duration` - The duration of the chord in beats (default: 1.0)
    * `inversion` - The inversion degree (0 = root position, 1 = first, etc.) (default: 0)

  ## Returns
    * A new Chord struct
  """
  @spec new_from_root(atom(), atom(), integer(), float(), integer()) :: Sonority.t()
  def new_from_root(key, quality, octave \\ 0, duration \\ 1.0, inversion \\ 0) do
    notes = ChordTheory.get_standard_notes(key, quality, octave)

    # Apply inversion if needed
    inverted_notes = apply_inversion(notes, inversion)

    %__MODULE__{
      root: key,
      quality: quality,
      notes: inverted_notes,
      duration: duration,
      inversion: inversion
    }
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
  Creates a chord from a Roman numeral, key, and optional octave, duration, scale type, and inversion.

  This function allows direct creation of chords from Roman numerals in a specific key.

  ## Parameters
    * `roman_numeral` - The Roman numeral symbol (e.g., :I, :ii, :V7)
    * `key` - The key to interpret the Roman numeral in (e.g., :C for C major)
    * `octave` - The octave for the root note (default: 4)
    * `duration` - The duration of the chord in beats (default: 1.0)
    * `scale_type` - The scale type (:major or :minor) to interpret the Roman numeral in (default: :major)
    * `inversion` - The inversion degree (0 = root position, 1 = first, etc.) (default: 0)

  ## Returns
    * A new Chord struct

  ## Examples
      # Creates a C major chord (I in C major) in octave 4 with duration 4.0
      iex> chord = Chord.from_roman_numeral(:I, :C, 4, 4.0)
      iex> chord.root
      :C
      iex> chord.quality
      :major

      # Creates a D dominant seventh chord (V7 in G major) in octave 3 with duration 2.0
      iex> chord = Chord.from_roman_numeral(:V7, :G, 3, 2.0)
      iex> chord.root
      :D
      iex> chord.quality
      :dominant_seventh

      # Creates a D# major chord (III in C minor) in octave 4 with duration 1.0
      # Note: D# is enharmonic with Eb but our implementation uses D#
      iex> chord = Chord.from_roman_numeral(:III, :C, 4, 1.0, :minor)
      iex> chord.root
      :D!
      iex> chord.quality
      :major

      # Creates a first inversion C major chord (I⁶ in C major) in octave 4 with duration 1.0
      iex> chord = Chord.from_roman_numeral(:I, :C, 4, 1.0, :major, 1)
      iex> chord.root
      :C
      iex> chord.quality
      :major
      iex> chord.inversion
      1
  """
  def from_roman_numeral(roman_numeral, key, octave \\ 4, duration \\ 1.0, scale_type \\ :major, inversion \\ 0) do
    # Convert Roman numeral to chord using ChordPrims
    chord_sym = ChordPrims.chord_sym_to_chord(roman_numeral, {{key, octave}, scale_type})

    # Extract root and quality from the chord symbol
    {{root, chord_octave}, quality} = chord_sym

    # Get standard notes for this chord
    notes = ChordTheory.get_standard_notes(root, quality, chord_octave)

    # Apply inversion if needed
    inverted_notes = apply_inversion(notes, inversion)

    # Create the chord
    %__MODULE__{
      root: root,
      quality: quality,
      notes: inverted_notes,
      duration: duration,
      inversion: inversion
    }
  end

  @doc """
  Checks if the chord's root is enharmonically equal to the specified note or key.

  This is useful when working with chord progressions where you need to check for
  chords by root, but want to handle enharmonic equivalences properly.

  ## Parameters
    * `chord` - The Chord struct to check
    * `note` - The note or key to compare against, either as a note tuple or atom

  ## Examples

      iex> chord = Chord.from_roman_numeral(:III, :C, 4, 1.0, :minor)
      iex> Chord.has_root_enharmonic_with?(chord, :Eb)
      true

      iex> chord = Chord.from_roman_numeral(:III, :C, 4, 1.0, :minor)
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

  def to_notes(chord) do
    # Start with base notes
    base_notes = chord.notes || []

    # Apply omissions if any
    notes_after_omissions = if chord.omissions do
      degrees = ChordTheory.chord_degrees(chord.root, chord.quality)
      indices_to_remove = Enum.map(chord.omissions, fn deg ->
        Enum.find_index(degrees, fn d -> d == deg end)
      end) |> Enum.reject(&is_nil/1)

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
    notes_with_additions
  end

  # Implement the Sonority protocol
  defimpl Sonority do
    def duration(chord), do: chord.duration
    def type(_), do: :chord
  end
end
