def sort(arr):
    n = len(arr)
    if n < 2:
        return
    scratch = arr[:]
    buffer = scratch[:]

    def merge_sort(lo, hi):
        if hi - lo < 2:
            return
        mid = lo + (hi - lo) // 2
        merge_sort(lo, mid)
        merge_sort(mid, hi)
        left, right, dest = lo, mid, lo
        while left < mid and right < hi:
            if scratch[left] <= scratch[right]:
                buffer[dest] = scratch[left]
                left += 1
            else:
                buffer[dest] = scratch[right]
                right += 1
            dest += 1
        while left < mid:
            buffer[dest] = scratch[left]
            left += 1
            dest += 1
        while right < hi:
            buffer[dest] = scratch[right]
            right += 1
            dest += 1
        scratch[lo:hi] = buffer[lo:hi]

    merge_sort(0, n)
    arr[:] = scratch
    for i in range(1, n):
        j = i
        while j > 0 and arr[j - 1] > arr[j]:
            arr[j - 1], arr[j] = arr[j], arr[j - 1]
            j -= 1


if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
