def insert_to(array, a, b):
    temp = array[a]
    while a > b:
        a -= 1
        array[a + 1] = array[a]
    array[b] = temp


def multi_swap(array, a, b, length):
    for i in range(length):
        array[a + i], array[b + i] = array[b + i], array[a + i]


def rotate(array, a, m, b):
    l = m - a
    r = b - m
    while l > 0 and r > 0:
        if r < l:
            multi_swap(array, m - r, m, r)
            b -= r
            m -= r
            l -= r
        else:
            multi_swap(array, a, m, l)
            a += l
            m += l
            r -= l


def bit_reversal(array, a, b):
    length = b - a
    m = 0
    d1 = length >> 1
    d2 = d1 + (d1 >> 1)
    i = 1
    while i < length - 1:
        j = d1
        k = i
        nn = d2
        while k & 1 == 0:
            j -= nn
            k >>= 1
            nn >>= 1
        m += j
        if m > i:
            array[a + i], array[a + m] = array[a + m], array[a + i]
        i += 1


def weave_insert(array, a, b, right):
    i = a
    j = a + 1
    while j < b:
        if right:
            while i < j and array[i] <= array[j]:
                i += 1
        else:
            while i < j and array[i] < array[j]:
                i += 1
        if i == j:
            right = not right
            j += 1
        else:
            insert_to(array, j, i)
            i += 1
            j += 2


def weave_merge(array, a, m_init, b):
    if b - a < 2:
        return
    a1 = a
    b1 = b
    right = True
    if (b - a) % 2 == 1:
        if m_init - a < b - m_init:
            a1 -= 1
            right = False
        else:
            b1 += 1
    e = b1
    while e - a1 > 2:
        m = (a1 + e) // 2
        p = 1
        while p * 2 <= m - a1:
            p *= 2
        rotate(array, m - p, m, e - p)
        m = e - p
        f = m - p
        bit_reversal(array, f, m)
        bit_reversal(array, m, e)
        bit_reversal(array, f, e)
        e = f
    weave_insert(array, a, b, right)


def sort(array):
    n = len(array)
    if n <= 1:
        return
    d = 1
    while d < n:
        d <<= 1
    while d > 1:
        i = 0
        dec = 0
        while i < n:
            j = i
            dec += n
            while dec >= d:
                dec -= d
                j += 1
            k = j
            dec += n
            while dec >= d:
                dec -= d
                k += 1
            weave_merge(array, i, j, k)
            i = k
        d //= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
