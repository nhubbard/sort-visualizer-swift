// The WikiSorting source is released to the public domain under the Unlicense.

import java.util.Arrays;

class WikiRange {
  int start,end;
  WikiRange(){this(0,0);}
  WikiRange(int start,int end){this.start=start;this.end=end;}
  int length(){return end-start;}
  void set(int first,int last){start=first;end=last;}
  WikiRange copy(){return new WikiRange(start,end);}
}
class WikiPull {
  int from_,to,count; WikiRange range;
  WikiPull(){this(0,0,0,new WikiRange());}
  WikiPull(int from_,int to,int count,WikiRange range){this.from_=from_;this.to=to;this.count=count;this.range=range;}
}
class WikiIterator {
  int size,denominator,numeratorStep,decimalStep,numerator,decimal;
  WikiIterator(int size){this.size=size;int power=1;while(power*2<=size)power*=2;denominator=power/4;numeratorStep=size%denominator;decimalStep=size/denominator;}
  void begin(){numerator=0;decimal=0;}
  WikiRange nextRange(){int start=decimal;decimal+=decimalStep;numerator+=numeratorStep;if(numerator>=denominator){numerator-=denominator;decimal++;}return new WikiRange(start,decimal);}
  boolean finished(){return decimal>=size;}
  boolean nextLevel(){decimalStep*=2;numeratorStep*=2;if(numeratorStep>=denominator){numeratorStep-=denominator;decimalStep++;}return decimalStep<size;}
  int length(){return decimalStep;}
}
class WikiSortExample {
  private final int[] values;
  WikiSortExample(int[] input) {
    values = input;
  }
  int read(int index) {
    return values[index];
  }
  boolean less(int left, int right) {
    return (values[left] < values[right]);
  }
  boolean lessValues(int left, int right) {
    return (left < right);
  }
  boolean greaterValues(int left, int right) {
    return (left > right);
  }
  void swap(int left, int right) {
    int _sim0_0 = values[right];
    int _sim0_1 = values[left];
    values[left] = _sim0_0;
    values[right] = _sim0_1;
  }
  int binaryFirst(int value, WikiRange range) {
    int end;
    int middle;
    int start;
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
  int binaryLast(int value, WikiRange range) {
    int end;
    int middle;
    int start;
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
  int findFirstForward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = Math.max((range.length() / Math.max(unique, 1)), 1);
    index = (range.start + skip);
    while ((values[(index - 1)] < value)) {
      if ((index >= (range.end - skip))) {
        return binaryFirst(value, new WikiRange(index, range.end));
      }
      index += skip;
    }
    return binaryFirst(value, new WikiRange((index - skip), index));
  }
  int findLastForward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = Math.max((range.length() / Math.max(unique, 1)), 1);
    index = (range.start + skip);
    while ((values[(index - 1)] <= value)) {
      if ((index >= (range.end - skip))) {
        return binaryLast(value, new WikiRange(index, range.end));
      }
      index += skip;
    }
    return binaryLast(value, new WikiRange((index - skip), index));
  }
  int findFirstBackward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = Math.max((range.length() / Math.max(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (values[(index - 1)] >= value))) {
      if ((index < (range.start + skip))) {
        return binaryFirst(value, new WikiRange(range.start, index));
      }
      index -= skip;
    }
    return binaryFirst(value, new WikiRange(index, (index + skip)));
  }
  int findLastBackward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = Math.max((range.length() / Math.max(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (values[(index - 1)] > value))) {
      if ((index < (range.start + skip))) {
        return binaryLast(value, new WikiRange(range.start, index));
      }
      index -= skip;
    }
    return binaryLast(value, new WikiRange(index, (index + skip)));
  }
  void insertionSort(WikiRange range) {
    int cursor;
    int destination;
    int index;
    int value;
    if (!((range.length() > 1))) {
      return;
    }
    for (index = (range.start + 1); index < range.end; index++) {
      value = read(index);
      destination = binaryLast(value, new WikiRange(range.start, index));
      cursor = index;
      while ((cursor > destination)) {
        values[cursor] = read((cursor - 1));
        cursor -= 1;
      }
      values[destination] = value;
    }
  }
  void blockSwap(int first, int second, int length) {
    int offset;
    if (!((length > 0))) {
      return;
    }
    for (offset = 0; offset < length; offset++) {
      swap((first + offset), (second + offset));
    }
  }
  void rotate(int amount, WikiRange range) {
    int leftLength;
    int position;
    int rightLength;
    int split;
    if (!((range.length() > 0))) {
      return;
    }
    split = ((amount >= 0) ? (range.start + amount) : (range.end + amount));
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
  void mergeInternal(WikiRange left, WikiRange right, WikiRange buffer) {
    int aCount;
    int bCount;
    int insert;
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
  void mergeInPlace(WikiRange originalLeft, WikiRange originalRight) {
    int amount;
    WikiRange left;
    int middle;
    WikiRange right;
    if (!(((originalLeft.length() > 0) && (originalRight.length() > 0)))) {
      return;
    }
    left = originalLeft;
    right = originalRight;
    while (true) {
      middle = binaryFirst(read(left.start), right);
      amount = (middle - left.end);
      rotate(-(amount), new WikiRange(left.start, middle));
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
  void netSwap(WikiRange range, int[] order, int x, int y) {
    int a;
    int b;
    int first;
    boolean isEqual;
    boolean isGreater;
    int second;
    first = (range.start + x);
    second = (range.start + y);
    a = read(first);
    b = read(second);
    isGreater = greaterValues(a, b);
    isEqual = (!(isGreater) && !(lessValues(a, b)));
    if ((isGreater || (isEqual && (order[x] > order[y])))) {
      swap(first, second);
      int _sim1_0 = order[y];
      int _sim1_1 = order[x];
      order[x] = _sim1_0;
      order[y] = _sim1_1;
    }
  }
  void sortSmallRuns(WikiIterator iterator) {
    int[] order;
    int[][] pairs;
    WikiRange range;
    while (!(iterator.finished())) {
      order = new int[]{0,1,2,3,4,5,6,7};
      range = iterator.nextRange();
      pairs = new int[0][0];
      if ((range.length() == 8)) {
        pairs = new int[][]{{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3}, {4, 6}, {5, 7}, {1, 2}, {5, 6}, {0, 4}, {3, 7}, {1, 5}, {2, 6}, {1, 4}, {3, 6}, {2, 4}, {3, 5}, {3, 4}};
      } else {
        if ((range.length() == 7)) {
          pairs = new int[][]{{1, 2}, {3, 4}, {5, 6}, {0, 2}, {3, 5}, {4, 6}, {0, 1}, {4, 5}, {2, 6}, {0, 4}, {1, 5}, {0, 3}, {2, 5}, {1, 3}, {2, 4}, {2, 3}};
        } else {
          if ((range.length() == 6)) {
            pairs = new int[][]{{1, 2}, {4, 5}, {0, 2}, {3, 5}, {0, 1}, {3, 4}, {2, 5}, {0, 3}, {1, 4}, {2, 4}, {1, 3}, {2, 3}};
          } else {
            if ((range.length() == 5)) {
              pairs = new int[][]{{0, 1}, {3, 4}, {2, 4}, {2, 3}, {1, 4}, {0, 3}, {0, 2}, {1, 3}, {1, 2}};
            } else {
              if ((range.length() == 4)) {
                pairs = new int[][]{{0, 1}, {2, 3}, {0, 2}, {1, 3}, {1, 2}};
              } else {
                pairs = new int[0][0];
              }
            }
          }
        }
      }
      for (int[] pair : pairs) {
        int x=pair[0], y=pair[1];
        netSwap(range, order, x, y);
      }
    }
  }
  void sort() {
    int amount;
    WikiRange blockA;
    WikiRange blockB;
    int blockSize;
    WikiRange buffer;
    WikiRange buffer1;
    WikiRange buffer2;
    int bufferSize;
    int count;
    int find;
    int findA;
    boolean findSeparately;
    WikiRange firstA;
    int index;
    int indexA;
    WikiIterator iterator;
    int last;
    WikiRange lastA;
    WikiRange lastB;
    WikiRange left;
    int length;
    int minimum;
    int nominalBlock;
    int pull;
    int pullIndex;
    WikiPull[] pulls;
    WikiRange range;
    int remaining;
    WikiRange right;
    int size;
    int split;
    int start;
    int targetBufferSize;
    int unique;
    size = values.length;
    if ((size < 4)) {
      insertionSort(new WikiRange(0, size));
      return;
    }
    iterator = new WikiIterator(size);
    sortSmallRuns(iterator);
    if ((size < 8)) {
      return;
    }
    while (true) {
      nominalBlock = Math.max(1, (int)(Math.sqrt(iterator.length())));
      blockSize = nominalBlock;
      targetBufferSize = ((iterator.length() / blockSize) + 1);
      buffer1 = new WikiRange();
      buffer2 = new WikiRange();
      pulls = new WikiPull[]{new WikiPull(), new WikiPull()};
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
          index = findLastForward(read(last), new WikiRange((last + 1), left.end), (find - count));
          if ((index == left.end)) {
            break;
          }
          last = index;
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = new WikiPull(index, left.start, count, new WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = new WikiRange(left.start, (left.start + targetBufferSize));
            buffer2 = new WikiRange((left.start + targetBufferSize), (left.start + count));
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = new WikiRange(left.start, (left.start + count));
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = new WikiRange(left.start, (left.start + count));
                findSeparately = false;
              } else {
                buffer2 = new WikiRange(left.start, (left.start + count));
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > buffer1.length()))) {
            buffer1 = new WikiRange(left.start, (left.start + count));
            pulls[pullIndex] = new WikiPull(index, left.start, count, new WikiRange(left.start, right.end));
          }
        }
        last = (right.end - 1);
        count = 1;
        while ((count < find)) {
          index = findFirstBackward(read(last), new WikiRange(right.start, last), (find - count));
          if ((index == right.start)) {
            break;
          }
          last = (index - 1);
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = new WikiPull(index, right.end, count, new WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = new WikiRange((right.end - count), (right.end - targetBufferSize));
            buffer2 = new WikiRange((right.end - targetBufferSize), right.end);
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = new WikiRange((right.end - count), right.end);
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = new WikiRange((right.end - count), right.end);
                findSeparately = false;
              } else {
                if ((pulls[0].range.start == left.start)) {
                  pulls[0].range.end -= pulls[1].count;
                }
                buffer2 = new WikiRange((right.end - count), right.end);
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > buffer1.length()))) {
            buffer1 = new WikiRange((right.end - count), right.end);
            pulls[pullIndex] = new WikiPull(index, right.end, count, new WikiRange(left.start, right.end));
          }
        }
      }
      for (pull = 0; pull < 2; pull++) {
        length = pulls[pull].count;
        if ((pulls[pull].to < pulls[pull].from_)) {
          index = pulls[pull].from_;
          if ((length > 1)) {
            for (count = 1; count < length; count++) {
              index = findFirstBackward(read((index - 1)), new WikiRange(pulls[pull].to, (pulls[pull].from_ - (count - 1))), (length - count));
              range = new WikiRange((index + 1), (pulls[pull].from_ + 1));
              rotate((range.length() - count), range);
              pulls[pull].from_ = (index + count);
            }
          }
        } else {
          if ((pulls[pull].to > pulls[pull].from_)) {
            index = (pulls[pull].from_ + 1);
            if ((length > 1)) {
              for (count = 1; count < length; count++) {
                index = findLastForward(read(index), new WikiRange(index, pulls[pull].to), (length - count));
                range = new WikiRange(pulls[pull].from_, (index - 1));
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
        for (WikiPull pullItem : pulls) {
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
          rotate(left.length(), new WikiRange(left.start, right.end));
        } else {
          if (less(left.end, (left.end - 1))) {
            blockA = left.copy();
            firstA = new WikiRange(left.start, (left.start + (blockA.length() % blockSize)));
            indexA = buffer1.start;
            index = firstA.end;
            while ((index < blockA.end)) {
              swap(indexA, index);
              indexA += 1;
              index += blockSize;
            }
            lastA = firstA.copy();
            lastB = new WikiRange();
            blockB = new WikiRange(right.start, (right.start + Math.min(blockSize, right.length())));
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
                    mergeInternal(lastA, new WikiRange(lastA.end, split), buffer2);
                  } else {
                    mergeInPlace(lastA, new WikiRange(lastA.end, split));
                  }
                  if ((buffer2.length() > 0)) {
                    blockSwap(blockA.start, buffer2.start, blockSize);
                    blockSwap(split, ((blockA.start + blockSize) - remaining), remaining);
                  } else {
                    rotate((blockA.start - split), new WikiRange(split, (blockA.start + blockSize)));
                  }
                  lastA = new WikiRange((blockA.start - remaining), ((blockA.start - remaining) + blockSize));
                  lastB = new WikiRange(lastA.end, (lastA.end + remaining));
                  blockA.start += blockSize;
                  if ((blockA.length() == 0)) {
                    break;
                  }
                } else {
                  if ((blockB.length() < blockSize)) {
                    rotate(-(blockB.length()), new WikiRange(blockA.start, blockB.end));
                    lastB = new WikiRange(blockA.start, (blockA.start + blockB.length()));
                    blockA.start += blockB.length();
                    blockA.end += blockB.length();
                    blockB.end = blockB.start;
                  } else {
                    blockSwap(blockA.start, blockB.start, blockSize);
                    lastB = new WikiRange(blockA.start, (blockA.start + blockSize));
                    blockA.start += blockSize;
                    blockA.end += blockSize;
                    blockB.start += blockSize;
                    blockB.end = Math.min((blockB.end + blockSize), right.end);
                  }
                }
              }
            }
            if ((buffer2.length() > 0)) {
              mergeInternal(lastA, new WikiRange(lastA.end, right.end), buffer2);
            } else {
              mergeInPlace(lastA, new WikiRange(lastA.end, right.end));
            }
          }
        }
      }
      insertionSort(buffer2);
      for (WikiPull pullItem : pulls) {
        unique = (pullItem.count * 2);
        if ((pullItem.from_ > pullItem.to)) {
          buffer = new WikiRange(pullItem.range.start, (pullItem.range.start + pullItem.count));
          while ((buffer.length() > 0)) {
            index = findFirstForward(read(buffer.start), new WikiRange(buffer.end, pullItem.range.end), unique);
            amount = (index - buffer.end);
            rotate(buffer.length(), new WikiRange(buffer.start, index));
            buffer.start += (amount + 1);
            buffer.end += amount;
            unique -= 2;
          }
        } else {
          if ((pullItem.from_ < pullItem.to)) {
            buffer = new WikiRange((pullItem.range.end - pullItem.count), pullItem.range.end);
            while ((buffer.length() > 0)) {
              index = findLastBackward(read((buffer.end - 1)), new WikiRange(pullItem.range.start, buffer.start), unique);
              amount = (buffer.start - index);
              rotate(amount, new WikiRange(index, buffer.end));
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

public class wikisort {
  public static void sort(int[] values){new WikiSortExample(values).sort();}
  public static void main(String[] args){int[] values={0,39,21,62,91,77,14,23,90,69,51,81,68,83,32,56};sort(values);System.out.println(Arrays.toString(values));}
}
