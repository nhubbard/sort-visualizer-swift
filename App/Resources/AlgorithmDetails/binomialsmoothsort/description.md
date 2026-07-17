Binomial Smooth Sort takes smoothsort's central idea — grow the unsorted region one element at a time into a forest of
heap-ordered trees, then dismantle that forest to extract the elements in order — and swaps out smoothsort's usual
Leonardo-number trees for trees shaped like a binomial heap's instead. Each new element joins the forest as its own
single-node tree; whenever the sizes line up correctly, two adjacent trees of matching size merge into one tree twice as
large, exactly the doubling rule binomial heaps use to keep the whole forest at no more than a handful of trees
regardless of how many elements have been added.

Because every tree in the forest is already heap-ordered by construction, extraction just has to find the largest root
among the current trees, remove it, and split its tree back apart into the (roughly log₂-sized) collection of smaller
trees it was built from — no sifting pass is needed the way a binary heap needs one, since a binomial-shaped tree's root
is always the largest thing in it, by the same invariant that made building the forest correct to begin with. The result
inherits smoothsort's central appeal — it's built incrementally, one insertion at a time, rather than requiring the
whole array up front — this variant is just built from binomial trees rather than the Leonardo trees the original
algorithm is named after.