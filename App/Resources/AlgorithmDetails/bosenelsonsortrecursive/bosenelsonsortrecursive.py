def sort(arr):
    n = len(arr)

    def compSwap(start, end):
        if arr[start] > arr[end]:
            arr[start], arr[end] = arr[end], arr[start]

    def merge(start1, len1, start2, len2):
        if len1 == 1 and len2 == 1:
            compSwap(start1, start2)
        elif len1 == 1 and len2 == 2:
            compSwap(start1, start2 + 1)
            compSwap(start1, start2)
        elif len1 == 2 and len2 == 1:
            compSwap(start1, start2)
            compSwap(start1 + 1, start2)
        else:
            mid1 = len1 // 2
            mid2 = len2 // 2 if len1 % 2 == 1 else (len2 + 1) // 2
            merge(start1, mid1, start2, mid2)
            merge(start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2)
            merge(start1 + mid1, len1 - mid1, start2, mid2)

    def boseNelson(start, length):
        if length > 1:
            mid = length // 2
            boseNelson(start, mid)
            boseNelson(start + mid, length - mid)
            merge(start, mid, start + mid, length - mid)

    boseNelson(0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
