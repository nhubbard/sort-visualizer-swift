*From Wikipedia, the free encyclopedia*

Quick Sort is an in-place sorting algorithm. Developed by British computer scientist [Tony Hoare](https://en.wikipedia.org/wiki/Tony_Hoare) in 1959 and published in 1961, it is still a commonly used algorithm for sorting. When implemented well, it can be somewhat faster than Merge Sort and about two or three times faster than Heap Sort.

Quick Sort is a [divide-and-conquer algorithm](https://en.wikipedia.org/wiki/Divide-and-conquer_algorithm). It works by selecting a 'pivot' element from the array and partitioning the other elements into two sub-arrays, according to whether they are less than or greater than the pivot. For this reason, it is sometimes called **partition-exchange sort**. The sub-arrays are then sorted recursively. This can be done in-place, requiring small additional amounts of memory to perform the sorting.

Quick Sort is a comparison sort, meaning that it can sort items of any type for which a "less-than" relation (formally, a [total order](https://en.wikipedia.org/wiki/Total_order)) is defined. Efficient implementations of Quick Sort are not a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability), meaning that the relative order of equal sort items is not preserved.
