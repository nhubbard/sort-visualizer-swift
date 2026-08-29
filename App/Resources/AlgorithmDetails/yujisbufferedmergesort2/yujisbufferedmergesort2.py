def ceil_log(n):
    i = 0
    while (1 << i) < n:
        i += 1
    return i


def multi_swap(array, a, b, length):
    for i in range(length):
        array[a + i], array[b + i] = array[b + i], array[a + i]


def insert_to(array, a, b):
    temp = array[a]
    while a > b:
        a -= 1
        array[a + 1] = array[a]
    array[b] = temp


def binary_search(array, start, end, value, left):
    a = start
    b = end
    while a < b:
        m = a + (b - a) // 2
        comp = value <= array[m] if left else value < array[m]
        if comp:
            b = m
        else:
            a = m + 1
    return a


def binary_insertion(array, a, b):
    i = a + 1
    while i < b:
        value = array[i]
        insert_to(array, i, binary_search(array, a, i, value, False))
        i += 1


def merge(array, a, m, b, p):
    i = a
    j = m
    while i < m and j < b:
        if array[i] <= array[j]:
            array[p], array[i] = array[i], array[p]
            p += 1
            i += 1
        else:
            array[p], array[j] = array[j], array[p]
            p += 1
            j += 1
    leftover = 0
    while i < m:
        array[p], array[i] = array[i], array[p]
        p += 1
        i += 1
    while j < b:
        array[p], array[j] = array[j], array[p]
        p += 1
        j += 1
        leftover += 1
    return leftover


def merge_with_buf_static(array, a, m, b, p, use_binary_search):
    i = 0
    j = m
    k = a
    if use_binary_search:
        while i < m - a and j < b:
            if array[j] < array[p + i]:
                value = array[p + i]
                q = binary_search(array, j, b, value, True)
                while j < q:
                    array[k], array[j] = array[j], array[k]
                    k += 1
                    j += 1
            array[k], array[p + i] = array[p + i], array[k]
            k += 1
            i += 1
        while i < m - a:
            array[k], array[p + i] = array[p + i], array[k]
            k += 1
            i += 1
    else:
        while i < m - a and j < b:
            if array[p + i] <= array[j]:
                array[k], array[p + i] = array[p + i], array[k]
                k += 1
                i += 1
            else:
                array[k], array[j] = array[j], array[k]
                k += 1
                j += 1
        while i < m - a:
            array[k], array[p + i] = array[p + i], array[k]
            k += 1
            i += 1


def merge_sort(array, a, p, length):
    j = 16
    ceil_log_value = ceil_log(length)
    pos = p if (length > 16 and (ceil_log_value & 1) == 1) else a

    i = pos
    while i + 16 <= pos + length:
        binary_insertion(array, i, i + 16)
        i += 16
    binary_insertion(array, i, pos + length)

    nxt = pos
    while j < length:
        pos = nxt
        nxt ^= a ^ p
        pos_next = nxt

        i = pos
        while i + 2 * j <= pos + length:
            merge(array, i, i + j, i + 2 * j, pos_next)
            i += 2 * j
            pos_next += 2 * j
        if i + j < pos + length:
            merge(array, i, i + j, pos + length, pos_next)
        else:
            while i < pos + length:
                array[i], array[pos_next] = array[pos_next], array[i]
                i += 1
                pos_next += 1
        j *= 2


def buffered_merge(array, a, b):
    if b - a <= 16:
        binary_insertion(array, a, b)
        return

    m = (a + b + 1) // 2
    merge_sort(array, m, 2 * m - b, b - m)

    n = (a + m + 1) // 2
    limit = (b - a) // 16
    while m - a > limit:
        merge_sort(array, 2 * n - m, n, m - n)
        merge_with_buf_static(
            array, n, m, b, 2 * n - m, (b - m) // (m - n) >= ceil_log(n - a)
        )
        m = n
        n = (a + m + 1) // 2

    buffered_merge(array, a, m)
    multi_swap(array, a, b - (m - a), m - a)
    s = merge(array, m, b - (m - a), b, a)
    buffered_merge(array, b - (m - a) - s, b)


def sort(arr):
    n = len(arr)
    if n <= 1:
        return
    buffered_merge(arr, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
