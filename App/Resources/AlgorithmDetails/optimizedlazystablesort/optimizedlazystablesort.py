def swap(arr, a, b):
    arr[a], arr[b] = arr[b], arr[a]


def multi_swap(arr, a, b, count):
    for i in range(count):
        swap(arr, a + i, b + i)


def rotate(arr, pos, len_a, len_b):
    while len_a != 0 and len_b != 0:
        if len_a <= len_b:
            multi_swap(arr, pos, pos + len_a, len_a)
            pos += len_a
            len_b -= len_a
        else:
            multi_swap(arr, pos + (len_a - len_b), pos + len_a, len_b)
            len_a -= len_b


def bin_search(arr, pos, length, key_pos, is_left):
    left = -1
    right = length
    key = arr[key_pos]
    while left < right - 1:
        mid = left + (right - left) // 2
        cond = arr[pos + mid] >= key if is_left else arr[pos + mid] > key
        if cond:
            right = mid
        else:
            left = mid
    return right


def merge_without_buffer(arr, pos, len1, len2):
    if len1 == 0 or len2 == 0:
        return
    if len1 < len2:
        while len1 != 0:
            loc = bin_search(arr, pos + len1, len2, pos, True)
            if loc != 0:
                rotate(arr, pos, len1, loc)
                pos += loc
                len2 -= loc
            if len2 == 0:
                break
            while True:
                pos += 1
                len1 -= 1
                if not (len1 != 0 and arr[pos] <= arr[pos + len1]):
                    break
    else:
        while len2 != 0:
            loc = bin_search(arr, pos, len1, pos + len1 + len2 - 1, False)
            if loc != len1:
                rotate(arr, pos + loc, len1 - loc, len2)
                len1 = loc
            if len1 == 0:
                break
            while True:
                len2 -= 1
                if not (
                    len2 != 0 and arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]
                ):
                    break


def insertion_sort_chunk(arr, a, b):
    # Guard: a chunk of length <= 1 has nothing to compare. ArrayV's own source skips this
    # check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
    # leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
    if b - a <= 1:
        return
    i = a + 1
    descending = arr[i - 1] > arr[i]
    i += 1
    if descending:
        while i < b and arr[i - 1] > arr[i]:
            i += 1
        lo, hi = a, i - 1
        while lo < hi:
            swap(arr, lo, hi)
            lo += 1
            hi -= 1
    else:
        while i < b and arr[i - 1] <= arr[i]:
            i += 1
    while i < b:
        current = arr[i]
        pos = i - 1
        while pos >= a and arr[pos] > current:
            arr[pos + 1] = arr[pos]
            pos -= 1
        arr[pos + 1] = current
        i += 1


def lazy_stable_sort(arr, pos, length):
    dist = 0
    while dist + 16 < length:
        insertion_sort_chunk(arr, pos + dist, pos + dist + 16)
        dist += 16
    if dist < length:
        insertion_sort_chunk(arr, pos + dist, pos + length)

    part = 16
    while part < length:
        left = 0
        right = length - 2 * part
        while left <= right:
            merge_without_buffer(arr, pos + left, part, part)
            left += 2 * part
        rest = length - left
        if rest > part:
            merge_without_buffer(arr, pos + left, part, rest - part)
        part *= 2


def sort(arr):
    n = len(arr)
    lazy_stable_sort(arr, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
