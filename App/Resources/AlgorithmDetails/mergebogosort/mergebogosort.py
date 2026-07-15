import random

def sort(arr, start=0, end=None):
    if end is None:
        end = len(arr)
    if start >= end - 1:
        return
    mid = (start + end) // 2
    sort(arr, start, mid)
    sort(arr, mid, end)

    saved = arr[start:end]

    def is_sorted():
        for i in range(start, end - 1):
            if arr[i] > arr[i + 1]:
                return False
        return True

    while not is_sorted():
        high_positions = set(random.sample(range(end - start), end - mid))
        low, high = 0, mid - start
        for offset in range(end - start):
            if offset in high_positions:
                arr[start + offset] = saved[high]
                high += 1
            else:
                arr[start + offset] = saved[low]
                low += 1

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
