"""Unary tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def pow(a: Tensor, power: int | float) -> Tensor:
    """Raise a tensor to a scalar power.

    Args:
        a (Tensor): Input tensor.
        power (int | float): Exponent value.

    Returns:
        Tensor: Result of ``a ** power``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.data**power, a.requires_grad, a._backend, (a,), f"**{power}")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += (power * a.data ** (power - 1)) * out.grad

    out._backward = _backward
    return out


def rpow(a: Tensor, base: int | float) -> Tensor:
    """A scalar base to a tensor power.

    Args:
        a (Tensor): Exponent tensor.
        base (int | float): Scalar base.

    Returns:
        Tensor: Result of ``base ** a``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(base**a.data, a.requires_grad, a._backend, (a,), f"{base}**")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += (base**a.data * a.xp.log(base)) * out.grad

    out._backward = _backward
    return out


def exp(a: Tensor) -> Tensor:
    """Compute the exponential of a tensor.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``exp(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.exp(a.data), a.requires_grad, a._backend, (a,), "exp")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += a.xp.exp(a.data) * out.grad

    out._backward = _backward
    return out


def log(a: Tensor) -> Tensor:
    """Compute the natural logarithm of a tensor.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``log(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.log(a.data), a.requires_grad, a._backend, (a,), "log")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += out.grad / a.data

    out._backward = _backward
    return out


def log1p(a: Tensor) -> Tensor:
    """Compute ``log(1 + a)`` elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``log1p(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.log1p(a.data), a.requires_grad, a._backend, (a,), "log1p")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += out.grad / (1 + a.data)

    out._backward = _backward
    return out


def abs(a: Tensor) -> Tensor:
    """Compute the absolute value elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Absolute value of the input tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.abs(a.data), a.requires_grad, a._backend, (a,), "abs")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        grad = a.xp.sign(a.data)
        grad = a.xp.where(a.data == 0, 0.0, grad)
        a.grad += grad * out.grad

    out._backward = _backward
    return out


def transpose(a: Tensor) -> Tensor:
    """Transpose a tensor.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Transposed tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.data.T, a.requires_grad, a._backend, (a,), ".T")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += out.grad.T

    out._backward = _backward
    return out


def reshape(a: Tensor, shape: int | tuple[int, ...]) -> Tensor:
    """Reshape a tensor.

    Args:
        a (Tensor): Input tensor.
        shape (int | tuple[int, ...]): Target shape.

    Returns:
        Tensor: Reshaped tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        a.xp.reshape(a.data, shape),
        a.requires_grad,
        a._backend,
        (a,),
        f"reshape({shape=})",
    )

    input_shape = a.data.shape

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += a.xp.reshape(out.grad, input_shape)

    out._backward = _backward
    return out


def flatten(a: Tensor) -> Tensor:
    """Flatten a tensor to one dimension.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Flattened tensor.
    """
    return reshape(a, (-1,))
