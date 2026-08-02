def sort(arr):
    n = len(arr)
    if n == 0:
        return arr
    min_value = min(arr)

    for i in range(n):
        cmp_count = 0
        while arr[i] - min_value != i and cmp_count < n:
            j = arr[i] - min_value
            arr[i], arr[j] = arr[j], arr[i]
            cmp_count += 1
        if cmp_count >= n - 1:
            break
    return arr


if __name__ == "__main__":
    array = [7, 3, 14, 0, 9, 5, 12, 1, 15, 4, 10, 2, 13, 6, 11, 8]
    sort(array)
    print(array)
