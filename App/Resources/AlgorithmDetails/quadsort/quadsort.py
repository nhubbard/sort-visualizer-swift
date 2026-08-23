INSERTION_RUN = 4


def insertion_sort_range(arr, lo, hi):
    for i in range(lo + 1, hi):
        key = arr[i]
        j = i - 1
        while j >= lo and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key


def parity_merge(source, lo, run_length, dest):
    # Merges the two equal-length sorted runs source[lo:lo+run_length] and
    # source[lo+run_length:lo+2*run_length] into dest, filling from both ends toward the
    # middle at once instead of scanning front to back alone.
    left, right = lo, lo + run_length
    left_end, right_end = lo + run_length - 1, lo + 2 * run_length - 1
    front, back = lo, lo + 2 * run_length - 1

    for _ in range(run_length):
        if source[left] <= source[right]:
            dest[front] = source[left]
            left += 1
        else:
            dest[front] = source[right]
            right += 1
        front += 1

        if source[left_end] > source[right_end]:
            dest[back] = source[left_end]
            left_end -= 1
        else:
            dest[back] = source[right_end]
            right_end -= 1
        back -= 1


def merge_range(source, lo, mid, hi, dest):
    left, right, out = lo, mid, lo
    while left < mid and right < hi:
        if source[left] <= source[right]:
            dest[out] = source[left]
            left += 1
        else:
            dest[out] = source[right]
            right += 1
        out += 1
    while left < mid:
        dest[out] = source[left]
        left += 1
        out += 1
    while right < hi:
        dest[out] = source[right]
        right += 1
        out += 1


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    buffer = list(arr)

    lo = 0
    while lo < n:
        insertion_sort_range(arr, lo, min(lo + INSERTION_RUN, n))
        lo += INSERTION_RUN

    run_length = INSERTION_RUN
    while run_length < n:
        lo = 0
        while lo < n:
            mid = min(lo + run_length, n)
            hi = min(lo + run_length * 2, n)
            if mid - lo == run_length and hi - mid == run_length:
                parity_merge(arr, lo, run_length, buffer)
            elif mid < hi:
                merge_range(arr, lo, mid, hi, buffer)
            else:
                for i in range(lo, mid):
                    buffer[i] = arr[i]
            lo += run_length * 2
        arr[:] = buffer
        run_length *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
