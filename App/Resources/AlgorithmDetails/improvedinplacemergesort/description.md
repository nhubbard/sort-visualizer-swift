In-place merge sort variants exist to solve one specific complaint about ordinary merge sort: the
extra array the size of the whole input that a normal merge step needs to combine two sorted runs.
This variant merges two adjacent sorted runs without any second array, at the cost of doing more
work to move elements around than a buffered merge would need.

The core operation is a single-step "push": given a run boundary and an insertion point somewhere
before it, push grabs the first element of the run, drops it into the insertion point, shifts every
element between the run's old start and the new element's landing spot down by one to close the
gap, and places the value that used to sit at the insertion point into the vacated slot at the end.
Merging two runs then becomes a matter of walking through the left run one element at a time: as
long as the current left element is already no greater than the run's own comparison pointer on the
right, that's a sign the left element belongs before every right-run element examined so far, so a
single push slots the next unconsumed right-run element into place and everything shifts to make
room. When the left element is instead greater than the value being compared against, the algorithm
simply advances its scan further into the right run without moving anything yet, extending the
stretch of right-run elements that a future push will need to account for.

Because every comparison only ever decides between "extend the scan" and "push," and a push never
reorders two elements that started out equal to each other, elements with equal values keep their
original relative order — making this a stable sort despite doing its rearranging via direct
position shifts rather than replaying reads from a temporary buffer. Its cost is dictated entirely
by how far a push has to shift elements: an input that's already sorted never triggers a push with
anything to move at all, giving the ordinary merge-sort recursion's own O(n log n) best case, while
an input arranged so that every left element requires shifting nearly the whole remaining right run
degrades to O(n²).
