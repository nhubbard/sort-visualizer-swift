import random

def sort(arr, length=None):
    if length is None:
        length = len(arr)
    if length == 1:
        return
    sort(arr, length - 1)
    while arr[length - 2] > arr[length - 1]:
        sub = arr[:length]
        random.shuffle(sub)
        arr[:length] = sub
        sort(arr, length - 1)

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
