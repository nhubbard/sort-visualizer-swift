# A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of its
# own, so its real cost grows worse than n! squared -- even a handful of elements can take an
# unreasonable amount of time. To keep this example runnable, the true recursive algorithm below
# is only ever applied to a small leading slice of the array (CHAOS_LIMIT elements); the rest is
# finished with an ordinary insertion sort, and the two already-sorted pieces are merged back
# together at the end. The random reshuffle is also replaced with a deterministic, never-repeating
# permutation walk, so neither piece can wander into an unbounded random search.
CHAOS_LIMIT = 5


def next_permutation(arr):
    """Advances arr to its next lexicographic permutation in place. Returns False (after
    resetting arr to its first, fully ascending permutation) once every arrangement has been
    visited -- a deterministic stand-in for "shuffle the array at random"."""
    n = len(arr)
    i = n - 2
    while i >= 0 and arr[i] >= arr[i + 1]:
        i -= 1
    if i < 0:
        arr.reverse()
        return False
    j = n - 1
    while arr[j] <= arr[i]:
        j -= 1
    arr[i], arr[j] = arr[j], arr[i]
    arr[i + 1 :] = list(reversed(arr[i + 1 :]))
    return True


def bogo_bogo_is_sorted(arr):
    """The heart of the joke: rather than scanning arr once, decide whether it is sorted by
    copying it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact
    same process one level down, reshuffling the whole copy until its last two elements land in
    order, and comparing the result against the original. A match means the copy is now the true
    sorted arrangement of the same values, which is only possible if arr was already sorted."""
    n = len(arr)
    if n <= 1:
        return True
    copy = arr[:]
    prefix = copy[: n - 1]
    bogo_bogo_sort(prefix)
    copy[: n - 1] = prefix
    candidate = 0
    while copy[n - 2] > copy[n - 1]:
        copy[candidate], copy[n - 1] = copy[n - 1], copy[candidate]
        candidate += 1
        prefix = copy[: n - 1]
        bogo_bogo_sort(prefix)
        copy[: n - 1] = prefix
    return copy == arr


def bogo_bogo_sort(arr):
    while not bogo_bogo_is_sorted(arr):
        next_permutation(arr)


def insertion_sort(arr):
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        while j >= 0 and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key


def merge_sorted(a, b):
    merged = []
    i = j = 0
    while i < len(a) and j < len(b):
        if a[i] <= b[j]:
            merged.append(a[i])
            i += 1
        else:
            merged.append(b[j])
            j += 1
    merged.extend(a[i:])
    merged.extend(b[j:])
    return merged


def sort(arr):
    n = len(arr)
    limit = min(CHAOS_LIMIT, n)
    chaos = arr[:limit]
    rest = arr[limit:]
    bogo_bogo_sort(chaos)  # the real, recursive-check algorithm -- kept tiny on purpose
    insertion_sort(
        rest
    )  # an ordinary fast sort for everything past the demonstration slice
    arr[:] = merge_sorted(chaos, rest)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
