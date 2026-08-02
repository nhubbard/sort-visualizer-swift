class Node {
  constructor(key) {
    this.key = key;
    this.left = null;
    this.right = null;
  }
}

function leftRotate(x) {
  var y = x.right;
  x.right = y.left;
  y.left = x;
  return y;
}

function rightRotate(x) {
  var y = x.left;
  x.left = y.right;
  y.right = x;
  return y;
}

function splay(root, key) {
  if (root === null) {
    return root;
  }
  if (root.key > key) {
    if (root.left === null) {
      return root;
    }
    if (root.left.key > key) {
      root.left.left = splay(root.left.left, key);
      root = rightRotate(root);
    } else {
      root.left.right = splay(root.left.right, key);
      if (root.left.right !== null) {
        root.left = leftRotate(root.left);
      }
    }
    return root.left === null ? root : rightRotate(root);
  } else {
    if (root.right === null) {
      return root;
    }
    if (root.right.key > key) {
      root.right.left = splay(root.right.left, key);
      if (root.right.left !== null) {
        root.right = rightRotate(root.right);
      }
    } else {
      root.right.right = splay(root.right.right, key);
      root = leftRotate(root);
    }
    return root.right === null ? root : leftRotate(root);
  }
}

function insertRec(root, key) {
  if (root === null) {
    return new Node(key);
  }
  root = splay(root, key);
  var n = new Node(key);
  if (root.key > key) {
    n.right = root;
    n.left = root.left;
    root.left = null;
  } else {
    n.left = root;
    n.right = root.right;
    root.right = null;
  }
  return n;
}

function sort(arr) {
  var root = null;
  for (var i = 0; i < arr.length; i++) {
    root = insertRec(root, arr[i]);
  }
  var result = [];
  function traverse(node) {
    if (node !== null) {
      traverse(node.left);
      result.push(node.key);
      traverse(node.right);
    }
  }
  traverse(root);
  for (var j = 0; j < arr.length; j++) {
    arr[j] = result[j];
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
