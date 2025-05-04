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

For new code, we recommend using the more explicit constructor and modifiers:

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

When working with MIDI libraries like elixir-midifile, you can still use the enhanced Chord functionality:

```elixir
# Create a track with a chord progression
chords = [
  Chord.from_root_and_quality(:C, :major, 4, 1.0),
  Chord.from_root_and_quality(:F, :major, 4, 1.0),
  Chord.from_root_and_quality(:G, :dominant_seventh, 4, 1.0),
  Chord.from_root_and_quality(:C, :major, 4, 1.0)
]

# The chord's to_notes method will be used when necessary
track = Midifile.Track.new("Chord Progression", chords)
```