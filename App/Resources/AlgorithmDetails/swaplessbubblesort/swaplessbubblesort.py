def swapless_bubble_sort(array):
    i = len(array)
    while i > 0:
        last = 0
        pos = 0
        comp = array[0]
        for j in range(1, i):
            if comp > array[j]:
                array[j - 1] = array[j]
                last = j
            else:
                if pos + 1 < j:
                    array[j - 1] = comp
                pos = j
                comp = array[j]
        array[i - 1] = comp
        i = last


def sort(arr):
    swapless_bubble_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
