Bad Sort is a comparison-based sorting algorithm with a worst-case time complexity of *O*(*n³*). James Jensen
contributed it to a Stack Overflow discussion about sorting algorithms with cubic worst-case behavior.

Bad Sort follows selection sort's placement rule: each pass finds the smallest remaining element and swaps it into the
front of the unsorted region. Instead of retaining a running minimum, it tests each candidate position and scans every
later element to determine whether a smaller value exists. Both accepted and rejected candidates can therefore require
a full scan.

The additional verification scans increase the worst-case complexity from selection sort's *O*(*n²*) to *O*(*n³*).
Sorted and reverse-sorted arrays still require *O*(*n²*) work because their verification scans terminate early. The
cubic case occurs when candidate minima repeatedly require long scans before being rejected.

Because it is built entirely from element swaps rather than shifts, Bad Sort shares selection sort's
instability: swapping a far-away minimum into place can carry equal-valued elements past one another, so elements that
compare equal are not guaranteed to retain their original relative order. As with other purpose-built "impractical"
sorts, Bad Sort is used for complexity demonstrations and sorting-algorithm visualizations.
