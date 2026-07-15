def sort(arr):
    n = len(arr)
    heap_size = n - 1

    def max_heapify(i):
        left, mid, right = 3 * i + 1, 3 * i + 2, 3 * i + 3
        largest = i
        if left <= heap_size and arr[left] > arr[largest]:
            largest = left
        if right <= heap_size and arr[right] > arr[largest]:
            largest = right
        if mid <= heap_size and arr[mid] > arr[largest]:
            largest = mid
        if largest != i:
            arr[i], arr[largest] = arr[largest], arr[i]
            max_heapify(largest)

    for i in range(n - 1, -1, -1):
        max_heapify(i)

    for i in range(n - 1, -1, -1):
        arr[0], arr[i] = arr[i], arr[0]
        heap_size -= 1
        max_heapify(0)

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
