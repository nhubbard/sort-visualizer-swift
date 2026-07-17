def snuffle_sort(arr, start, stop):
    if stop - start + 1 >= 2:
        if arr[start] > arr[stop]:
            arr[start], arr[stop] = arr[stop], arr[start]
        if stop - start + 1 >= 3:
            mid = (stop - start) // 2 + start
            iterations = (stop - start + 1) // 2
            for _ in range(iterations):
                snuffle_sort(arr, start, mid)
                snuffle_sort(arr, mid, stop)


def sort(arr):
    snuffle_sort(arr, 0, len(arr) - 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23]
    sort(array)
    print(array)
