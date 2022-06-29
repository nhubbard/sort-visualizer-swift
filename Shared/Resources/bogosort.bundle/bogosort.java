import java.util.Arrays;

public class bogosort {
  public static boolean isSorted(int[] arr) {
    for (int i = 1; i < arr.length; i++) {
      if (arr[i - 1] > arr[i]) {
        return false;
      }
    }
    return true;
  }
  
  public static void shuffle(int[] arr) {
    int n = arr.length;
    for (int i = 0; i < n; i++) {
      int a = (int)(Math.random() * n);
      int b = (int)(Math.random() * n);
      int t = arr[a];
      arr[a] = arr[b];
      arr[b] = t;
    }
  }
  
  public static void sort(int[] arr) {
    while (!isSorted(arr)) {
      shuffle(arr);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
