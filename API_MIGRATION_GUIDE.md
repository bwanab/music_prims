# API Migration Guide: Scale and Chord Function Changes

This document outlines the breaking changes introduced in the latest commit that converted Scale and Chord functions from positional default parameters to keyword arguments and added channel parameter support.

## Overview

**Commit:** Convert Scale and Chord functions to keyword arguments and add channel parameter support

**Impact:** This is a **major breaking change** affecting all Scale and Chord function calls in dependent projects.

## Key Changes

### 1. Positional Parameters → Keyword Arguments
All functions that previously used positional default parameters now use keyword argument lists.

### 2. Added Channel Parameter Support
All functions now support a `:channel` parameter for MIDI channel specification.

### 3. Parameter Order Changes
Some functions had their parameter order changed (notably `modal_scale`).

---

## Scale Module Changes

### `Scale.new/3` → `Scale.new/2`
**Before:**
```elixir
Scale.new(:C)                    # Uses defaults: quality=:major, octave=3
Scale.new(:C, :minor)            # Uses default: octave=3  
Scale.new(:C, :major, 4)         # All parameters specified
```

**After:**
```elixir
Scale.new(:C)                                    # Uses defaults
Scale.new(:C, quality: :minor)                   # Specify quality
Scale.new(:C, quality: :major, octave: 4)        # All parameters
Scale.new(:C, channel: 5)                        # New: channel support
Scale.new(:C, quality: :minor, octave: 4, channel: 2)  # All options
```

### `Scale.major_scale/2` → `Scale.major_scale/2`
**Before:**
```elixir
Scale.major_scale(:C)      # Uses default octave=0
Scale.major_scale(:C, 1)   # Octave specified
```

**After:**
```elixir
Scale.major_scale(:C)                     # Uses default octave=0
Scale.major_scale(:C, octave: 1)          # Octave specified
Scale.major_scale(:C, channel: 3)         # New: channel support
Scale.major_scale(:C, octave: 1, channel: 3)  # Both parameters
```

### `Scale.minor_scale/2` → `Scale.minor_scale/2`
**Before:**
```elixir
Scale.minor_scale(:A)      # Uses default octave=0
Scale.minor_scale(:A, 1)   # Octave specified
```

**After:**
```elixir
Scale.minor_scale(:A)                     # Uses default octave=0
Scale.minor_scale(:A, octave: 1)          # Octave specified
Scale.minor_scale(:A, channel: 2)         # New: channel support
Scale.minor_scale(:A, octave: 1, channel: 2)  # Both parameters
```

### `Scale.blues_scale/2` → `Scale.blues_scale/2`
**Before:**
```elixir
Scale.blues_scale(:E)      # Uses default octave=0
Scale.blues_scale(:E, 2)   # Octave specified
```

**After:**
```elixir
Scale.blues_scale(:E)                     # Uses default octave=0
Scale.blues_scale(:E, octave: 2)          # Octave specified
Scale.blues_scale(:E, channel: 1)         # New: channel support
```

### `Scale.pent_scale/2` → `Scale.pent_scale/2`
**Before:**
```elixir
Scale.pent_scale(:G)       # Uses default octave=0
Scale.pent_scale(:G, 3)    # Octave specified
```

**After:**
```elixir
Scale.pent_scale(:G)                      # Uses default octave=0
Scale.pent_scale(:G, octave: 3)           # Octave specified
Scale.pent_scale(:G, channel: 4)          # New: channel support
```

### `Scale.modal_scale/3` → `Scale.modal_scale/3` ⚠️ PARAMETER ORDER CHANGED
**Before:**
```elixir
Scale.modal_scale(:D, 1, :dorian)         # key, octave, mode
```

**After:**
```elixir
Scale.modal_scale(:D, :dorian, octave: 1)           # key, mode, opts
Scale.modal_scale(:D, :dorian, octave: 1, channel: 2)  # With channel
```

### `Scale.build_note_seq/3` → `Scale.build_note_seq/3`
**Before:**
```elixir
Scale.build_note_seq(:C, [0, 4, 7])       # Uses default octave=0
Scale.build_note_seq(:C, [0, 4, 7], 2)    # Octave specified
```

**After:**
```elixir
Scale.build_note_seq(:C, [0, 4, 7])                      # Uses defaults
Scale.build_note_seq(:C, [0, 4, 7], octave: 2)           # Octave specified
Scale.build_note_seq(:C, [0, 4, 7], channel: 3)          # New: channel support
```

### `Scale.chromatic_scale/2` → `Scale.chromatic_scale/2`
**Before:**
```elixir
Scale.chromatic_scale(:F, 3)              # key, octave
```

**After:**
```elixir
Scale.chromatic_scale(:F, octave: 3)               # Keyword arguments
Scale.chromatic_scale(:F, octave: 3, channel: 1)   # With channel
```

---

## Chord Module Changes

### All Chord Building Functions
The following functions all follow the same pattern change:

- `major_chord/2`, `minor_chord/2`, `augmented_chord/2`, `diminished_chord/2`
- `dominant_seventh_chord/2`, `major_seventh_chord/2`, `minor_seventh_chord/2`
- `half_diminshed_seventh_chord/2`, `diminished_seventh_chord/2`
- `minor_major_seventh_chord/2`, `augmented_major_seventh_chord/2`, `augmented_seventh_chord/2`

**Before:**
```elixir
Chord.major_chord(:C)          # Uses default octave=0
Chord.major_chord(:C, 2)       # Octave specified
Chord.minor_chord(:A, 1)       # All similar patterns
```

**After:**
```elixir
Chord.major_chord(:C)                        # Uses default octave=0
Chord.major_chord(:C, octave: 2)             # Octave specified
Chord.major_chord(:C, channel: 5)            # New: channel support
Chord.major_chord(:C, octave: 2, channel: 5) # Both parameters

Chord.minor_chord(:A, octave: 1)             # Similar for all chord functions
```

### `Chord.chord_to_notes/1` → `Chord.chord_to_notes/2` ⚠️ SIGNATURE CHANGED
**Before:**
```elixir
Chord.chord_to_notes({{:C, 0}, :major})      # Tuple-based input
Chord.chord_to_notes({:C, :major})           # Simplified tuple
```

**After:**
```elixir
Chord.chord_to_notes(:C, scale_type: :major)                # Key + options
Chord.chord_to_notes(:C, octave: 0, scale_type: :major)     # With octave
Chord.chord_to_notes(:C, octave: 0, scale_type: :major, channel: 2)  # All options
```

### `Chord.get_standard_notes/3` → `Chord.get_standard_notes/3`
**Before:**
```elixir
Chord.get_standard_notes(:F, :major, 2)     # key, quality, octave
```

**After:**
```elixir
Chord.get_standard_notes(:F, :major, octave: 2)           # Keyword arguments
Chord.get_standard_notes(:F, :major, octave: 2, channel: 1)  # With channel
```

---

## Migration Steps

### 1. Update Scale Function Calls

Replace all positional arguments with keyword arguments:

```bash
# Find all scale function calls with positional arguments
grep -r "major_scale.*," your_project/
grep -r "minor_scale.*," your_project/
grep -r "modal_scale.*," your_project/
# etc.
```

### 2. Fix Modal Scale Parameter Order

**Critical:** `modal_scale` parameter order changed!

```elixir
# OLD: modal_scale(key, octave, mode)
modal_scale(:D, 1, :dorian)

# NEW: modal_scale(key, mode, opts)
modal_scale(:D, :dorian, octave: 1)
```

### 3. Update Chord Function Calls

Replace positional octave arguments with keyword arguments:

```elixir
# OLD
major_chord(:C, 2)
minor_seventh_chord(:G, 1)

# NEW  
major_chord(:C, octave: 2)
minor_seventh_chord(:G, octave: 1)
```

### 4. Update chord_to_notes Calls

This function completely changed its signature:

```elixir
# OLD
result = Enum.map(chord_tuples, &chord_to_notes/1)

# NEW
result = Enum.map(chord_tuples, fn {{key, octave}, scale_type} ->
  chord_to_notes(key, octave: octave, scale_type: scale_type)
end)
```

### 5. Add Channel Support (Optional)

Take advantage of the new channel parameter:

```elixir
# Example: Different instruments on different channels
bass_notes = major_scale(:C, octave: 2, channel: 1)      # Bass channel
melody_notes = major_scale(:C, octave: 4, channel: 2)    # Melody channel
chord_notes = major_chord(:C, octave: 3, channel: 3)     # Chord channel
```

---

## Default Values

### Scale Functions
- `:octave` → `0` (except `Scale.new` and `chromatic_scale` which default to `3`)
- `:channel` → `0`
- `:quality` → `:major` (Scale.new only)

### Chord Functions  
- `:octave` → `0`
- `:channel` → `0`
- `:scale_type` → `:major` (chord_to_notes only)

---

## Testing Migration

Run your test suite after making changes:

```bash
mix test
```

Common error patterns to look for:
- `FunctionClauseError` - Usually indicates positional arguments still being used
- `Keyword.get/3` errors - Indicates a keyword list was expected but got a primitive value

---

## Benefits of This Change

1. **Consistency:** All functions now use the same keyword argument pattern
2. **Extensibility:** Easy to add new parameters without breaking changes
3. **Clarity:** Function calls are more self-documenting
4. **Channel Support:** Full MIDI channel support throughout the library
5. **Flexibility:** Parameters can be specified in any order

---

## Questions?

If you encounter issues during migration, check:

1. Parameter order (especially for `modal_scale`)
2. Tuple destructuring for `chord_to_notes`
3. Missing keyword argument conversions
4. Function arity changes in function references