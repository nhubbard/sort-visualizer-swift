import random


def sort(arr, start=0, end=None):
    if end is None:
        end = len(arr)
    if start >= end - 1:
        return

    pivot = start

    def is_partitioned():
        for i in range(start, pivot):
            if arr[i] > arr[pivot]:
                return False
        for i in range(pivot + 1, end):
            if arr[pivot] > arr[i]:
                return False
        return True

    while not is_partitioned():
        for i in range(start, end):
            j = random.randint(i, end - 1)
            if pivot == i:
                pivot = j
            elif pivot == j:
                pivot = i
            arr[i], arr[j] = arr[j], arr[i]

    sort(arr, start, pivot)
    sort(arr, pivot + 1, end)


array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
