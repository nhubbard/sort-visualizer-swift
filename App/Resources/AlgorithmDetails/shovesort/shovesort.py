def sort(arr):
    end = len(arr)
    i = 0
    while i < end - 1:
        if arr[i] > arr[i + 1]:
            for f in range(i, end - 1):
                arr[f], arr[f + 1] = arr[f + 1], arr[f]
            if i > 0:
                i -= 1
            continue
        i += 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
