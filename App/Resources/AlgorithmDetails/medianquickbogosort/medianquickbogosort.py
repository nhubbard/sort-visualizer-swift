import random

def sort(arr, start=0, end=None):
    if end is None:
        end = len(arr)
    if start >= end - 1:
        return
    mid = (start + end) // 2

    def is_split():
        low_max = arr[start]
        for i in range(start + 1, mid):
            if arr[i] > low_max:
                low_max = arr[i]
        for i in range(mid, end):
            if low_max > arr[i]:
                return False
        return True

    while not is_split():
        sub = arr[start:end]
        random.shuffle(sub)
        arr[start:end] = sub

    sort(arr, start, mid)
    sort(arr, mid, end)

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
