def sort(arr):
    def comp_swap(a, b):
        if arr[a] > arr[b]:
            arr[a], arr[b] = arr[b], arr[a]

    def pairwise_recursive(start, end, gap):
        if start == end - gap:
            return
        b = start + gap
        while b < end:
            comp_swap(b - gap, b)
            b += 2 * gap

        if ((end - start) // gap) % 2 == 0:
            pairwise_recursive(start, end, gap * 2)
            pairwise_recursive(start + gap, end + gap, gap * 2)
        else:
            pairwise_recursive(start, end + gap, gap * 2)
            pairwise_recursive(start + gap, end, gap * 2)

        a = 1
        while a < (end - start) // gap:
            a = (a * 2) + 1

        b = start + gap
        while b + gap < end:
            c = a
            while c > 1:
                c //= 2
                if b + (c * gap) < end:
                    comp_swap(b, b + (c * gap))
            b += 2 * gap

    pairwise_recursive(0, len(arr), 1)
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
