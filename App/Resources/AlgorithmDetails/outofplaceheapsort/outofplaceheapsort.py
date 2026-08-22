def sift_down(array, root, size):
    index = root
    while 2 * index + 1 < size:
        child = 2 * index + 1
        if child + 1 < size and array[child + 1] > array[child]:
            child += 1
        index = child
    root_value = array[root]
    while root_value > array[index]:
        index = (index - 1) // 2
    while index != root:
        array[root], array[index] = array[index], array[root]
        index = (index - 1) // 2


def heapify(array, length):
    for i in range((length - 1) // 2, -1, -1):
        sift_down(array, i, length)


def find_next(array, size):
    hole = 0
    left = 1
    right = 2
    while right < size and not (array[left] == -1 and array[right] == -1):
        if array[left] == -1:
            array[hole], array[right] = array[right], array[hole]
            hole = right
        elif array[right] == -1:
            array[hole], array[left] = array[left], array[hole]
            hole = left
        elif array[right] > array[left]:
            array[hole], array[right] = array[right], array[hole]
            hole = right
        else:
            array[hole], array[left] = array[left], array[hole]
            hole = left
        left = 2 * hole + 1
        right = left + 1
    if left < size and array[left] != -1:
        array[hole], array[left] = array[left], array[hole]


def sort(array):
    n = len(array)
    output = [0] * n
    if n <= 1:
        if n == 1:
            output[0] = array[0]
        return output
    heapify(array, n)
    for i in range(n - 1, -1, -1):
        output[i] = array[0]
        array[0] = -1
        find_next(array, n)
    return output


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    output = sort(array)
    print(output)
