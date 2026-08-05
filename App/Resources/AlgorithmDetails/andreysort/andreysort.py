def swap(arr, i, j):
    arr[i], arr[j] = arr[j], arr[i]


def selection_sort(arr, a_in, b_in):
    # Base case below length 12: repeatedly swap the minimum of the
    # remaining range to the front.
    a = a_in
    b = b_in
    while b > 1:
        k = 0
        for i in range(1, b):
            if arr[a + k] > arr[a + i]:
                k = i
        swap(arr, a, a + k)
        a += 1
        b -= 1


def aswap(arr, arr1_in, arr2_in, l_in):
    # Forward block-swap of l elements.
    arr1 = arr1_in
    arr2 = arr2_in
    l = l_in
    while l > 0:
        swap(arr, arr1, arr2)
        arr1 += 1
        arr2 += 1
        l -= 1


def backmerge(arr, arr1_in, l1_in, arr2_in, l2_in):
    # Merges the two runs ending at arr1/arr2 (lengths l1/l2), working
    # backward from their high ends into the trailing buffer that starts
    # right after arr2. Returns the count of unplaced left-run elements if
    # the right run ran out first (0 otherwise).
    arr1 = arr1_in
    l1 = l1_in
    arr2 = arr2_in
    l2 = l2_in
    arr0 = arr2 + l1
    while True:
        if arr[arr1] > arr[arr2]:
            swap(arr, arr1, arr0)
            arr1 -= 1
            arr0 -= 1
            l1 -= 1
            if l1 == 0:
                return 0
        else:
            swap(arr, arr2, arr0)
            arr2 -= 1
            arr0 -= 1
            l2 -= 1
            if l2 == 0:
                break
    res = l1
    while True:
        swap(arr, arr1, arr0)
        arr1 -= 1
        arr0 -= 1
        l1 -= 1
        if l1 == 0:
            break
    return res


def rmerge(arr, a, l, r):
    # Merges arr[a..a+l) (as l/r blocks of width r) using the buffer
    # arr[a+l..a+l+r): selection-sorts the block leaders, then backmerges
    # each selected block into place.
    i = 0
    while i < l:
        q = i
        j = i + r
        while j < l:
            if arr[a + q] > arr[a + j]:
                q = j
            j += r
        if q != i:
            aswap(arr, a + i, a + q, r)
        if i != 0:
            aswap(arr, a + l, a + i, r)
            backmerge(arr, a + (l + r - 1), r, a + (i - 1), r)
        i += r


def rbnd(len_in):
    # Computes the block size: roughly sqrt(len), rounded up to a power of two.
    length = len_in // 2
    k = 0
    i = 1
    while i < length:
        k += 1
        i *= 2
    length //= k
    k = 1
    while k <= length:
        k *= 2
    return k


def msort(arr, a, length):
    if length < 12:
        selection_sort(arr, a, length)
        return

    r = rbnd(length)
    lr = (length // r - 1) * r

    p = 2
    while p <= lr:
        if arr[a + (p - 2)] > arr[a + (p - 1)]:
            swap(arr, a + (p - 2), a + (p - 1))
        if (p & 2) != 0:
            p += 2
            continue

        aswap(arr, a + (p - 2), a + p, 2)

        m = length - p
        q = 2
        while True:
            q0 = 2 * q
            if q0 > m or (p & q0) != 0:
                break
            backmerge(arr, a + (p - q - 1), q, a + (p + q - 1), q)
            q = q0
        backmerge(arr, a + (p + q - 1), q, a + (p - q - 1), q)
        q1 = q
        q *= 2

        while (q & p) == 0:
            q *= 2
            rmerge(arr, a + (p - q), q, q1)

        p += 2

    q1 = 0
    q = r
    while q < lr:
        if (lr & q) != 0:
            q1 += q
            if q1 != q:
                rmerge(arr, a + (lr - q1), q1, r)
        q *= 2

    s0 = length - lr
    msort(arr, a + lr, s0)
    aswap(arr, a, a + lr, s0)
    s = s0 + backmerge(arr, a + (s0 - 1), s0, a + (lr - 1), lr - s0)
    msort(arr, a, s)


def sort(arr):
    n = len(arr)
    msort(arr, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
