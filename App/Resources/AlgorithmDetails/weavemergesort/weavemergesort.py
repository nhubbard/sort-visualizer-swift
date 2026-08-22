def multi_swap(arr, pos, to):
    if to - pos > 0:
        for i in range(pos, to):
            arr[i], arr[i + 1] = arr[i + 1], arr[i]
    else:
        for i in range(pos, to, -1):
            arr[i], arr[i - 1] = arr[i - 1], arr[i]


def weave_insert(arr, start, end):
    for j in range(start, end):
        pos = j
        while pos > start and arr[pos] <= arr[pos - 1]:
            arr[pos], arr[pos - 1] = arr[pos - 1], arr[pos]
            pos -= 1


def weave_merge(arr, min_i, max_i, mid):
    target = mid - min_i
    for i in range(1, target + 1):
        multi_swap(arr, mid + i, min_i + (i * 2) - 1)
    weave_insert(arr, min_i, max_i + 1)


def weave_merge_sort(arr, min_i, max_i):
    if max_i - min_i == 0:
        return
    elif max_i - min_i == 1:
        if arr[min_i] > arr[max_i]:
            arr[min_i], arr[max_i] = arr[max_i], arr[min_i]
    else:
        mid = (min_i + max_i) // 2
        weave_merge_sort(arr, min_i, mid)
        weave_merge_sort(arr, mid + 1, max_i)
        weave_merge(arr, min_i, max_i, mid)


def sort(arr):
    if len(arr) > 1:
        weave_merge_sort(arr, 0, len(arr) - 1)
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
