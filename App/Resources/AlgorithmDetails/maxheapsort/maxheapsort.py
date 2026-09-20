def sift_down(arr, root, size):
    while True:
        largest = root
        left = 2 * root + 1
        right = left + 1
        if left < size and arr[largest] < arr[left]:
            largest = left
        if right < size and arr[largest] < arr[right]:
            largest = right
        if largest == root:
            break
        arr[root], arr[largest] = arr[largest], arr[root]
        root = largest


def sort(arr):
    n = len(arr)
    for i in range(n // 2 - 1, -1, -1):
        sift_down(arr, i, n)
    for i in range(n - 1, 0, -1):
        arr[i], arr[0] = arr[0], arr[i]
        sift_down(arr, 0, i)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
