import random


def sort(arr):
    n = len(arr)
    while arr != sorted(arr):
        index = random.randint(0, n - 2)
        if arr[index] > arr[index + 1]:
            arr[index], arr[index + 1] = arr[index + 1], arr[index]


array = [0, 39, 21, 62, 91, 77, 14, 23]
sort(array)
print(array)
