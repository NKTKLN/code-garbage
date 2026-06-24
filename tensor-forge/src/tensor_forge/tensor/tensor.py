"""Tensor object with autodiff support and backend switching."""

from __future__ import annotations

from collections.abc import Callable

from numpy.typing import ArrayLike

from tensor_forge.errors import (
    CuPyNotInstalledError,
    ShapeMismatchError,
    UnsupportedBackendError,
)

from .backends import Array, Backend, DType, get_backend, get_dtype


class Tensor:
    """Tensor with gradient tracking and basic differentiable operations."""

    def __init__(
        self,
        data: ArrayLike,
        requires_grad: bool = False,
        backend_title: str = "numpy",
        _children: tuple[Tensor, ...] | set[Tensor] = (),
        _op: str = "",
        dtype: DType = DType.float32,
    ) -> None:
        """Initialize a tensor.

        Args:
            data (ArrayLike): Input data.
            requires_grad (bool): Whether to track gradients.
            backend_title (str): Backend name.
            _children (tuple[Tensor, ...] | set[Tensor]): Parent tensors.
            _op (str): Operation name that created the tensor.
            dtype (DType): Data type for tensor.
        """
        self.requires_grad = requires_grad

        self._prev = set(_children)
        self._op = _op
        self._backward: Callable[[], None] = lambda: None

        self.xp: Backend = get_backend(backend_title)
        self._backend = backend_title
        self._dtype = get_dtype(self.xp, dtype)

        self.data: Array = self.xp.array(data, dtype=self._dtype)
        self.grad: Array = self.xp.zeros_like(self.data, dtype=self._dtype)

        self.change_backend(backend_title)

    def change_backend(self, title: str = "numpy") -> None:
        """Change tensor backend.

        Args:
            title (str): Target backend name.

        Raises:
            RuntimeError: If CuPy backend is requested but not installed.
        """
        if title not in ["numpy", "cupy"]:
            raise UnsupportedBackendError(title)

        if title == "numpy" and self._backend != "numpy":
            self.data = self.data.get()
            self.grad = self.grad.get()

        if title == "cupy" and self._backend != "cupy":
            try:
                import cupy as cp  # type: ignore
            except ImportError as e:
                raise CuPyNotInstalledError("backend") from e

            self.data = cp.asarray(self.data)
            self.grad = cp.asarray(self.grad)

        self.xp = get_backend(title)
        self._backend = title

        for child in self._prev:
            child.change_backend(title)

    def zero_grad(self) -> None:
        """Reset gradient to zeros."""
        self.grad = self.xp.zeros_like(self.data, dtype=self._dtype)

    def backward(self, grad: ArrayLike | None = None) -> None:
        """Run backpropagation from this tensor.

        Args:
            grad (ArrayLike | None): Initial gradient. If ``None``, uses ones.

        Raises:
            ValueError: If gradient shape does not match tensor shape.
        """
        self.change_backend(self._backend)

        topological_order = []
        visited_tensors = set()

        def build_order(value: Tensor) -> None:
            """Build topological order for backpropagation.

            Args:
                value (Tensor): Current tensor.
            """
            if value in visited_tensors:
                return

            visited_tensors.add(value)

            for child in value._prev:
                build_order(child)

            topological_order.append(value)

        build_order(self)

        if grad is None:
            self.grad = self.xp.ones_like(self.data, dtype=self._dtype)
        else:
            grad = self.xp.array(grad, dtype=self._dtype)

            if self.data.shape != grad.shape:
                raise ShapeMismatchError(grad.shape, self.data.shape)

            self.grad = grad

        for tensor in reversed(topological_order):
            tensor._backward()

    def __repr__(self) -> str:
        """Return string representation of the tensor.

        Returns:
            str: Tensor representation.
        """
        return f"Tensor(data={self.data}, grad={self.grad})"

    def __add__(self, other: Tensor | ArrayLike) -> Tensor:
        """Add another tensor or array-like value.

        Args:
            other (Tensor | ArrayLike): Right operand.

        Returns:
            Tensor: Addition result.
        """
        from .ops import add

        return add(self, other)

    def __radd__(self, other: Tensor | ArrayLike) -> Tensor:
        """Add tensor to another value with reversed operands.

        Args:
            other (Tensor | ArrayLike): Left operand.

        Returns:
            Tensor: Addition result.
        """
        return self + other

    def __mul__(self, other: Tensor | ArrayLike) -> Tensor:
        """Multiply by another tensor or array-like value.

        Args:
            other (Tensor | ArrayLike): Right operand.

        Returns:
            Tensor: Multiplication result.
        """
        from .ops import mul

        return mul(self, other)

    def __rmul__(self, other: Tensor | ArrayLike) -> Tensor:
        """Multiply tensor by another value with reversed operands.

        Args:
            other (Tensor | ArrayLike): Left operand.

        Returns:
            Tensor: Multiplication result.
        """
        return self * other

    def __pow__(self, power: int | float) -> Tensor:
        """Raise tensor to a scalar power.

        Args:
            power (int | float): Exponent.

        Returns:
            Tensor: Power result.
        """
        from .ops import pow

        return pow(self, power)

    def __rpow__(self, base: int | float) -> Tensor:
        """Raise scalar base to tensor power.

        Args:
            base (int | float): Base value.

        Returns:
            Tensor: Power result.
        """
        from .ops import rpow

        return rpow(base, self)

    def __neg__(self) -> Tensor:
        """Negate the tensor.

        Returns:
            Tensor: Negated tensor.
        """
        return self * -1

    def __sub__(self, other: Tensor | ArrayLike) -> Tensor:
        """Subtract another tensor or array-like value.

        Args:
            other (Tensor | ArrayLike): Right operand.

        Returns:
            Tensor: Subtraction result.
        """
        return self + (-other)

    def __rsub__(self, other: Tensor | ArrayLike) -> Tensor:
        """Subtract tensor from another value.

        Args:
            other (Tensor | ArrayLike): Left operand.

        Returns:
            Tensor: Subtraction result.
        """
        return other + (-self)

    def __truediv__(self, other: Tensor | ArrayLike) -> Tensor:
        """Divide by another tensor or array-like value.

        Args:
            other (Tensor | ArrayLike): Right operand.

        Returns:
            Tensor: Division result.
        """
        return self * (other**-1)

    def __rtruediv__(self, other: Tensor | ArrayLike) -> Tensor:
        """Divide another value by this tensor.

        Args:
            other (Tensor | ArrayLike): Left operand.

        Returns:
            Tensor: Division result.
        """
        return other * (self**-1)

    @property
    def T(self) -> Tensor:
        """Transpose the tensor.

        Returns:
            Tensor: Transposed tensor.
        """
        from .ops import transpose

        return transpose(self)

    def exp(self) -> Tensor:
        """Apply exponential elementwise.

        Returns:
            Tensor: Exponential result.
        """
        from .ops import exp

        return exp(self)

    def log(self) -> Tensor:
        """Apply natural logarithm elementwise.

        Returns:
            Tensor: Logarithm result.
        """
        from .ops import log

        return log(self)

    def log1p(self) -> Tensor:
        """Apply ``log(1 + x)`` elementwise.

        Returns:
            Tensor: Logarithm result.
        """
        from .ops import log1p

        return log1p(self)

    def sin(self) -> Tensor:
        """Apply sine elementwise.

        Returns:
            Tensor: Sine result.
        """
        from .ops import sin

        return sin(self)

    def cos(self) -> Tensor:
        """Apply cosine elementwise.

        Returns:
            Tensor: Cosine result.
        """
        from .ops import cos

        return cos(self)

    def tan(self) -> Tensor:
        """Apply tangent elementwise.

        Returns:
            Tensor: Tangent result.
        """
        from .ops import tan

        return tan(self)

    def sinh(self) -> Tensor:
        """Apply hyperbolic sine elementwise.

        Returns:
            Tensor: Hyperbolic sine result.
        """
        from .ops import sinh

        return sinh(self)

    def cosh(self) -> Tensor:
        """Apply hyperbolic cosine elementwise.

        Returns:
            Tensor: Hyperbolic cosine result.
        """
        from .ops import cosh

        return cosh(self)

    def tanh(self) -> Tensor:
        """Apply hyperbolic tangent elementwise.

        Returns:
            Tensor: Hyperbolic tangent result.
        """
        from .ops import tanh

        return tanh(self)

    def arcsin(self) -> Tensor:
        """Apply inverse sine elementwise.

        Returns:
            Tensor: Inverse sine result.
        """
        from .ops import arcsin

        return arcsin(self)

    def arccos(self) -> Tensor:
        """Apply inverse cosine elementwise.

        Returns:
            Tensor: Inverse cosine result.
        """
        from .ops import arccos

        return arccos(self)

    def arctan(self) -> Tensor:
        """Apply inverse tangent elementwise.

        Returns:
            Tensor: Inverse tangent result.
        """
        from .ops import arctan

        return arctan(self)

    def abs(self) -> Tensor:
        """Apply absolute value elementwise.

        Returns:
            Tensor: Absolute value result.
        """
        from .ops import abs

        return abs(self)

    def sum(
        self,
        axis: int | tuple[int, ...] | None = None,
        keepdims: bool = False,
    ) -> Tensor:
        """Sum tensor elements over given axes.

        Args:
            axis (int | tuple[int, ...] | None): Reduction axis or axes.
            keepdims (bool): Whether to keep reduced dimensions.

        Returns:
            Tensor: Reduced tensor.
        """
        from .ops import sum

        return sum(self, axis, keepdims)

    def mean(
        self,
        axis: int | tuple[int, ...] | None = None,
        keepdims: bool = False,
    ) -> Tensor:
        """Compute mean over given axes.

        Args:
            axis (int | tuple[int, ...] | None): Reduction axis or axes.
            keepdims (bool): Whether to keep reduced dimensions.

        Returns:
            Tensor: Reduced tensor.
        """
        from .ops import mean

        return mean(self, axis, keepdims)

    def max(
        self,
        axis: int | tuple[int, ...] | None = None,
        keepdims: bool = False,
    ) -> Tensor:
        """Compute maximum over given axes.

        Args:
            axis (int | tuple[int, ...] | None): Reduction axis or axes.
            keepdims (bool): Whether to keep reduced dimensions.

        Returns:
            Tensor: Reduced tensor.
        """
        from .ops import max

        return max(self, axis, keepdims)

    def min(
        self,
        axis: int | tuple[int, ...] | None = None,
        keepdims: bool = False,
    ) -> Tensor:
        """Compute minimum over given axes.

        Args:
            axis (int | tuple[int, ...] | None): Reduction axis or axes.
            keepdims (bool): Whether to keep reduced dimensions.

        Returns:
            Tensor: Reduced tensor.
        """
        from .ops import min

        return min(self, axis, keepdims)

    def reshape(self, axis: int | tuple[int, ...]) -> Tensor:
        """Reshape the tensor.

        Args:
            axis (int | tuple[int, ...]): Target shape.

        Returns:
            Tensor: Reshaped tensor.
        """
        from .ops import reshape

        return reshape(self, axis)

    def flatten(self) -> Tensor:
        """Flatten the tensor to one dimension.

        Returns:
            Tensor: Flattened tensor.
        """
        from .ops import flatten

        return flatten(self)

    def __matmul__(self, other: Tensor | ArrayLike) -> Tensor:
        """Apply matrix multiplication.

        Args:
            other (Tensor | ArrayLike): Right operand.

        Returns:
            Tensor: Matrix multiplication result.
        """
        from .ops import matmul

        return matmul(self, other)

    def sigmoid(self) -> Tensor:
        """Apply sigmoid activation.

        Returns:
            Tensor: Sigmoid output.
        """
        from .ops import sigmoid

        return sigmoid(self)

    def relu(self) -> Tensor:
        """Apply ReLU activation.

        Returns:
            Tensor: ReLU output.
        """
        from .ops import relu

        return relu(self)

    def leaky_relu(self, alpha: float = 0.01) -> Tensor:
        """Apply Leaky ReLU activation.

        Args:
            alpha (float): Negative slope.

        Returns:
            Tensor: Leaky ReLU output.
        """
        from .ops import leaky_relu

        return leaky_relu(self, alpha)

    def softplus(self) -> Tensor:
        """Apply softplus activation.

        Returns:
            Tensor: Softplus output.
        """
        from .ops import softplus

        return softplus(self)

    def softmax(self, dim: int | tuple[int, ...] = -1) -> Tensor:
        """Apply softmax over a given dimension.

        Args:
            dim (int | tuple[int, ...]): Dimension or dimensions to normalize over.

        Returns:
            Tensor: Softmax output.
        """
        from .ops import softmax

        return softmax(self, dim)
