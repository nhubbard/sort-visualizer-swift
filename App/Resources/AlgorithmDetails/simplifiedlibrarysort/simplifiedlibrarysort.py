def binary_search(array, item, start, end):
    lo = start
    hi = end
    while lo < hi:
        mid = lo + (hi - lo) // 2
        if item < array[mid]:
            hi = mid
        else:
            lo = mid + 1
    return lo


def binary_insertion_sort(array, start, end):
    for i in range(start + 1, end):
        item = array[i]
        pos = binary_search(array, item, start, i)
        j = i
        while j > pos:
            array[j] = array[j - 1]
            j -= 1
        array[pos] = item


def rebalance(array, temp, counts, locations, spine_size, batch_end):
    for i in range(spine_size):
        counts[i + 1] = counts[i + 1] + counts[i] + 1

    for k, i in enumerate(range(spine_size, batch_end)):
        gap = locations[k]
        position = counts[gap]
        temp[position] = array[i]
        counts[gap] = position + 1

    for i in range(spine_size):
        position = counts[i]
        temp[position] = array[i]
        counts[i] = position + 1

    for i in range(batch_end):
        array[i] = temp[i]

    binary_insertion_sort(array, 0, counts[0] - 1)
    for i in range(spine_size - 1):
        binary_insertion_sort(array, counts[i], counts[i + 1] - 1)
    binary_insertion_sort(array, counts[spine_size - 1], counts[spine_size])

    for i in range(spine_size + 2):
        counts[i] = 0


def library_sort(array):
    n = len(array)
    if n < 2:
        return array

    rebalance_factor = 2
    spine_size = 1
    binary_insertion_sort(array, 0, spine_size)

    max_level = spine_size
    while max_level * rebalance_factor < n:
        max_level *= rebalance_factor

    temp = [0] * n
    counts = [0] * (max_level + 2)
    locations = [0] * n

    i = spine_size
    k = 0
    while i < n:
        if rebalance_factor * spine_size == i:
            rebalance(array, temp, counts, locations, spine_size, i)
            spine_size = i
            k = 0
        gap = binary_search(array, array[i], 0, spine_size)
        counts[gap + 1] += 1
        locations[k] = gap
        k += 1
        i += 1
    rebalance(array, temp, counts, locations, spine_size, n)
    return array


def sort(arr):
    return library_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
