def sort(arr)
  n = arr.length()

  index = 2
  while index <= n
    max_node = index
    while true
      focus = max_node
      depth = 1
      while (focus & depth) == 0
        if arr[focus - depth - 1] > arr[max_node - 1]
          max_node = focus - depth
        end
        depth *= 2
      end
      if focus != max_node
        arr[focus - 1], arr[max_node - 1] = arr[max_node - 1], arr[focus - 1]
      end
      if focus == max_node
        break
      end
    end
    index += 2
  end

  index = n
  while index > 2
    max_node = index
    focus = index
    depth = 1
    while focus != 0
      if (focus & depth) != 0
        if arr[focus - 1] > arr[max_node - 1]
          max_node = focus
        end
        focus -= depth
      end
      depth *= 2
    end

    if max_node != index
      focus = index
      while true
        arr[focus - 1], arr[max_node - 1] = arr[max_node - 1], arr[focus - 1]
        focus = max_node
        inner_depth = 1
        while (focus & inner_depth) == 0
          if arr[focus - inner_depth - 1] > arr[max_node - 1]
            max_node = focus - inner_depth
          end
          inner_depth *= 2
        end
        if focus == max_node
          break
        end
      end
    end
    index -= 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
