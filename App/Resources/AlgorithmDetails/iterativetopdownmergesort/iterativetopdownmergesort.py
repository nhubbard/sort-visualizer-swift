def merge(array, scratch, low, mid, high):
    left, right, out = low, mid, low
    while left < mid and right < high:
        if array[left] <= array[right]:
            scratch[out] = array[left]
            left += 1
        else:
            scratch[out] = array[right]
            right += 1
        out += 1
    while left < mid:
        scratch[out] = array[left]
        left += 1
        out += 1
    while right < high:
        scratch[out] = array[right]
        right += 1
        out += 1
    for index in range(low, high):
        array[index] = scratch[index]


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    scratch = [0] * n
    subarray_count = 1
    while subarray_count < n:
        subarray_count = subarray_count * 2

    while subarray_count > 1:
        i = 0
        while i < subarray_count:
            low = n * i // subarray_count
            mid = n * (i + 1) // subarray_count
            high = n * (i + 2) // subarray_count
            merge(arr, scratch, low, mid, high)
            i = i + 2
        subarray_count = subarray_count // 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
