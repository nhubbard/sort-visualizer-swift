def multi_swap(array, a, b, length):
    for i in range(length):
        array[a + i], array[b + i] = array[b + i], array[a + i]


def rotate(array, a, m, b):
    l, r = m - a, b - m
    while l > 0 and r > 0:
        if r < l:
            multi_swap(array, m - r, m, r)
            b -= r
            m -= r
            l -= r
        else:
            multi_swap(array, a, m, l)
            a += l
            m += l
            r -= l


def partition_merge(array, a, m, b, c):
    """Select the c smallest combined elements of the two already-sorted
    runs array[a:m] and array[m:b] into the front half via a single
    rotation. Uses a merge-path (co-rank) binary search over whichever run
    is shorter: it looks for the split count r such that taking r elements
    from the tail of one run and (c - r) from the head of the other yields
    exactly the c smallest values in order, rather than searching for a
    value directly."""
    len_a, len_b = m - a, b - m
    if len_a < 1 or len_b < 1:
        return

    if len_b < len_a:
        cc = (len_a + len_b) - c
        r1 = max(0, cc - len_a)
        r2 = min(cc, len_b)
        while r1 < r2:
            ml = r1 + (r2 - r1) // 2
            if array[m - (cc - ml)] > array[b - ml - 1]:
                r2 = ml
            else:
                r1 = ml + 1
        rotate(array, m - (cc - r1), m, b - r1)
    else:
        r1 = max(0, c - len_b)
        r2 = min(c, len_a)
        while r1 < r2:
            ml = r1 + (r2 - r1) // 2
            if array[a + ml] > array[m + (c - ml) - 1]:
                r2 = ml
            else:
                r1 = ml + 1
        rotate(array, a + r1, m, m + (c - r1))


def rotate_merge(array, a, b, c):
    """Find the first place inside array[a:b] where ascending order breaks,
    then partition-merge the sorted piece before it with the sorted piece
    after it. A no-op if array[a:b] is already one ascending run."""
    i = a + 1
    while i < b and array[i - 1] <= array[i]:
        i += 1
    if i < b:
        partition_merge(array, a, i, b, c)


def rotate_partition_merge_sort(array, n):
    if n < 2:
        return

    for i in range(1, n, 2):
        if array[i - 1] > array[i]:
            array[i - 1], array[i] = array[i], array[i - 1]

    j = 2
    while j < n:
        b1 = 0
        block_start = 0
        while block_start + j < n:
            b1 = min(block_start + 2 * j, n)
            partition_merge(array, block_start, block_start + j, b1, j)
            block_start += 2 * j

        k = j // 2
        while k > 1:
            seam_start = 0
            while seam_start + k < b1:
                seam_end = min(seam_start + 2 * k, n)
                rotate_merge(array, seam_start, seam_end, k)
                seam_start += 2 * k
            k //= 2

        for m in range(1, b1, 2):
            if array[m - 1] > array[m]:
                array[m - 1], array[m] = array[m], array[m - 1]

        j *= 2


def sort(arr):
    rotate_partition_merge_sort(arr, len(arr))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
