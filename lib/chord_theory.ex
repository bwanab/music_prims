defmodule ChordTheory do

  @moduledoc """
  Functions for chord theory, analysis, and manipulation.

  This module provides utilities for working with chord structures,
  including generating notes for chord symbols, inferring chord types
  from notes, and manipulating chord voicings.
  """

  @doc """
  Generates the standard notes for a given chord type.

  ## Parameters
    * `key` - The root key of the chord
    * `quality` - The chord quality (e.g., :major, :minor, :dominant_seventh)
    * `octave` - The octave for the root note (default: 0)

  ## Returns
    * A list of Note structs representing the chord
  """
  def get_standard_notes(key, quality, octave \\ 0) do
    case quality do
      :major -> Chord.major_chord(key, octave)
      :minor -> Chord.minor_chord(key, octave)
      :diminished -> Chord.diminished_chord(key, octave)
      :augmented -> Chord.augmented_chord(key, octave)
      :dominant_seventh -> Chord.dominant_seventh_chord(key, octave)
      :major_seventh -> Chord.major_seventh_chord(key, octave)
      :minor_seventh -> Chord.minor_seventh_chord(key, octave)
      :half_diminished_seventh -> Chord.half_diminshed_seventh_chord(key, octave)
      :diminished_seventh -> Chord.diminished_seventh_chord(key, octave)
      :minor_major_seventh -> Chord.minor_major_seventh_chord(key, octave)
      :augmented_major_seventh -> Chord.augmented_major_seventh_chord(key, octave)
      :augmented_seventh -> Chord.augmented_seventh_chord(key, octave)
      # Default to major if unknown quality
      _ -> Chord.major_chord(key, octave)
    end
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
    get_note_nums = fn notes ->
      note_nums = Enum.map(notes, &Note.note_to_midi(&1).note_number)
      min = Enum.min(note_nums)
      Enum.map(note_nums, &(&1 - min))
    end

    # Try different rotations of the notes to find a known chord pattern
    matches =
      Enum.map(
        0..(length(notes) - 1),
        fn rotation_index ->
          rotated_notes = Note.rotate_notes(notes, rotation_index)
          intervals = get_note_nums.(rotated_notes)
          chord_type = Map.get(MusicPrims.chord_interval_map(), intervals)
          {rotation_index, chord_type, rotated_notes}
        end
      )
      |> Enum.filter(fn {_i, chord_type, _rotated_notes} -> !is_nil(chord_type) end)

    if length(matches) > 0 do
      # Get the first match
      {rotation_index, chord_type, rotated_notes} = Enum.at(matches, 0)

      # The root is the first note of the rotated collection that matched a chord pattern
      root_note = Enum.at(rotated_notes, 0).note

      # The inversion is the rotation index used to transform the input notes
      # to get to root position (when rotation_index=0)
      inversion = rotation_index

      {{root_note, chord_type}, inversion}
    else
      # Return a default value if no matches found
      # Using the first note as root, assuming major quality, and root position
      {{List.first(notes).note, :major}, 0}
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

  # These helper functions were part of the previous implementation
  # but are no longer used with the new approach.
  # They are kept here as comments for reference in case they're needed in the future.

  # # Helper function to match chord patterns regardless of inversion
  # defp match_chord_pattern?(notes, pattern) do
  #   # Normalize to C root for pattern matching
  #   root_note = List.first(notes)
  #   target_intervals = normalize_to_intervals(notes, root_note)
  #   pattern_intervals = normalize_to_intervals(pattern, List.first(pattern))
  #
  #   # Compare interval patterns
  #   Enum.sort(target_intervals) == Enum.sort(pattern_intervals)
  # end
  #
  # # Convert notes to semitone intervals from the root
  # defp normalize_to_intervals(notes, root) do
  #   Enum.map(notes, fn note ->
  #     # This is a simplified implementation
  #     # In a real implementation, you'd calculate actual semitone distances
  #     # For now, just returning the notes as their position in the chromatic scale
  #     position_of(note) - position_of(root)
  #   end)
  # end
  #
  # # Get position in chromatic scale (simplified)
  # defp position_of(note) do
  #   case note do
  #     :C -> 0
  #     :C! -> 1
  #     :Db -> 1
  #     :D -> 2
  #     :D! -> 3
  #     :Eb -> 3
  #     :E -> 4
  #     :F -> 5
  #     :F! -> 6
  #     :Gb -> 6
  #     :G -> 7
  #     :G! -> 8
  #     :Ab -> 8
  #     :A -> 9
  #     :A! -> 10
  #     :Bb -> 10
  #     :B -> 11
  #     _ -> 0
  #   end
  # end
end
