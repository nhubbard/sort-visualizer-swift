def sort(arr):
    n = len(arr)
    if n < 2:
        return
    scratch = arr.copy()

    def merge(index, merge_size):
        mid = index + merge_size // 2
        end = min(n, index + merge_size)
        if mid >= end:
            return index
        left, right, out = index, mid, index
        while left < mid and right < end:
            if arr[left] <= arr[right]:
                scratch[out] = arr[left]
                left += 1
            else:
                scratch[out] = arr[right]
                right += 1
            out += 1
        while left < mid:
            scratch[out] = arr[left]
            left += 1
            out += 1
        while right < end:
            scratch[out] = arr[right]
            right += 1
            out += 1
        return None

    merge_size = 2
    while merge_size <= n:
        copy_length = n
        for index in range(0, n, merge_size):
            stop = merge(index, merge_size)
            if stop is not None:
                copy_length = stop
        arr[:copy_length] = scratch[:copy_length]
        merge_size *= 2
    if merge_size // 2 != n:
        stop = merge(0, merge_size)
        copy_length = n if stop is None else stop
        arr[:copy_length] = scratch[:copy_length]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
