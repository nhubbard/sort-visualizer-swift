def flip(arr, hi):
    """Reverses arr[0..hi] in place. This "flip" is the only move the algorithm ever performs;
    there is no per-element shift anywhere."""
    lo = 0
    while lo < hi:
        arr[lo], arr[hi] = arr[hi], arr[lo]
        lo += 1
        hi -= 1


def search_ascending(arr, start, end, value_index):
    """Monobound binary search: locates the index within the ascending run arr[start:end] at
    which arr[value_index] belongs, using one comparison per halving instead of the usual two."""
    top = end - start
    while top > 1:
        mid = top // 2
        if arr[value_index] <= arr[end - mid]:
            end -= mid
        top -= mid
    if arr[value_index] <= arr[end - 1]:
        return end - 1
    return end


def search_descending(arr, start, end, value_index):
    """Mirror image of search_ascending for a descending run arr[start:end]."""
    top = end - start
    while top > 1:
        mid = top // 2
        if arr[start + mid] > arr[value_index]:
            start += mid
        top -= mid
    if arr[start] > arr[value_index]:
        return start + 1
    return start


def sort_first_three(arr, n):
    """Hand-sorts arr[0:n] for n <= 3 via a small decision tree. Returns True if the result runs
    ascending, False if it runs descending."""
    if n < 2:
        return False
    if arr[0] > arr[1]:
        flip(arr, 1)
    if n > 2:
        if arr[1] > arr[2]:
            if arr[0] > arr[2]:
                flip(arr, 1)
            else:
                flip(arr, 2)
                flip(arr, 1)
            return False
        return True
    return True


def sort(arr):
    n = len(arr)
    if n < 2:
        return

    ascending = sort_first_three(arr, n)

    i = 3
    while i < n:
        if ascending:
            if arr[i - 1] <= arr[i]:
                # Already fits; the ascending prefix already ends at or below the new element.
                pass
            elif arr[0] > arr[i]:
                # The new element is smaller than everything in the prefix -- one flip turns
                # the whole thing, including the new element, into a descending run.
                flip(arr, i - 1)
                ascending = False
            else:
                idx = search_ascending(arr, 0, i, i)
                flip(arr, i)
                tail = i - idx
                flip(arr, tail)
                flip(arr, tail - 1)
                ascending = False
        else:
            if arr[i - 1] > arr[i]:
                pass
            elif arr[0] <= arr[i]:
                flip(arr, i - 1)
                ascending = True
            else:
                idx = search_descending(arr, 0, i, i)
                flip(arr, i)
                tail = i - idx
                flip(arr, tail)
                flip(arr, tail - 1)
                ascending = True
        i += 1

    if not ascending:
        flip(arr, n - 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
