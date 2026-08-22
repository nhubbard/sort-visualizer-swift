import math


def sort(arr):
    def dir_compare_val(left, right, dir_):
        if left > right:
            res = 1
        elif left < right:
            res = -1
        else:
            res = 0
        return res if dir_ else -res

    def gap_reverse(start, end, gap):
        i, j = start, end
        while i < j:
            arr[i], arr[j - gap] = arr[j - gap], arr[i]
            i += gap
            j -= gap

    def insert_last(a, b, gap, dir_):
        did = False
        key = arr[b]
        j = b - gap
        while j >= a and dir_compare_val(key, arr[j], dir_) < 0:
            arr[j + gap] = arr[j]
            did = True
            j -= gap
        arr[j + gap] = key
        return did

    class MatrixShape:
        def __init__(self, width, height, insert_last):
            self.width = width
            self.unbalanced = (width == 1) != (height == 1)
            self.insert_last = self.unbalanced or insert_last

    def get_matrix_dims(length):
        dim = math.isqrt(length)
        insert_last_ = dim * dim == length - 1
        while length % dim != 0:
            dim -= 1
        return MatrixShape(dim, length // dim, insert_last_)

    def matrix_sort(start, end, gap, dir_):
        length = (end - start) // gap
        if length < 2:
            return False
        elif length <= 16:
            did = False
            i = start
            while i < end:
                did = insert_last(start, i, gap, dir_) or did
                i += gap
            return did
        else:
            mat_shape = get_matrix_dims(length)
            if mat_shape.insert_last:
                did1 = matrix_sort(start, end - gap, gap, dir_)
                did2 = insert_last(start, end - gap, gap, dir_)
                return did1 or did2

            i = start + mat_shape.width * gap
            while i < end:
                gap_reverse(i, i + mat_shape.width * gap, gap)
                i += 2 * mat_shape.width * gap

            did = False
            newdid = True
            while newdid:
                newdid = False
                curdir = dir_
                i = start
                while i < end:
                    newdid = (
                        matrix_sort(i, i + mat_shape.width * gap, gap, curdir) or newdid
                    )
                    did = did or newdid
                    curdir = not curdir
                    i += mat_shape.width * gap

                newdid = False
                for k in range(mat_shape.width):
                    newdid = (
                        matrix_sort(
                            start + k * gap, end + k * gap, gap * mat_shape.width, dir_
                        )
                        or newdid
                    )
                    did = did or newdid
            i = start + mat_shape.width * gap
            while i < end:
                gap_reverse(i, i + mat_shape.width * gap, gap)
                i += 2 * mat_shape.width * gap

            return did

    matrix_sort(0, len(arr), 1, True)
    return arr


if __name__ == "__main__":
    array = [
        15,
        3,
        22,
        8,
        19,
        1,
        24,
        11,
        6,
        20,
        9,
        17,
        2,
        14,
        23,
        5,
        18,
        0,
        12,
        21,
        7,
        16,
        4,
        13,
        10,
    ]
    sort(array)
    print(array)
