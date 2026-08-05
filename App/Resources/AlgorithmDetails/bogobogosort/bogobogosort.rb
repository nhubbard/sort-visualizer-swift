# A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of its
# own, so its real cost grows worse than n! squared -- even a handful of elements can take an
# unreasonable amount of time. To keep this example runnable, the true recursive algorithm below
# is only ever applied to a small leading slice of the array (CHAOS_LIMIT elements); the rest is
# finished with an ordinary insertion sort, and the two already-sorted pieces are merged back
# together at the end. The random reshuffle is also replaced with a deterministic, never-repeating
# permutation walk, so neither piece can wander into an unbounded random search.
CHAOS_LIMIT = 5

# Advances arr to its next lexicographic permutation in place. Returns false (after resetting arr
# to its first, fully ascending permutation) once every arrangement has been visited -- a
# deterministic stand-in for "shuffle the array at random".
def next_permutation(arr)
  n = arr.length
  i = n - 2
  i -= 1 while i >= 0 && arr[i] >= arr[i + 1]
  if i < 0
    arr.reverse!
    return false
  end
  j = n - 1
  j -= 1 while arr[j] <= arr[i]
  arr[i], arr[j] = arr[j], arr[i]
  arr[(i + 1)...n] = arr[(i + 1)...n].reverse
  true
end

# The heart of the joke: rather than scanning arr once, decide whether it is sorted by copying it,
# recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact same process one
# level down, reshuffling the whole copy until its last two elements land in order, and comparing
# the result against the original. A match means the copy is now the true sorted arrangement of
# the same values, which is only possible if arr was already sorted.
def bogo_bogo_is_sorted?(arr)
  n = arr.length
  return true if n <= 1

  copy = arr.dup
  prefix = copy[0...(n - 1)]
  bogo_bogo_sort(prefix)
  copy[0...(n - 1)] = prefix
  candidate = 0
  while copy[n - 2] > copy[n - 1]
    copy[candidate], copy[n - 1] = copy[n - 1], copy[candidate]
    candidate += 1
    prefix = copy[0...(n - 1)]
    bogo_bogo_sort(prefix)
    copy[0...(n - 1)] = prefix
  end
  copy == arr
end

def bogo_bogo_sort(arr)
  next_permutation(arr) until bogo_bogo_is_sorted?(arr)
end

def insertion_sort(arr)
  (1...arr.length).each do |i|
    key = arr[i]
    j = i - 1
    while j >= 0 && arr[j] > key
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[j + 1] = key
  end
end

def merge_sorted(a, b)
  merged = []
  i = 0
  j = 0
  while i < a.length && j < b.length
    if a[i] <= b[j]
      merged << a[i]
      i += 1
    else
      merged << b[j]
      j += 1
    end
  end
  merged.concat(a[i...])
  merged.concat(b[j...])
  merged
end

def sort(arr)
  n = arr.length
  limit = [CHAOS_LIMIT, n].min
  chaos = arr[0...limit]
  rest = arr[limit...n]

  bogo_bogo_sort(chaos) # the real, recursive-check algorithm -- kept tiny on purpose
  insertion_sort(rest) # an ordinary fast sort for the rest of the array

  arr[0...n] = merge_sorted(chaos, rest)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
