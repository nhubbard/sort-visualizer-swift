def sort(arr):
    n = len(arr)
    gaps = (8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1)
    for gap in gaps:
        if gap >= n:
            continue
        for i in range(gap, n):
            j = i
            while j >= gap and arr[j] < arr[j - gap]:
                arr[j], arr[j - gap] = arr[j - gap], arr[j]
                j -= gap


if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
