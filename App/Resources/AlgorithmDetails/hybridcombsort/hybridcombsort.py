def insertion_sort(arr):
    n = len(arr)
    for i in range(1, n):
        key = arr[i]
        j = i - 1
        while j >= 0 and arr[j] > key:
            arr[j + 1] = arr[j]
            j = j - 1
        arr[j + 1] = key


def sort(arr):
    n = len(arr)
    shrink = 1.3
    gap = n
    sorted = False
    threshold = min(8, n // 32)
    while not sorted:
        gap = int(gap / shrink)
        if gap <= 1:
            sorted = True
            gap = 1
        for i in range(n - gap):
            if gap <= threshold:
                insertion_sort(arr)
                return
            sm = gap + i
            if arr[i] > arr[sm]:
                arr[i], arr[sm] = arr[sm], arr[i]
                sorted = False


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
