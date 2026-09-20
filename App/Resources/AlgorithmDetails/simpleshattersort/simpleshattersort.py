def sort(arr):
    if len(arr) < 2:
        return
    n = len(arr)
    rate = max(2, floor_log2(n) // 2)
    simple_shatter_sort(arr, n, 4, rate)

def insertion_sort(arr, start, end):
    for i in range(start + 1, end):
        pos = i
        while pos > start and arr[pos - 1] > arr[pos]:
            arr[pos - 1], arr[pos] = arr[pos], arr[pos - 1]
            pos -= 1

def shatter_partition(arr, start, length, num):
    window = arr[start : start + length]
    min_v = min(window)
    max_v = max(window)
    value_range = max_v - min_v + 1
    shatters = -(-length // num)

    buckets = [[] for _ in range(shatters)]
    for v in window:
        idx = min(shatters - 1, (v - min_v) * shatters // value_range)
        buckets[idx].append(v)

    offsets = [0] * (shatters + 1)
    for i in range(shatters):
        offsets[i + 1] = offsets[i] + len(buckets[i])

    pos = start
    for bucket in buckets:
        for v in bucket:
            arr[pos] = v
            pos += 1
    return offsets


def floor_log2(n):
    log = 0
    m = n
    while m > 1:
        m >>= 1
        log += 1
    return log


def simple_shatter_sort(arr, length, num, rate):
    i = num
    while i > 1:
        shatter_partition(arr, 0, length, i)
        i = i // rate
    offsets = shatter_partition(arr, 0, length, 1)
    for k in range(len(offsets) - 1):
        if offsets[k + 1] - offsets[k] > 1:
            insertion_sort(arr, offsets[k], offsets[k + 1])




if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
