*From Wikipedia, the free encyclopedia*

Gnome sort (nicknamed stupid sort) is a variation of the insertion sort sorting algorithm that does not use nested loops. Gnome sort was originally proposed by Iranian computer scientist Hamid Sarbazi-Azad (professor of Computer Science and Engineering at Sharif University of Technology) in 2000. The sort was first called *stupid sort* (not to be confused with bogosort), and then later described by [Dick Grune](https://en.wikipedia.org/wiki/Dick_Grune) and named *gnome sort*.

Gnome sort performs at least as many comparisons as insertion sort and has the same [asymptotic runtime](https://en.wikipedia.org/wiki/Asymptotic_run_time) characteristics. Gnome sort works by building a sorted list one element at a time, getting each item to the proper place in a series of swaps. The average running time is O(n²) but tends towards O(n) if the list is initially almost sorted.

[Dick Grune](https://en.wikipedia.org/wiki/Dick_Grune) described the sorting method with the following story:

> Gnome Sort is based on the technique used by the standard Dutch [Garden Gnome](https://en.wikipedia.org/wiki/Garden_gnome) (Du.: [tuinkabouter](https://nl.wikipedia.org/wiki/tuinkabouter)).

> Here is how a garden gnome sorts a line of [flower pots](https://en.wikipedia.org/wiki/Flowerpot).

> Basically, he looks at the flower pot next to him and the previous one; if they are in the right order he steps one pot forward, otherwise, he swaps them and steps one pot backward.

> Boundary conditions: if there is no previous pot, he steps forwards; if there is no pot next to him, he is done.
