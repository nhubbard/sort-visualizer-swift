def sort(arr):
    n = len(arr)
    if n < 2 or all(arr[i] >= arr[i - 1] for i in range(1, n)):
        return

    while True:
        pivot = n - 2
        while pivot >= 0 and arr[pivot] >= arr[pivot + 1]:
            pivot -= 1
        if pivot < 0:
            break
        successor = n - 1
        while arr[successor] <= arr[pivot]:
            successor -= 1
        arr[pivot], arr[successor] = arr[successor], arr[pivot]
        arr[pivot + 1 :] = reversed(arr[pivot + 1 :])
    arr.reverse()


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23]
    sort(array)
    print(array)
