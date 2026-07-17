*From Wikipedia, the free encyclopedia*

Strand sort is a recursive sorting algorithm that repeatedly picks sorted sub-sequences, called **strands**, out of an
unsorted list and merges them into a single sorted output list. A strand is a run of elements that is already in
ascending order, but its elements need not be contiguous within the original list — the algorithm scans forward and
simply skips over any element that is smaller than the last one it picked, leaving that element behind for a later pass.

The algorithm works by repeating the following steps until the input list is empty: first, traverse the remaining
unsorted list from front to back, moving every element that continues an ascending run into a new sub-list (this
sub-list is itself sorted by construction, since only non-decreasing elements are appended to it) while leaving the rest
behind in the original list; second, [merge](https://en.wikipedia.org/wiki/Merge_algorithm) that sub-list into the
growing output list, much as the merge step of [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort) combines two
sorted lists into one. Once the input is exhausted, the output list contains every original element in sorted order.

Because each pass extracts the longest ascending run available, Strand sort performs particularly well on data that is
already partially sorted — that is, data made up of a small number of long ascending runs. In the best case, where the
entire list is already sorted, a single pass extracts one strand equal in length to the whole list, giving a running
time of O(n). In the worst case, however, such as a list sorted in descending order, every strand extracted is only a
single element long, and the algorithm degrades to O(n²), similar
to [Insertion Sort](https://en.wikipedia.org/wiki/Insertion_sort).

Strand sort is naturally suited to [linked lists](https://en.wikipedia.org/wiki/Linked_list), since removing an element
from one list and appending it to another (as well as merging two sorted lists) can be done in constant time per element
by relinking nodes, without shifting or copying contiguous storage. Array-based implementations, including the one
presented here, must instead copy elements into and out of an auxiliary sub-list on each pass, which is why they require
O(n) additional space.
