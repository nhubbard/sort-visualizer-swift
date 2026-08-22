import random


def is_sorted(arr):
    for i in range(1, len(arr)):
        if arr[i - 1] > arr[i]:
            return False
    return True


def sort(arr):
    n = len(arr)
    while not is_sorted(arr):
        i = random.randrange(n)
        j = random.randrange(n)
        arr[i], arr[j] = arr[j], arr[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77]
    sort(array)
    print(array)
