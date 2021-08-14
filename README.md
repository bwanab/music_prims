
# Table of Contents



This is a collection of music primitives implemented in Elixir.

Definitions:

-   The keys at present are :A,:A!,:B,:C,:C!&#x2026;:G,:G! where the ! represents the sharp sign. It handles flats with :A,:Bb,:B,:C,:Db&#x2026; where flats are normally
    expected.

-   Note is a tuple pair {key, octave}.

-   Chord is a tuple pair {key, chord<sub>type</sub>}

Examples:

-   major<sub>scale</sub>(:C) == [C: 0, D: 0, E: 0, F: 0, G: 0, A: 0, B: 0]
-   major<sub>scale</sub>(:F) == [F: 0, G: 0, A: 0, Bb: 0, C: 1, D: 1, E: 1]
-   minor<sub>scale</sub>(:A) == [A: 0, B: 0, C: 1, D: 1, E: 1, F: 1, G: 1]
-   blues<sub>scale</sub>(:A) == [A: 0, C: 1, D: 1, D!: 1, E: 1, G: 1]
-   key(:major, 0, :sharps) == :C
-   key(:major, 3, :sharps) == :A
-   key(:major, 3, :flats) == :Eb
-   next<sub>fifth</sub>({:C, 1}) == {:G, 1}
-   next<sub>fifth</sub>({:G, 1}) == {:D, 2}
-   chromatic<sub>scale</sub>({:C, 0}) |> Enum.take(4) = [C: 0, C!: 0, D: 0, D!: 0]
-   major<sub>chord</sub>(:F) == [F: 0, A: 0, C: 1]
-   major<sub>chord</sub>(:F) |> first<sub>inversion</sub> == [A: 0, C: 1, F: 1]
-   major<sub>seventh</sub><sub>chord</sub>(:F) == [F: 0, A: 0, C: 1, E: 1]
-   major<sub>seventh</sub><sub>chord</sub>(:F) |> to<sub>midi</sub> == [29, 33, 36, 40]
-   chord<sub>syms</sub><sub>to</sub><sub>chords</sub>([:I, :IV, :vi, :V], :C) == [{:C, :major}, {:F, :major}, {:A, :minor}, {:G, :major}]
-   chord<sub>syms</sub><sub>to</sub><sub>chords</sub>([:I, :IV, :vi, :V], :G) == [G: :major, C: :major, E: :minor, D: :major]
-   Enum.map(chord<sub>syms</sub><sub>to</sub><sub>chords</sub>([:I, :IV, :vi, :V], :G), &(chord<sub>to</sub><sub>notes</sub>(&1))) == [
      [G: 1, B: 1, D: 2],
      [C: 1, E: 1, G: 1],
      [E: 1, G: 1, B: 1],
      [D: 1, F!: 1, A: 1]
    ]
-   Enum.map(chord<sub>syms</sub><sub>to</sub><sub>chords</sub>([:I, :IV, :vi, :V], :G), &(chord<sub>to</sub><sub>notes</sub>(&1) |> to<sub>midi</sub> |> Enum.map(fn a -> to<sub>string</sub>(a) end))) == [[&ldquo;43&rdquo;, &ldquo;47&rdquo;, &ldquo;50&rdquo;], [&ldquo;36&rdquo;, &ldquo;40&rdquo;, &ldquo;43&rdquo;], [&ldquo;40&rdquo;, &ldquo;43&rdquo;, &ldquo;47&rdquo;], [&ldquo;38&rdquo;, &ldquo;42&rdquo;, &ldquo;45&rdquo;]]

