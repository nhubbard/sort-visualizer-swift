def int_pow(base, exponent):
    result = 1
    for _ in range(exponent):
        result *= base
    return result


def get_digit(value, place, base):
    return (value // int_pow(base, place)) % base


def multi_swap(arr, a, b, length):
    for i in range(length):
        arr[a + i], arr[b + i] = arr[b + i], arr[a + i]


def rotate(arr, a, m, b):
    l = m - a
    r = b - m
    while l > 0 and r > 0:
        if r < l:
            multi_swap(arr, m - r, m, r)
            b -= r
            m -= r
            l -= r
        else:
            multi_swap(arr, a, m, l)
            a += l
            m += l
            r -= l


def bin_search_digit(arr, a, b, d, place, base):
    while a < b:
        mid = (a + b) // 2
        if get_digit(arr[mid], place, base) >= d:
            b = mid
        else:
            a = mid + 1
    return a


def merge_digit(arr, a, m, b, da, db, place, base):
    if b - a < 2 or db - da < 2:
        return
    dm = (da + db) // 2
    m1 = bin_search_digit(arr, a, m, dm, place, base)
    m2 = bin_search_digit(arr, m, b, dm, place, base)
    rotate(arr, m1, m, m2)
    new_m = m1 + (m2 - m)
    merge_digit(arr, new_m, m2, b, dm, db, place, base)
    merge_digit(arr, a, m1, new_m, da, dm, place, base)


def merge_sort_digit(arr, a, b, place, base):
    if b - a < 2:
        return
    mid = (a + b) // 2
    merge_sort_digit(arr, a, mid, place, base)
    merge_sort_digit(arr, mid, b, place, base)
    merge_digit(arr, a, mid, b, 0, base, place, base)


def msd_rotate_sort(arr, a, b, place, base):
    """Digit-sorts arr[a:b] in place by `place` using rotation instead of
    counting buckets, then recurses into every resulting digit bucket one
    place lower -- an ordinary MSD radix sort built entirely out of the LSD
    variant's rotate/binary-search machinery."""
    if b - a < 2 or place < 0:
        return
    merge_sort_digit(arr, a, b, place, base)
    start = a
    for d in range(base):
        end = bin_search_digit(arr, start, b, d + 1, place, base)
        msd_rotate_sort(arr, start, end, place - 1, base)
        start = end


def sort(arr):
    if len(arr) <= 1:
        return
    base = 4
    max_value = max(arr)
    highest_place = 0
    probe = base
    while probe <= max_value:
        highest_place += 1
        probe *= base
    msd_rotate_sort(arr, 0, len(arr), highest_place, base)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
