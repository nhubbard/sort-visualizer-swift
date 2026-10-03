// The WikiSorting source is released to the public domain under the Unlicense.
class WikiRange(var start: Int=0, var end: Int=0) {
  fun length() = end-start
  fun set(first: Int,last: Int) { start=first;end=last }
  fun copy() = WikiRange(start,end)
}
class WikiPull(var from_: Int=0,var to: Int=0,var count: Int=0,var range: WikiRange=WikiRange())
class WikiIterator(val size: Int) {
  var denominator: Int
  var numeratorStep: Int
  var decimalStep: Int
  var numerator=0
  var decimal=0
  init { var power=1;while(power*2<=size)power*=2;denominator=power/4;numeratorStep=size%denominator;decimalStep=size/denominator }
  fun begin(){numerator=0;decimal=0}
  fun nextRange(): WikiRange { val start=decimal;decimal+=decimalStep;numerator+=numeratorStep;if(numerator>=denominator){numerator-=denominator;decimal++};return WikiRange(start,decimal) }
  fun finished()=decimal>=size
  fun nextLevel(): Boolean {decimalStep*=2;numeratorStep*=2;if(numeratorStep>=denominator){numeratorStep-=denominator;decimalStep++};return decimalStep<size}
  fun length()=decimalStep
}
class WikiSortExample(private val values: IntArray) {
  fun read(index: Int): Int {
    return values[index];
  }
  fun less(left: Int, right: Int): Boolean {
    return (values[left] < values[right]);
  }
  fun lessValues(left: Int, right: Int): Boolean {
    return (left < right);
  }
  fun greaterValues(left: Int, right: Int): Boolean {
    return (left > right);
  }
  fun swap(left: Int, right: Int) {
    var _sim0_0 = values[right]
    var _sim0_1 = values[left]
    values[left] = _sim0_0;
    values[right] = _sim0_1;
  }
  fun binaryFirst(value: Int, range: WikiRange): Int {
    var end = 0
    var middle = 0
    var start = 0
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((values[middle] < value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
  fun binaryLast(value: Int, range: WikiRange): Int {
    var end = 0
    var middle = 0
    var start = 0
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((values[middle] <= value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
  fun findFirstForward(value: Int, range: WikiRange, unique: Int): Int {
    var index = 0
    var skip = 0
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = maxOf((range.length() / maxOf(unique, 1)), 1);
    index = (range.start + skip);
    while ((values[(index - 1)] < value)) {
      if ((index >= (range.end - skip))) {
        return binaryFirst(value, WikiRange(index, range.end));
      }
      index += skip;
    }
    return binaryFirst(value, WikiRange((index - skip), index));
  }
  fun findLastForward(value: Int, range: WikiRange, unique: Int): Int {
    var index = 0
    var skip = 0
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = maxOf((range.length() / maxOf(unique, 1)), 1);
    index = (range.start + skip);
    while ((values[(index - 1)] <= value)) {
      if ((index >= (range.end - skip))) {
        return binaryLast(value, WikiRange(index, range.end));
      }
      index += skip;
    }
    return binaryLast(value, WikiRange((index - skip), index));
  }
  fun findFirstBackward(value: Int, range: WikiRange, unique: Int): Int {
    var index = 0
    var skip = 0
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = maxOf((range.length() / maxOf(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (values[(index - 1)] >= value))) {
      if ((index < (range.start + skip))) {
        return binaryFirst(value, WikiRange(range.start, index));
      }
      index -= skip;
    }
    return binaryFirst(value, WikiRange(index, (index + skip)));
  }
  fun findLastBackward(value: Int, range: WikiRange, unique: Int): Int {
    var index = 0
    var skip = 0
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = maxOf((range.length() / maxOf(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (values[(index - 1)] > value))) {
      if ((index < (range.start + skip))) {
        return binaryLast(value, WikiRange(range.start, index));
      }
      index -= skip;
    }
    return binaryLast(value, WikiRange(index, (index + skip)));
  }
  fun insertionSort(range: WikiRange) {
    var cursor = 0
    var destination = 0
    var index = 0
    var value = 0
    if (!((range.length() > 1))) {
      return;
    }
    for (index in (range.start + 1) until range.end) {
      value = read(index);
      destination = binaryLast(value, WikiRange(range.start, index));
      cursor = index;
      while ((cursor > destination)) {
        values[cursor] = read((cursor - 1));
        cursor -= 1;
      }
      values[destination] = value;
    }
  }
  fun blockSwap(first: Int, second: Int, length: Int) {
    var offset = 0
    if (!((length > 0))) {
      return;
    }
    for (offset in 0 until length) {
      swap((first + offset), (second + offset));
    }
  }
  fun rotate(amount: Int, range: WikiRange) {
    var leftLength = 0
    var position = 0
    var rightLength = 0
    var split = 0
    if (!((range.length() > 0))) {
      return;
    }
    split = if (amount >= 0) range.start + amount else range.end + amount;
    if (!(((range.start < split) && (split < range.end)))) {
      return;
    }
    position = range.start;
    leftLength = (split - range.start);
    rightLength = (range.end - split);
    while (((leftLength != 0) && (rightLength != 0))) {
      if ((leftLength <= rightLength)) {
        blockSwap(position, (position + leftLength), leftLength);
        position += leftLength;
        rightLength -= leftLength;
      } else {
        blockSwap(((position + leftLength) - rightLength), (position + leftLength), rightLength);
        leftLength -= rightLength;
      }
    }
  }
  fun mergeInternal(left: WikiRange, right: WikiRange, buffer: WikiRange) {
    var aCount = 0
    var bCount = 0
    var insert = 0
    aCount = 0;
    bCount = 0;
    insert = 0;
    if (((right.length() > 0) && (left.length() > 0))) {
      while (true) {
        if (!(less((right.start + bCount), (buffer.start + aCount)))) {
          swap((left.start + insert), (buffer.start + aCount));
          aCount += 1;
          insert += 1;
          if ((aCount >= left.length())) {
            break;
          }
        } else {
          swap((left.start + insert), (right.start + bCount));
          bCount += 1;
          insert += 1;
          if ((bCount >= right.length())) {
            break;
          }
        }
      }
    }
    blockSwap((buffer.start + aCount), (left.start + insert), (left.length() - aCount));
  }
  fun mergeInPlace(originalLeft: WikiRange, originalRight: WikiRange) {
    var amount = 0
    var left = WikiRange()
    var middle = 0
    var right = WikiRange()
    if (!(((originalLeft.length() > 0) && (originalRight.length() > 0)))) {
      return;
    }
    left = originalLeft;
    right = originalRight;
    while (true) {
      middle = binaryFirst(read(left.start), right);
      amount = (middle - left.end);
      rotate(-(amount), WikiRange(left.start, middle));
      if ((right.end == middle)) {
        break;
      }
      right.start = middle;
      left.set((left.start + amount), right.start);
      left.start = binaryLast(read(left.start), left);
      if ((left.length() == 0)) {
        break;
      }
    }
  }
  fun netSwap(range: WikiRange, order: IntArray, x: Int, y: Int) {
    var a = 0
    var b = 0
    var first = 0
    var isEqual = false
    var isGreater = false
    var second = 0
    first = (range.start + x);
    second = (range.start + y);
    a = read(first);
    b = read(second);
    isGreater = greaterValues(a, b);
    isEqual = (!(isGreater) && !(lessValues(a, b)));
    if ((isGreater || (isEqual && (order[x] > order[y])))) {
      swap(first, second);
      var _sim1_0 = order[y]
      var _sim1_1 = order[x]
      order[x] = _sim1_0;
      order[y] = _sim1_1;
    }
  }
  fun sortSmallRuns(iterator: WikiIterator) {
    var order = IntArray(8)
    var pairs = arrayOf<IntArray>()
    var range = WikiRange()
    while (!(iterator.finished())) {
      order = intArrayOf(0,1,2,3,4,5,6,7);
      range = iterator.nextRange();
      pairs = arrayOf<IntArray>();
      if ((range.length() == 8)) {
        pairs = arrayOf(intArrayOf(0, 1), intArrayOf(2, 3), intArrayOf(4, 5), intArrayOf(6, 7), intArrayOf(0, 2), intArrayOf(1, 3), intArrayOf(4, 6), intArrayOf(5, 7), intArrayOf(1, 2), intArrayOf(5, 6), intArrayOf(0, 4), intArrayOf(3, 7), intArrayOf(1, 5), intArrayOf(2, 6), intArrayOf(1, 4), intArrayOf(3, 6), intArrayOf(2, 4), intArrayOf(3, 5), intArrayOf(3, 4))
      } else {
        if ((range.length() == 7)) {
          pairs = arrayOf(intArrayOf(1, 2), intArrayOf(3, 4), intArrayOf(5, 6), intArrayOf(0, 2), intArrayOf(3, 5), intArrayOf(4, 6), intArrayOf(0, 1), intArrayOf(4, 5), intArrayOf(2, 6), intArrayOf(0, 4), intArrayOf(1, 5), intArrayOf(0, 3), intArrayOf(2, 5), intArrayOf(1, 3), intArrayOf(2, 4), intArrayOf(2, 3))
        } else {
          if ((range.length() == 6)) {
            pairs = arrayOf(intArrayOf(1, 2), intArrayOf(4, 5), intArrayOf(0, 2), intArrayOf(3, 5), intArrayOf(0, 1), intArrayOf(3, 4), intArrayOf(2, 5), intArrayOf(0, 3), intArrayOf(1, 4), intArrayOf(2, 4), intArrayOf(1, 3), intArrayOf(2, 3))
          } else {
            if ((range.length() == 5)) {
              pairs = arrayOf(intArrayOf(0, 1), intArrayOf(3, 4), intArrayOf(2, 4), intArrayOf(2, 3), intArrayOf(1, 4), intArrayOf(0, 3), intArrayOf(0, 2), intArrayOf(1, 3), intArrayOf(1, 2))
            } else {
              if ((range.length() == 4)) {
                pairs = arrayOf(intArrayOf(0, 1), intArrayOf(2, 3), intArrayOf(0, 2), intArrayOf(1, 3), intArrayOf(1, 2))
              } else {
                pairs = arrayOf<IntArray>();
              }
            }
          }
        }
      }
      for (pair in pairs) {
        val x=pair[0]; val y=pair[1];
        netSwap(range, order, x, y);
      }
    }
  }
  fun sort() {
    var amount = 0
    var blockA = WikiRange()
    var blockB = WikiRange()
    var blockSize = 0
    var buffer = WikiRange()
    var buffer1 = WikiRange()
    var buffer2 = WikiRange()
    var bufferSize = 0
    var count = 0
    var find = 0
    var findA = 0
    var findSeparately = false
    var firstA = WikiRange()
    var index = 0
    var indexA = 0
    var iterator = WikiIterator(8)
    var last = 0
    var lastA = WikiRange()
    var lastB = WikiRange()
    var left = WikiRange()
    var length = 0
    var minimum = 0
    var nominalBlock = 0
    var pull = 0
    var pullIndex = 0
    var pulls = arrayOf(WikiPull(),WikiPull())
    var range = WikiRange()
    var remaining = 0
    var right = WikiRange()
    var size = 0
    var split = 0
    var start = 0
    var targetBufferSize = 0
    var unique = 0
    size = values.size;
    if ((size < 4)) {
      insertionSort(WikiRange(0, size));
      return;
    }
    iterator = WikiIterator(size);
    sortSmallRuns(iterator);
    if ((size < 8)) {
      return;
    }
    while (true) {
      nominalBlock = maxOf(1, kotlin.math.sqrt(iterator.length().toDouble()).toInt());
      blockSize = nominalBlock;
      targetBufferSize = ((iterator.length() / blockSize) + 1);
      buffer1 = WikiRange();
      buffer2 = WikiRange();
      pulls = arrayOf(WikiPull(), WikiPull());
      pullIndex = 0;
      find = (targetBufferSize * 2);
      findSeparately = false;
      if ((find > iterator.length())) {
        find = targetBufferSize;
        findSeparately = true;
      }
      iterator.begin();
      while (!(iterator.finished())) {
        left = iterator.nextRange();
        right = iterator.nextRange();
        last = left.start;
        count = 1;
        index = last;
        while ((count < find)) {
          index = findLastForward(read(last), WikiRange((last + 1), left.end), (find - count));
          if ((index == left.end)) {
            break;
          }
          last = index;
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = WikiPull(index, left.start, count, WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = WikiRange(left.start, (left.start + targetBufferSize));
            buffer2 = WikiRange((left.start + targetBufferSize), (left.start + count));
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = WikiRange(left.start, (left.start + count));
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = WikiRange(left.start, (left.start + count));
                findSeparately = false;
              } else {
                buffer2 = WikiRange(left.start, (left.start + count));
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > buffer1.length()))) {
            buffer1 = WikiRange(left.start, (left.start + count));
            pulls[pullIndex] = WikiPull(index, left.start, count, WikiRange(left.start, right.end));
          }
        }
        last = (right.end - 1);
        count = 1;
        while ((count < find)) {
          index = findFirstBackward(read(last), WikiRange(right.start, last), (find - count));
          if ((index == right.start)) {
            break;
          }
          last = (index - 1);
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = WikiPull(index, right.end, count, WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = WikiRange((right.end - count), (right.end - targetBufferSize));
            buffer2 = WikiRange((right.end - targetBufferSize), right.end);
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = WikiRange((right.end - count), right.end);
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = WikiRange((right.end - count), right.end);
                findSeparately = false;
              } else {
                if ((pulls[0].range.start == left.start)) {
                  pulls[0].range.end -= pulls[1].count;
                }
                buffer2 = WikiRange((right.end - count), right.end);
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > buffer1.length()))) {
            buffer1 = WikiRange((right.end - count), right.end);
            pulls[pullIndex] = WikiPull(index, right.end, count, WikiRange(left.start, right.end));
          }
        }
      }
      for (pull in 0 until 2) {
        length = pulls[pull].count;
        if ((pulls[pull].to < pulls[pull].from_)) {
          index = pulls[pull].from_;
          if ((length > 1)) {
            for (count in 1 until length) {
              index = findFirstBackward(read((index - 1)), WikiRange(pulls[pull].to, (pulls[pull].from_ - (count - 1))), (length - count));
              range = WikiRange((index + 1), (pulls[pull].from_ + 1));
              rotate((range.length() - count), range);
              pulls[pull].from_ = (index + count);
            }
          }
        } else {
          if ((pulls[pull].to > pulls[pull].from_)) {
            index = (pulls[pull].from_ + 1);
            if ((length > 1)) {
              for (count in 1 until length) {
                index = findLastForward(read(index), WikiRange(index, pulls[pull].to), (length - count));
                range = WikiRange(pulls[pull].from_, (index - 1));
                rotate(count, range);
                pulls[pull].from_ = ((index - 1) - count);
              }
            }
          }
        }
      }
      bufferSize = buffer1.length();
      blockSize = ((iterator.length() / bufferSize) + 1);
      iterator.begin();
      while (!(iterator.finished())) {
        left = iterator.nextRange();
        right = iterator.nextRange();
        start = left.start;
        for (pullItem in pulls) {
          if ((start != pullItem.range.start)) {
            continue;
          }
          if ((pullItem.from_ > pullItem.to)) {
            left.start += pullItem.count;
          } else {
            if ((pullItem.from_ < pullItem.to)) {
              right.end -= pullItem.count;
            }
          }
        }
        if (((left.length() == 0) || (right.length() == 0))) {
          continue;
        }
        if (less((right.end - 1), left.start)) {
          rotate(left.length(), WikiRange(left.start, right.end));
        } else {
          if (less(left.end, (left.end - 1))) {
            blockA = left.copy();
            firstA = WikiRange(left.start, (left.start + (blockA.length() % blockSize)));
            indexA = buffer1.start;
            index = firstA.end;
            while ((index < blockA.end)) {
              swap(indexA, index);
              indexA += 1;
              index += blockSize;
            }
            lastA = firstA.copy();
            lastB = WikiRange();
            blockB = WikiRange(right.start, (right.start + minOf(blockSize, right.length())));
            blockA.start += firstA.length();
            indexA = buffer1.start;
            if ((buffer2.length() > 0)) {
              blockSwap(lastA.start, buffer2.start, lastA.length());
            }
            if ((blockA.length() > 0)) {
              while (true) {
                if ((((lastB.length() > 0) && !(less((lastB.end - 1), indexA))) || (blockB.length() == 0))) {
                  split = binaryFirst(read(indexA), lastB);
                  remaining = (lastB.end - split);
                  minimum = blockA.start;
                  findA = (minimum + blockSize);
                  while ((findA < blockA.end)) {
                    if (less(findA, minimum)) {
                      minimum = findA;
                    }
                    findA += blockSize;
                  }
                  blockSwap(blockA.start, minimum, blockSize);
                  swap(blockA.start, indexA);
                  indexA += 1;
                  if ((buffer2.length() > 0)) {
                    mergeInternal(lastA, WikiRange(lastA.end, split), buffer2);
                  } else {
                    mergeInPlace(lastA, WikiRange(lastA.end, split));
                  }
                  if ((buffer2.length() > 0)) {
                    blockSwap(blockA.start, buffer2.start, blockSize);
                    blockSwap(split, ((blockA.start + blockSize) - remaining), remaining);
                  } else {
                    rotate((blockA.start - split), WikiRange(split, (blockA.start + blockSize)));
                  }
                  lastA = WikiRange((blockA.start - remaining), ((blockA.start - remaining) + blockSize));
                  lastB = WikiRange(lastA.end, (lastA.end + remaining));
                  blockA.start += blockSize;
                  if ((blockA.length() == 0)) {
                    break;
                  }
                } else {
                  if ((blockB.length() < blockSize)) {
                    rotate(-(blockB.length()), WikiRange(blockA.start, blockB.end));
                    lastB = WikiRange(blockA.start, (blockA.start + blockB.length()));
                    blockA.start += blockB.length();
                    blockA.end += blockB.length();
                    blockB.end = blockB.start;
                  } else {
                    blockSwap(blockA.start, blockB.start, blockSize);
                    lastB = WikiRange(blockA.start, (blockA.start + blockSize));
                    blockA.start += blockSize;
                    blockA.end += blockSize;
                    blockB.start += blockSize;
                    blockB.end = minOf((blockB.end + blockSize), right.end);
                  }
                }
              }
            }
            if ((buffer2.length() > 0)) {
              mergeInternal(lastA, WikiRange(lastA.end, right.end), buffer2);
            } else {
              mergeInPlace(lastA, WikiRange(lastA.end, right.end));
            }
          }
        }
      }
      insertionSort(buffer2);
      for (pullItem in pulls) {
        unique = (pullItem.count * 2);
        if ((pullItem.from_ > pullItem.to)) {
          buffer = WikiRange(pullItem.range.start, (pullItem.range.start + pullItem.count));
          while ((buffer.length() > 0)) {
            index = findFirstForward(read(buffer.start), WikiRange(buffer.end, pullItem.range.end), unique);
            amount = (index - buffer.end);
            rotate(buffer.length(), WikiRange(buffer.start, index));
            buffer.start += (amount + 1);
            buffer.end += amount;
            unique -= 2;
          }
        } else {
          if ((pullItem.from_ < pullItem.to)) {
            buffer = WikiRange((pullItem.range.end - pullItem.count), pullItem.range.end);
            while ((buffer.length() > 0)) {
              index = findLastBackward(read((buffer.end - 1)), WikiRange(pullItem.range.start, buffer.start), unique);
              amount = (buffer.start - index);
              rotate(amount, WikiRange(index, buffer.end));
              buffer.start -= amount;
              buffer.end -= (amount + 1);
              unique -= 2;
            }
          }
        }
      }
      if (!(iterator.nextLevel())) {
        break;
      }
    }
  }
}

fun wikiSort(values: IntArray) { WikiSortExample(values).sort() }
fun main(){val values=intArrayOf(0,39,21,62,91,77,14,23,90,69,51,81,68,83,32,56);wikiSort(values);println(values.joinToString(prefix="[",postfix="]"))}
