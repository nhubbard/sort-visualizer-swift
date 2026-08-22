def unoptimized_cocktail_shaker_sort(array):
    n = len(array)
    i = 0
    while i < n // 2:
        for j in range(i, n - i - 1):
            if array[j] > array[j + 1]:
                array[j], array[j + 1] = array[j + 1], array[j]
        for j in range(n - i - 1, i, -1):
            if array[j] < array[j - 1]:
                array[j], array[j - 1] = array[j - 1], array[j]
        i = i + 1


def sort(arr):
    unoptimized_cocktail_shaker_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
