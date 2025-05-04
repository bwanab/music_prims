# Chord Module Migration Guide

This guide explains how to migrate from the old Chord implementation to the new enhanced Chord module.

## Overview of Changes

The Chord module has been enhanced with more explicit chord representation capabilities:

- Explicit root and quality fields
- Support for slash chords via bass note
- Support for chord extensions and alterations
- Ability to omit specific chord tones
- More intuitive constructors

## Backward Compatibility

All existing code will continue to work as-is. The `Chord.new/2` function maintains the same API:

```elixir
# Create from notes (still works)
Chord.new([note1, note2, note3], 1.0)

# Create from chord symbol (still works)
Chord.new({{:C, 4}, :major}, 1.0)
```

## Using the Enhanced API

For new code, we recommend using the more explicit constructors and modifiers:

```elixir
# Create a basic C major chord
c_major = Chord.from_root_and_quality(:C, :major)

# Create a C/G chord (C major with G in the bass)
c_over_g = Chord.from_root_and_quality(:C, :major) |> Chord.with_bass({:G, 3})

# Create a Cadd9 chord (C major with added 9th)
c_add9 = Chord.from_root_and_quality(:C, :major) 
         |> Chord.with_additions([Note.new({:D, 5})])

# Create a C major chord without the fifth
c_no5 = Chord.from_root_and_quality(:C, :major) |> Chord.with_omissions([5])
```

## Creating Chords from Roman Numerals

The new `from_roman_numeral` function allows you to directly create chords from Roman numerals in a specific key:

```elixir
# Create a I chord in C major (C major chord)
I_chord = Chord.from_roman_numeral(:I, :C, 4, 1.0)

# Create a V7 chord in G major (D7 chord)
V7_chord = Chord.from_roman_numeral(:V7, :G, 3, 2.0)

# Create a ii chord in F major (G minor chord)
ii_chord = Chord.from_roman_numeral(:ii, :F, 4, 4.0)

# You can also specify :minor as the scale type for Roman numerals in minor keys
# Create a III chord in C minor (Eb major chord)
III_chord = Chord.from_roman_numeral(:III, :C, 4, 4.0, :minor)
```

This is especially useful when creating chord progressions using Roman numeral analysis:

```elixir
# Create a I-IV-V-I progression in C major
progression = [
  Chord.from_roman_numeral(:I, :C, 4, 4.0),
  Chord.from_roman_numeral(:IV, :C, 4, 4.0),
  Chord.from_roman_numeral(:V, :C, 4, 4.0),
  Chord.from_roman_numeral(:I, :C, 4, 4.0)
]

# Create a i-iv-V-i progression in A minor
minor_progression = [
  Chord.from_roman_numeral(:i, :A, 4, 4.0, :minor),
  Chord.from_roman_numeral(:iv, :A, 4, 4.0, :minor),
  Chord.from_roman_numeral(:V, :A, 4, 4.0, :minor),
  Chord.from_roman_numeral(:i, :A, 4, 4.0, :minor)
]
```

## Converting to Notes

When you need to get the actual notes of a chord after modifications:

```elixir
# Get the notes from a modified chord
notes = Chord.from_root_and_quality(:C, :major)
        |> Chord.with_omissions([5])
        |> Chord.to_notes()
```

## Combining with Other Musical Elements

The enhanced Chord struct still implements the Sonority protocol, so it can be
used alongside Note and Rest in any sequence of musical elements.

## Example: Building a Complex Chord Progression

```elixir
# Create a jazz II-V-I progression in C with some voicing choices
progression = [
  # Dm7 - no fifth, add 9th
  Chord.from_root_and_quality(:D, :minor_seventh)
       |> Chord.with_omissions([5])
       |> Chord.with_additions([Note.new({:E, 4})]),
       
  # G7 - as a G7/B (3rd in bass)
  Chord.from_root_and_quality(:G, :dominant_seventh)
       |> Chord.with_bass({:B, 3}),
       
  # Cmaj7 - complete chord
  Chord.from_root_and_quality(:C, :major_seventh)
]

# Convert to notes for playback
chord_notes = Enum.map(progression, &Chord.to_notes/1)
```

## Integration with MIDI Libraries

When working with MIDI libraries like elixir-midifile, you can use the enhanced Chord functionality:

```elixir
# Create a track with a chord progression using root and quality
chords = [
  Chord.from_root_and_quality(:C, :major, 4, 1.0),
  Chord.from_root_and_quality(:F, :major, 4, 1.0),
  Chord.from_root_and_quality(:G, :dominant_seventh, 4, 1.0),
  Chord.from_root_and_quality(:C, :major, 4, 1.0)
]

# The chord's to_notes method will be used when necessary
track = Midifile.Track.new("Chord Progression", chords)
```

Or, you can create progressions more intuitively using Roman numerals:

```elixir
# Create a chord progression in C major using Roman numerals
chords = [
  Chord.from_roman_numeral(:I, :C, 4, 4.0),   # C major
  Chord.from_roman_numeral(:IV, :C, 4, 4.0),  # F major
  Chord.from_roman_numeral(:V7, :C, 4, 4.0),  # G dominant 7th
  Chord.from_roman_numeral(:I, :C, 4, 4.0)    # C major
]

# Create a random progression with 10 chords
random_numerals = ChordPrims.random_progression(10, 1)
random_chords = Enum.map(random_numerals, fn numeral ->
  Chord.from_roman_numeral(numeral, :C, 4, 4.0)
end)
```