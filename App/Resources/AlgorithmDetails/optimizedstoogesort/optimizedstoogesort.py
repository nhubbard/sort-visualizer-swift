def forward(arr, left, right):
    while left < right:
        index = right
        while left < index:
            if arr[left] > arr[index]:
                arr[left], arr[index] = arr[index], arr[left]
            left += 1
            index -= 1
        left = 0
        right -= 1


def backward(arr, left, right):
    length = right
    while left < right:
        index = left
        while index < right:
            if arr[index] > arr[right]:
                arr[index], arr[right] = arr[right], arr[index]
            index += 1
            right -= 1
        left += 1
        right = length


def exchange(arr, length):
    left = 0
    right = length - 1
    while left < right:
        if arr[left] > arr[right]:
            arr[left], arr[right] = arr[right], arr[left]
        left += 1
        right -= 1

    forward(arr, 0, length - 2)
    backward(arr, 1, length - 1)


def sort(arr):
    exchange(arr, len(arr))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
