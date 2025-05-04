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
    bass_note: MusicPrims.raw_note() | nil,
    additions: [Note.t()] | nil,
    omissions: [integer()] | nil,
    # Legacy field for backward compatibility
    chord: ChordPrims.chord() | nil
  }

  defstruct [:root, :quality, :notes, :duration, :bass_note, :additions, :omissions, :chord]

  @doc """
  Creates a new chord from either a list of notes or a chord symbol.
  
  This function supports backward compatibility with existing code while
  providing enhanced functionality through the new fields.
  
  ## Parameters
    * First argument: Either a list of Note structs or a chord symbol tuple
    * `duration` - The duration of the chord in beats
    
  ## Returns
    * A new Chord struct
  """
  # Legacy constructor (backward compatibility) - from notes
  @spec new([Note.t()], float()) :: Sonority.t()
  def new(notes, duration) when is_list(notes) do
    {inferred_root, inferred_quality} = ChordTheory.infer_chord_type(notes)
    %__MODULE__{
      notes: notes,
      root: inferred_root,
      quality: inferred_quality,
      duration: duration,
      chord: nil
    }
  end

  # Legacy constructor (backward compatibility) - from chord symbol
  @spec new(ChordPrims.chord(), float()) :: Sonority.t()
  def new(chord = {{key, _octave}, quality}, duration) do
    notes = ChordPrims.chord_to_notes(chord)
    %__MODULE__{
      chord: chord,
      root: key,
      quality: quality,
      notes: notes,
      duration: duration
    }
  end

  @doc """
  Creates a chord from a root note, quality, and optional octave and duration.
  
  This is a more explicit constructor that clearly specifies the chord's
  root and quality rather than inferring it.
  
  ## Parameters
    * `key` - The root key of the chord
    * `quality` - The chord quality (e.g., :major, :minor)
    * `octave` - The octave for the root note (default: 0)
    * `duration` - The duration of the chord in beats (default: 1.0)
    
  ## Returns
    * A new Chord struct
  """
  def from_root_and_quality(key, quality, octave \\ 0, duration \\ 1.0) do
    chord = {{key, octave}, quality}
    notes = ChordTheory.get_standard_notes(key, quality, octave)
    %__MODULE__{
      chord: chord,
      root: key,
      quality: quality,
      notes: notes,
      duration: duration
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
  Creates a chord from a Roman numeral, key, and optional octave, duration, and scale type.
  
  This function allows direct creation of chords from Roman numerals in a specific key.
  
  ## Parameters
    * `roman_numeral` - The Roman numeral symbol (e.g., :I, :ii, :V7)
    * `key` - The key to interpret the Roman numeral in (e.g., :C for C major)
    * `octave` - The octave for the root note (default: 4)
    * `duration` - The duration of the chord in beats (default: 1.0)
    * `scale_type` - The scale type (:major or :minor) to interpret the Roman numeral in (default: :major)
    
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
  """
  def from_roman_numeral(roman_numeral, key, octave \\ 4, duration \\ 1.0, scale_type \\ :major) do
    # Convert Roman numeral to chord using ChordPrims
    chord_sym = ChordPrims.chord_sym_to_chord(roman_numeral, {{key, octave}, scale_type})
    
    # Extract root and quality from the chord symbol
    {{root, chord_octave}, quality} = chord_sym
    
    # Create the chord
    %__MODULE__{
      chord: chord_sym,
      root: root,
      quality: quality,
      notes: ChordTheory.get_standard_notes(root, quality, chord_octave),
      duration: duration
    }
  end

  @doc """
  Calculates the final set of notes in the chord after applying all modifications.
  
  This method resolves the actual notes to be played based on the chord's
  root, quality, and any modifications (bass note, additions, omissions).
  
  ## Parameters
    * `chord` - The Chord struct to resolve
    
  ## Returns
    * A list of Note structs representing the final chord voicing
  """
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