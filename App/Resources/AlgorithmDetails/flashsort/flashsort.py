def classify(value, min_value, c):
    return int((value - min_value) * c) + 1


def flash_sort(array):
    n = len(array)
    if n == 0:
        return

    m = int(0.2 * n) + 2

    min_value = max_value = array[0]
    max_index = 0

    i = 1
    while i < n - 1:
        if array[i] < array[i + 1]:
            small, big, big_index = array[i], array[i + 1], i + 1
        else:
            big, big_index, small = array[i], i, array[i + 1]
        if big > max_value:
            max_value = big
            max_index = big_index
        if small < min_value:
            min_value = small
        i += 2

    last = array[n - 1]
    if last < min_value:
        min_value = last
    elif last > max_value:
        max_value = last
        max_index = n - 1

    if max_value == min_value:
        return

    L = [0] * (m + 1)
    c = (m - 1.0) / (max_value - min_value)

    for h in range(n):
        k = classify(array[h], min_value, c)
        L[k] += 1

    for k in range(2, m + 1):
        L[k] += L[k - 1]

    array[max_index], array[0] = array[0], array[max_index]

    j = 0
    k = m
    num_moves = 0
    while num_moves < n:
        while j >= L[k]:
            j += 1
            k = classify(array[j], min_value, c)

        evicted = array[j]
        while j < L[k]:
            k = classify(evicted, min_value, c)
            location = L[k] - 1
            temp = array[location]
            array[location] = evicted
            evicted = temp
            L[k] -= 1
            num_moves += 1

    for i in range(1, n):
        current = array[i]
        pos = i - 1
        while pos >= 0 and array[pos] > current:
            array[pos + 1] = array[pos]
            pos -= 1
        array[pos + 1] = current


def sort(arr):
    flash_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
