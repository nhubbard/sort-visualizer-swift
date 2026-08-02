def stable_partition(arr, start, end):
    pivot_value = arr[start]
    left_list = []
    right_list = []

    for i in range(start + 1, end + 1):
        if arr[i] < pivot_value:
            left_list.append(arr[i])
        else:
            right_list.append(arr[i])

    write_index = start
    for v in left_list:
        arr[write_index] = v
        write_index += 1
    pivot_index = write_index
    arr[write_index] = pivot_value
    write_index += 1
    for v in right_list:
        arr[write_index] = v
        write_index += 1
    return pivot_index


def stable_quick_sort(arr, start, end):
    if start < end:
        p = stable_partition(arr, start, end)
        stable_quick_sort(arr, start, p - 1)
        stable_quick_sort(arr, p + 1, end)


def sort(arr):
    n = len(arr)
    stable_quick_sort(arr, 0, n - 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
