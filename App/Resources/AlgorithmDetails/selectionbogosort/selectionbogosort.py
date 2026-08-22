import random


def sort(arr):
    n = len(arr)
    for i in range(n):
        while arr[i] != min(arr[i:]):
            j = random.randint(i, n - 1)
            arr[i], arr[j] = arr[j], arr[i]


array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
