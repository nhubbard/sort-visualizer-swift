Flan Sort combines three-way partitioning with a gapped library sort. It chooses a pivot from a
median of three ninthers, partitions the active range into values below, equal to, and above the
pivot, then sorts the smaller unequal side while using the larger side as working space. The
process repeats on the remaining side until a small range can be finished by binary insertion.

Within a sorted side, library sort keeps ordered elements separated by fourteen-slot gaps. Binary
search finds the appropriate gap; when a gap fills, elements are shifted or the gaps are rebuilt.
Equal-valued elements may be spread among matching gaps to avoid concentrating all duplicates in
one place. A small heap then merges the sorted runs into the available destination. Gap selection
is pseudorandom but seeded from the input, so recording the same input always produces the same
sequence of operations.

The average comparison count is O(n log n), while unfavorable layouts can require O(n^2) work
without the initial shuffle normally used to protect this family of algorithms. Apart from a
fixed number of run-head and heap entries, it uses the input array as its workspace. Its swaps,
partitioning, and gap insertion do not preserve the input order of equal values, so it is not
stable.
