def cycle_sort(array):
    n = len(array)
    for cycle_start in range(n - 1):
        item = array[cycle_start]
        pos = cycle_start
        for i in range(cycle_start + 1, n):
            if array[i] < item:
                pos += 1
        if pos == cycle_start:
            continue
        while item == array[pos]:
            pos += 1
        array[pos], item = item, array[pos]
        while pos != cycle_start:
            pos = cycle_start
            for i in range(cycle_start + 1, n):
                if array[i] < item:
                    pos += 1
            while item == array[pos]:
                pos += 1
            array[pos], item = item, array[pos]
    return array


def sort(arr):
    cycle_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
