Bogosort repeatedly shuffles an array until the elements are in order. Its expected running time
grows factorially with the input size. Bogo Bogo Sort applies the same generate-and-test method
recursively to the sortedness test itself.

Bogo Bogo Sort copies the range and recursively sorts the first n − 1 elements of the copy. It then
reshuffles the complete copy until its final two elements are ordered, after which it compares the
copy with the original element by element. Matching ranges establish that the original was already
sorted.

The sortedness check is therefore a complete recursive sort at every smaller range down to one
element. Bogosort has expected cost O(n × n!). Estimates for Bogo Bogo Sort begin near
O(n × (n!)²), with higher bounds depending on how the nested failed attempts are counted. Its
practical input limit is correspondingly smaller than Bogosort's.

Bogo Bogo Sort is an intentionally inefficient algorithm used to demonstrate the cost of nesting a
generate-and-test procedure. It is not intended for practical sorting.
