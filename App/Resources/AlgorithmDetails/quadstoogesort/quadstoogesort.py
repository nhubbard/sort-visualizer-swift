def quad_stooge(arr, pos, length):
    if length >= 2 and arr[pos] > arr[pos + length - 1]:
        arr[pos], arr[pos + length - 1] = arr[pos + length - 1], arr[pos]
    if length <= 2:
        return

    len1 = length // 2
    len2 = (length + 1) // 2
    len3 = (len1 + 1) // 2 + (len2 + 1) // 2

    quad_stooge(arr, pos, len1)
    quad_stooge(arr, pos + len1, len2)
    quad_stooge(arr, pos + len1 // 2, len3)
    quad_stooge(arr, pos + len1, len2)
    quad_stooge(arr, pos, len1)
    if length > 3:
        quad_stooge(arr, pos + len1 // 2, len3)


def sort(arr):
    quad_stooge(arr, 0, len(arr))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
