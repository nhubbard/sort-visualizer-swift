*From Wikipedia, the free encyclopedia*

Gnome sort (nicknamed stupid sort) is a variation of the insertion sort sorting algorithm that does not use nested
loops. Gnome sort was originally proposed by Iranian computer scientist Hamid Sarbazi-Azad (professor of Computer
Science and Engineering at Sharif University of Technology) in 2000. The sort was first called *stupid sort* (not to be
confused with bogosort), and then later described by [Dick Grune](https://en.wikipedia.org/wiki/Dick_Grune) and named
*gnome sort*.

Gnome sort performs at least as many comparisons as insertion sort and has the
same [asymptotic runtime](https://en.wikipedia.org/wiki/Asymptotic_run_time) characteristics. Gnome sort works by
building a sorted list one element at a time, getting each item to the proper place in a series of swaps. The average
running time is O(n²) but tends towards O(n) if the list is initially almost sorted.

[Dick Grune](https://en.wikipedia.org/wiki/Dick_Grune) explained the method through the image of a Dutch
[garden gnome](https://en.wikipedia.org/wiki/Garden_gnome) sorting a line of
[flower pots](https://en.wikipedia.org/wiki/Flowerpot). The gnome compares the next pot with the previous one. If they
are in order, the gnome steps forward; otherwise, the pots are swapped and the gnome steps backward. At the beginning
of the line the gnome can only step forward, and after reaching the end the work is complete.
