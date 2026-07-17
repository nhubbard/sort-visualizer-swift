import java.util.Arrays;

public class doubleselectionsort {
  private static void doubleSelectionSort(int arr[]) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }

    int left = 0;
    int right = n - 1;
    int smallest = 0;
    int biggest = 0;

    while (left <= right) {
      for (int i = left; i <= right; i++) {
        if (arr[i] > arr[biggest]) {
          biggest = i;
        }
        if (arr[i] < arr[smallest]) {
          smallest = i;
        }
      }

      if (biggest == left) {
        biggest = smallest;
      }

      int temp = arr[left];
      arr[left] = arr[smallest];
      arr[smallest] = temp;

      temp = arr[right];
      arr[right] = arr[biggest];
      arr[biggest] = temp;

      left++;
      right--;
      smallest = left;
      biggest = right;
    }
  }

  public static void sort(int arr[]) {
    doubleSelectionSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
