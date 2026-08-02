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
        cond = arr[pos + mid] < arr[key_pos] if is_left else arr[pos + mid] <= arr[key_pos]
        if cond:
            left = mid + 1
        else:
            right = mid
    return left


def merge_without_buffer(arr, pos, len1, len2):
    if len1 == 0 or len2 == 0:
        return
    if len1 == 1:
        loc = bin_search(arr, pos + 1, len2, pos, True)
        rotate(arr, pos, 1, loc)
        return
    if len2 == 1:
        loc = bin_search(arr, pos, len1, pos + len1, False)
        rotate(arr, pos + loc, len1 - loc, 1)
        return
    mid1 = len1 // 2
    loc = bin_search(arr, pos + len1, len2, pos + mid1, True)
    rotate(arr, pos + mid1, len1 - mid1, loc)
    merge_without_buffer(arr, pos, mid1, loc)
    merge_without_buffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc)


def find_run(arr, a, b):
    i = a + 1
    if i == b:
        return i
    if arr[i - 1] > arr[i]:
        i += 1
        while i < b and arr[i - 1] > arr[i]:
            i += 1
        lo, hi = a, i - 1
        while lo < hi:
            arr[lo], arr[hi] = arr[hi], arr[lo]
            lo += 1
            hi -= 1
    else:
        i += 1
        while i < b and arr[i - 1] <= arr[i]:
            i += 1
    return i


def insert1(arr, a, l):
    tmp = arr[l]
    l -= 1
    while l >= a and arr[l] > tmp:
        arr[l + 1] = arr[l]
        l -= 1
    arr[l + 1] = tmp


def insert2(arr, a, l, r):
    tmp_l = arr[l]
    tmp_r = arr[r]
    l -= 1
    while l >= a and arr[l] > tmp_r:
        arr[l + 2] = arr[l]
        l -= 1
    arr[l + 2] = tmp_r
    while l >= a and arr[l] > tmp_l:
        arr[l + 1] = arr[l]
        l -= 1
    arr[l + 1] = tmp_l


def sort(arr):
    n = len(arr)
    i = find_run(arr, 0, n)
    while i < n:
        j = find_run(arr, i, n)
        length = j - i
        if length == 1:
            insert1(arr, 0, i)
        elif length == 2:
            insert2(arr, 0, i, i + 1)
        else:
            merge_without_buffer(arr, 0, i, length)
        i = j


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
