def sort(arr):
    i = len(arr) - 1
    while i > 0:
        consec_sorted = 1
        for j in range(i):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                consec_sorted = 1
            else:
                consec_sorted += 1
        i -= consec_sorted


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
