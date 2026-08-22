def composite_less(arr, key, mid, i):
    if arr[mid] < arr[i]:
        return True
    if arr[mid] == arr[i]:
        return key[mid] < key[i]
    return False


def binary_search(arr, key, n, i):
    start = 0
    end = n - 1
    while start < end:
        mid = (start + end) // 2
        if composite_less(arr, key, mid, i):
            start = mid + 1
        else:
            end = mid
    return start


def sort(arr):
    n = len(arr)
    key = list(range(n))

    for i in range(1, n):
        done = False
        while not done:
            pos = binary_search(arr, key, n, i)
            if pos == i:
                done = True
            elif i < pos - 1:
                arr[i], arr[pos - 1] = arr[pos - 1], arr[i]
                key[i], key[pos - 1] = key[pos - 1], key[i]
            else:
                arr[i], arr[pos] = arr[pos], arr[i]
                key[i], key[pos] = key[pos], key[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
