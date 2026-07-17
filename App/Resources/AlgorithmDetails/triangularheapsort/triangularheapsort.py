import math


def triangular_root(val):
    return (int(math.sqrt(8 * val + 1)) - 1) // 2


def sift_down(array, root, size):
    while True:
        row = triangular_root(root)
        left = root + row + 1
        if left >= size:
            break
        right = left + 1
        largest = root
        if array[largest] < array[left]:
            largest = left
        if right < size and array[largest] < array[right]:
            largest = right
        if largest == root:
            break
        array[root], array[largest] = array[largest], array[root]
        root = largest


def heapify(array, length):
    for i in range(length - 1, -1, -1):
        sift_down(array, i, length)


def sort(array):
    n = len(array)
    if n <= 1:
        return
    heapify(array, n)
    for i in range(1, n - 1):
        array[0], array[n - i] = array[n - i], array[0]
        sift_down(array, 0, n - i)
    if array[0] > array[1]:
        array[0], array[1] = array[1], array[0]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
