import random


def is_minimum(arr, start, end):
    for k in range(start + 1, end):
        if arr[start] > arr[k]:
            return False
    return True


def shuffle_range(arr, start, end):
    for i in range(start, end - 1):
        j = random.randrange(i, end)
        arr[i], arr[j] = arr[j], arr[i]


def sort(arr):
    n = len(arr)
    for i in range(n):
        while not is_minimum(arr, i, n):
            shuffle_range(arr, i, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23]
    sort(array)
    print(array)
