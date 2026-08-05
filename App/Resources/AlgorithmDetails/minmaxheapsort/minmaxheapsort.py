def bit_length(value):
    length = 0
    while value > 0:
        value >>= 1
        length += 1
    return length


def is_min_level(index):
    return bit_length(index + 1) % 2 == 1


def better_than(a, b, min_level):
    return a < b if min_level else a > b


def downheap(array, start, size):
    i = start
    while True:
        min_level = is_min_level(i)
        left = 2 * i + 1
        right = 2 * i + 2
        if left >= size:
            return
        winner = left
        if right < size and better_than(array[right], array[winner], min_level):
            winner = right
        base = 4 * i + 3
        for offset in range(4):
            gc = base + offset
            if gc < size and better_than(array[gc], array[winner], min_level):
                winner = gc
        is_grandchild = winner >= base
        extreme = better_than(array[winner], array[i], min_level)
        if not is_grandchild:
            if extreme:
                array[i], array[winner] = array[winner], array[i]
            return
        if extreme:
            array[i], array[winner] = array[winner], array[i]
        else:
            return
        parent = (winner - 1) // 2
        if min_level:
            if array[winner] > array[parent]:
                array[parent], array[winner] = array[winner], array[parent]
        else:
            if array[winner] < array[parent]:
                array[parent], array[winner] = array[winner], array[parent]
        i = winner


def heapify(array, length):
    for i in range((length - 1) // 2, -1, -1):
        downheap(array, i, length)


def store_max(array, heap_size):
    if heap_size <= 1:
        return heap_size
    imax = 1
    if heap_size > 2 and array[2] > array[1]:
        imax = 2
    last = heap_size - 1
    array[imax], array[last] = array[last], array[imax]
    new_size = last
    if imax < new_size:
        downheap(array, imax, new_size)
    return new_size


def sort(arr):
    n = len(arr)
    if n <= 1:
        return
    heapify(arr, n)
    heap_size = n
    for _ in range(n - 1):
        heap_size = store_max(arr, heap_size)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
