from tensor_forge.tensor.tensor import Tensor


def main() -> None:
    """Run a simple example of tensor operations."""
    print("=== Проверка matmul: 1D @ 1D ===")
    a = Tensor([1.0, 2.0, 3.0], requires_grad=True)
    b = Tensor([4.0, 5.0, 6.0], requires_grad=True)
    y = a @ b
    y.backward()

    print("y.data =", y.data)  # ожидается 32.0
    print("a.grad =", a.grad)  # ожидается [4. 5. 6.]
    print("b.grad =", b.grad)  # ожидается [1. 2. 3.]
    print()

    print("=== Проверка matmul: 2D @ 1D ===")
    a = Tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]], requires_grad=True)
    b = Tensor([10.0, 20.0, 30.0], requires_grad=True)
    y = a @ b
    y.backward([1.0, 1.0])

    print("y.data =", y.data)  # ожидается [140. 320.]
    print("a.grad =\n", a.grad)  # ожидается [[10. 20. 30.]
    #            [10. 20. 30.]]
    print("b.grad =", b.grad)  # ожидается [5. 7. 9.]
    print()

    print("=== Проверка matmul: 1D @ 2D ===")
    a = Tensor([1.0, 2.0], requires_grad=True)
    b = Tensor([[10.0, 20.0, 30.0], [40.0, 50.0, 60.0]], requires_grad=True)
    y = a @ b
    y.backward([1.0, 1.0, 1.0])

    print("y.data =", y.data)  # ожидается [ 90. 120. 150.]
    print("a.grad =", a.grad)  # ожидается [60. 150.]
    print("b.grad =\n", b.grad)  # ожидается [[1. 1. 1.]
    #            [2. 2. 2.]]
    print()

    print("=== Проверка matmul: 2D @ 2D ===")
    a = Tensor([[1.0, 2.0], [3.0, 4.0]], requires_grad=True)
    b = Tensor([[5.0, 6.0], [7.0, 8.0]], requires_grad=True)
    y = a @ b
    y.backward([[1.0, 1.0], [1.0, 1.0]])

    print("y.data =\n", y.data)  # ожидается [[19. 22.]
    #            [43. 50.]]
    print("a.grad =\n", a.grad)  # ожидается [[11. 15.]
    #            [11. 15.]]
    print("b.grad =\n", b.grad)  # ожидается [[4. 4.]
    #            [6. 6.]]
    print()


if __name__ == "__main__":
    main()
