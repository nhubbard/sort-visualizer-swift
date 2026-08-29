def block_root(n):
    i = 1
    while i * i < n:
        i *= 2
    return i


def multi_swap(array, a, b, length):
    for i in range(length):
        array[a + i], array[b + i] = array[b + i], array[a + i]


def rotate(array, a, m, b):
    l = m - a
    r = b - m
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


def select_range(array, start, end, b_len):
    min_index = start
    a = start + b_len
    while a < end:
        if (
            array[a] < array[min_index]
            or array[a] == array[min_index]
            and array[a + b_len - 1] < array[min_index + b_len - 1]
        ):
            min_index = a
        a += b_len
    return min_index


def block_select(array, a, m, b, b_len):
    k = a
    j = m
    while k < m and array[k] <= array[m]:
        k += b_len
    if k == m:
        return

    i = m
    multi_swap(array, k, j, b_len)
    k += b_len
    j += b_len

    while k < j < b:
        if array[i] <= array[j]:
            if k != i:
                multi_swap(array, k, i, b_len)
            k += b_len
            i = select_range(array, max(m, k), j, b_len)
        else:
            if i == k:
                i = j
            if k != j:
                multi_swap(array, k, j, b_len)
            k += b_len
            j += b_len

    while k < j:
        i = select_range(array, k, b, b_len)
        if k != i:
            multi_swap(array, k, i, b_len)
        k += b_len


def in_place_merge(array, a, m, b):
    i = a
    j = m
    while i < j < b:
        if array[i] > array[j]:
            k = j + 1
            while k < b and array[i] > array[k]:
                k += 1
            rotate(array, i, j, k)
            i += k - j
            j = k
        else:
            i += 1
    return i


def in_place_merge_bw(array, a, m, b):
    i = m - 1
    j = b - 1
    while j > i >= a:
        if array[i] > array[j]:
            k = i - 1
            while k >= a and array[k] > array[j]:
                k -= 1
            rotate(array, k + 1, i + 1, j + 1)
            j -= i - k
            i = k
        else:
            j -= 1


def sort(array):
    n = len(array)
    if n <= 1:
        return
    j = 1
    while j < n:
        b_len = block_root(j)
        run_length = j
        b = n - n % b_len

        while run_length > 16:
            i = 0
            while i + j < b:
                k = i
                while k + run_length < min(i + 2 * j, b):
                    block_select(
                        array, k, k + run_length, min(k + 2 * run_length, b), b_len
                    )
                    k += run_length
                i += 2 * j
            run_length = b_len
            b_len = block_root(b_len)

        i = 0
        while i + j < b:
            k = i
            f = i
            while k + run_length < min(i + 2 * j, b):
                f = in_place_merge(array, f, k + run_length, min(k + 2 * run_length, b))
                k += run_length
            i += 2 * j

        in_place_merge_bw(array, n - n % (2 * j), b, n)
        j *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
