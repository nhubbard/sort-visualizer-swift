def double_selection_sort(array):
    n = len(array)
    if n <= 1:
        return

    left = 0
    right = n - 1
    smallest = 0
    biggest = 0

    while left <= right:
        for i in range(left, right + 1):
            if array[i] > array[biggest]:
                biggest = i
            if array[i] < array[smallest]:
                smallest = i

        if biggest == left:
            biggest = smallest

        array[left], array[smallest] = array[smallest], array[left]
        array[right], array[biggest] = array[biggest], array[right]

        left += 1
        right -= 1
        smallest = left
        biggest = right


def sort(arr):
    double_selection_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
