def reverse_range(arr, lo, hi):
    while lo < hi:
        arr[lo], arr[hi] = arr[hi], arr[lo]
        lo += 1
        hi -= 1


def twin_swap(arr, nmemb):
    index = 0
    end = nmemb - 2
    while index <= end:
        if arr[index] <= arr[index + 1]:
            index += 2
            continue
        start = index
        index += 2
        while True:
            if index > end:
                if start == 0 and (nmemb % 2 == 0 or arr[index - 1] > arr[index]):
                    end = nmemb - 1
                    reverse_range(arr, start, end)
                    return 1
                break
            if arr[index] > arr[index + 1]:
                if arr[index - 1] > arr[index]:
                    index += 2
                    continue
                arr[index], arr[index + 1] = arr[index + 1], arr[index]
            break
        end = index - 1
        reverse_range(arr, start, end)
        end = nmemb - 2
        index += 2
    return 0


def tail_merge(arr, buf, nmemb, block):
    s = 0
    while block < nmemb:
        offset = 0
        while offset + block < nmemb:
            a = offset
            e = a + block - 1
            if arr[e] <= arr[e + 1]:
                offset += block * 2
                continue
            if offset + block * 2 <= nmemb:
                c_max = s + block
                d_max = a + block * 2
            else:
                c_max = s + nmemb - (offset + block)
                d_max = nmemb
            d = d_max - 1
            while arr[e] <= arr[d]:
                d_max -= 1
                d -= 1
                c_max -= 1
            c = s
            d = a + block
            while c < c_max:
                buf[c] = arr[d]
                c += 1
                d += 1
            c -= 1
            d = a + block - 1
            e = d_max - 1
            if arr[a] <= arr[a + block]:
                arr[e] = arr[d]
                e -= 1
                d -= 1
                while c >= s:
                    while arr[d] > buf[c]:
                        arr[e] = arr[d]
                        e -= 1
                        d -= 1
                    arr[e] = buf[c]
                    e -= 1
                    c -= 1
            else:
                arr[e] = arr[d]
                e -= 1
                d -= 1
                while d >= a:
                    while arr[d] <= buf[c]:
                        arr[e] = buf[c]
                        e -= 1
                        c -= 1
                    arr[e] = arr[d]
                    e -= 1
                    d -= 1
                while c >= s:
                    arr[e] = buf[c]
                    e -= 1
                    c -= 1
            offset += block * 2
        block *= 2


def twinsort(arr, nmemb):
    if twin_swap(arr, nmemb) == 0:
        buf = [0] * (nmemb // 2)
        tail_merge(arr, buf, nmemb, 2)


def sort(arr):
    n = len(arr)
    twinsort(arr, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
