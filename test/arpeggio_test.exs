defmodule ArpeggioTest do
  use ExUnit.Case
  doctest Arpeggio

  describe "Arpeggio.new/3" do
    test "creates an arpeggio from a chord and pattern" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :up, 2)

      assert arpeggio.chord == chord
      assert arpeggio.pattern == :up
      assert arpeggio.duration == 2
    end
  end

  describe "Sonority.to_notes/1" do
    test "converts up pattern to notes" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :up, 4)
      notes = Sonority.to_notes(arpeggio)

      assert length(notes) == 3
      assert Enum.map(notes, & &1.note) == [:C, :E, :G]
      assert Enum.all?(notes, & &1.duration == 4)
    end

    test "converts down pattern to notes" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :down, 4)
      notes = Sonority.to_notes(arpeggio)

      assert length(notes) == 3
      assert Enum.map(notes, & &1.note) == [:G, :E, :C]
      assert Enum.all?(notes, & &1.duration == 4)
    end

    test "converts up_down pattern to notes" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :up_down, 4)
      notes = Sonority.to_notes(arpeggio)

      assert length(notes) == 5
      assert Enum.map(notes, & &1.note) == [:C, :E, :G, :E, :C]
      assert Enum.all?(notes, & &1.duration == 4)
    end

    test "converts down_up pattern to notes" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :down_up, 4)
      notes = Sonority.to_notes(arpeggio)

      assert length(notes) == 5
      assert Enum.map(notes, & &1.note) == [:G, :E, :C, :E, :G]
      assert Enum.all?(notes, & &1.octave == 4)
      assert Enum.all?(notes, & &1.duration == 4)
    end

    test "converts explicit pattern to notes" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, [2, 1, 3], 4)
      notes = Sonority.to_notes(arpeggio)

      assert length(notes) == 3
      assert Enum.map(notes, & &1.note) ==  [:E, :C, :G]
      assert Enum.all?(notes, & &1.duration == 4)
    end
  end

  describe "Arpeggio.repeat/2" do
    test "repeats an arpeggio the specified number of times" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :up, 4)
      notes = Arpeggio.repeat(arpeggio, 2)

      assert length(notes) == 6
      assert Enum.map(notes, & &1.note) == [:C, :E, :G, :C, :E, :G]
      assert Enum.all?(notes, & &1.duration == 4)
    end
  end

  describe "Sonority protocol implementation" do
    test "returns correct duration" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :up, 4)
      assert Sonority.duration(arpeggio) == 4
    end

    test "returns correct type" do
      chord = Chord.new(:C, :major, octave: 4, duration: 1)
      arpeggio = Arpeggio.new(chord, :up, 4)
      assert Sonority.type(arpeggio) == :arpeggio
    end
  end

  defmodule TD do
      def build_chords(progression, key, octave, duration, channel) do
        Enum.map(progression, fn roman_numeral ->
          # Create chord using the new from_roman_numeral function
          c = Chord.from_roman_numeral(roman_numeral, key, octave: octave, duration: duration, channel: channel)
          notes = Sonority.to_notes(c)
          all_notes = notes ++ Note.bump_octave(notes, :up)
          Chord.new(all_notes, duration)
        end)
      end

      # @spec do_arpeggio_progression([atom()], atom(), boolean(), String.t(), atom()) :: :ok
      def do_arpeggio_progression() do
        key = :C
        progression = [:I, :vi, :iii]

        chord_channel = 0
        #arpeggio_channel = 1
        bass_channel = 2
        all_chords = build_chords(progression, key, 4, 2, chord_channel)

        patterns = [
          [4,1,2,3],
          [1,2,4,3],
          [2,3,4,2],
          [1,4,3,1],
          [1,2,3,4],
          [1,4,3,1],
          [1,2,3,2],
          [2,3,4,1]
        ]

        all_arpeggios = Enum.map(Enum.zip(all_chords, patterns), fn {c, p} -> Arpeggio.new(c, p, 0.5) end)

        bass_patterns = [
          [1,4],
          [1,2],
          [1,3],
          [1,3],
          [1,2],
          [1,4],
          [1,2],
          [1,3]
        ]


        bass_chords = build_chords(progression, key, 2, 1, bass_channel)

        bass_arpeggios = Enum.map(Enum.zip(bass_chords, bass_patterns), fn {c, p} ->
          Arpeggio.new(c, p, 1)
        end)
        Enum.flat_map(all_arpeggios, fn a -> Sonority.to_notes(a) end) ++
        Enum.flat_map(bass_arpeggios, fn a -> Sonority.to_notes(a) end) ++
        Enum.flat_map(all_chords, fn a -> Sonority.to_notes(a) end)
      end
  end

  describe "lots of manipulations test" do
    test "returns correct sonarities" do
      everything = TD.do_arpeggio_progression()
      # IO.inspect(everything)
      assert everything == [
        %Note{note: :C, octave: 5, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :C, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :E, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :G, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :A, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :C, octave: 5, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :A, octave: 5, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :E, octave: 5, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :G, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :B, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :E, octave: 5, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :G, octave: 4, duration: 0.5, velocity: 100, channel: 0},
        %Note{note: :C, octave: 2, duration: 1, velocity: 100, channel: 0},
        %Note{note: :C, octave: 3, duration: 1, velocity: 100, channel: 0},
        %Note{note: :A, octave: 2, duration: 1, velocity: 100, channel: 0},
        %Note{note: :C, octave: 3, duration: 1, velocity: 100, channel: 0},
        %Note{note: :E, octave: 2, duration: 1, velocity: 100, channel: 0},
        %Note{note: :B, octave: 2, duration: 1, velocity: 100, channel: 0},
        %Note{note: :C, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :E, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :G, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :C, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :E, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :G, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :A, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :C, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :E, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :A, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :C, octave: 6, duration: 2, velocity: 100, channel: 0},
        %Note{note: :E, octave: 6, duration: 2, velocity: 100, channel: 0},
        %Note{note: :E, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :G, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :B, octave: 4, duration: 2, velocity: 100, channel: 0},
        %Note{note: :E, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :G, octave: 5, duration: 2, velocity: 100, channel: 0},
        %Note{note: :B, octave: 5, duration: 2, velocity: 100, channel: 0}
      ]
    end
  end
end
