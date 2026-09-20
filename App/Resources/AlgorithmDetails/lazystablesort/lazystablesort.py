def multi_swap(arr, a, b, count):
    for i in range(count):
        arr[a + i], arr[b + i] = arr[b + i], arr[a + i]


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
    left, right = 0, length
    while left < right:
        mid = left + (right - left) // 2
        cond = (
            arr[pos + mid] < arr[key_pos] if is_left else arr[pos + mid] <= arr[key_pos]
        )
        if cond:
            left = mid + 1
        else:
            right = mid
    return left


def merge_without_buffer(arr, pos, len1, len2):
    if len1 < len2:
        while len1:
            loc = bin_search(arr, pos + len1, len2, pos, True)
            if loc:
                rotate(arr, pos, len1, loc)
                pos += loc
                len2 -= loc
            if not len2:
                break
            while True:
                pos += 1
                len1 -= 1
                if not len1 or arr[pos] > arr[pos + len1]:
                    break
    else:
        while len2:
            loc = bin_search(arr, pos, len1, pos + len1 + len2 - 1, False)
            if loc != len1:
                rotate(arr, pos + loc, len1 - loc, len2)
                len1 = loc
            if not len1:
                break
            while True:
                len2 -= 1
                if not len2 or arr[pos + len1 - 1] > arr[pos + len1 + len2 - 1]:
                    break


def sort(arr):
    n = len(arr)
    dist = 1
    while dist < n:
        if arr[dist - 1] > arr[dist]:
            arr[dist - 1], arr[dist] = arr[dist], arr[dist - 1]
        dist += 2
    part = 2
    while part < n:
        left = 0
        right = n - 2 * part
        while left <= right:
            merge_without_buffer(arr, left, part, part)
            left += 2 * part
        rest = n - left
        if rest > part:
            merge_without_buffer(arr, left, part, rest - part)
        part *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
