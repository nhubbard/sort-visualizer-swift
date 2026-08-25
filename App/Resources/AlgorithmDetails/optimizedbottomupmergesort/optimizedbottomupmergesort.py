BLOCK_SIZE = 16


def binary_insertion_sort(arr, lo, hi):
    for i in range(lo + 1, hi):
        key = arr[i]
        left, right = lo, i
        while left < right:
            mid = (left + right) // 2
            if arr[mid] <= key:
                left = mid + 1
            else:
                right = mid
        j = i
        while j > left:
            arr[j] = arr[j - 1]
            j -= 1
        arr[left] = key


def merge(src, dst, low, mid, high):
    i, j, k = low, mid, low
    while i < mid and j < high:
        if src[i] <= src[j]:
            dst[k] = src[i]
            i += 1
        else:
            dst[k] = src[j]
            j += 1
        k += 1
    while i < mid:
        dst[k] = src[i]
        i += 1
        k += 1
    while j < high:
        dst[k] = src[j]
        j += 1
        k += 1


def sort(arr):
    n = len(arr)
    if n < BLOCK_SIZE:
        binary_insertion_sort(arr, 0, n)
        return

    low = 0
    while low < n:
        binary_insertion_sort(arr, low, min(low + BLOCK_SIZE, n))
        low += BLOCK_SIZE

    scratch = [0] * n
    src, dst = arr, scratch
    width = BLOCK_SIZE
    passes = 0
    while width < n:
        low = 0
        while low < n:
            mid = min(low + width, n)
            high = min(low + 2 * width, n)
            if mid < high:
                merge(src, dst, low, mid, high)
            else:
                for i in range(low, mid):
                    dst[i] = src[i]
            low += 2 * width
        src, dst = dst, src
        width *= 2
        passes += 1

    # An even number of passes lands the sorted result back in arr on its own; an odd
    # number leaves it in scratch, needing this one explicit copy back.
    if passes % 2 == 1:
        arr[:] = src


if __name__ == "__main__":
    array = [
        81,
        14,
        3,
        94,
        35,
        31,
        28,
        17,
        94,
        13,
        86,
        94,
        69,
        11,
        75,
        54,
        4,
        3,
        11,
        27,
        29,
        64,
        77,
        3,
        71,
        25,
        91,
        83,
        89,
        69,
        53,
        28,
        57,
        75,
        35,
        0,
        97,
        20,
        89,
        54,
    ]
    sort(array)
    print(array)
