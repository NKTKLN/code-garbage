"""Activation functions for neural network style tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

from .reductions import max, sum
from .unary import exp, log1p

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def sigmoid(a: Tensor) -> Tensor:
    """Apply the sigmoid activation elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Sigmoid output.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        1.0 / (1.0 + a.xp.exp(-a.data)),
        a.requires_grad,
        a._backend,
        (a,),
        "sigmoid",
    )

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += out.data * (1.0 - out.data) * out.grad

    out._backward = _backward
    return out


def relu(a: Tensor) -> Tensor:
    """Apply the ReLU activation elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: ReLU output.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.maximum(0, a.data), a.requires_grad, a._backend, (a,), "relu")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += (a.data > 0).astype(a.xp.float64) * out.grad

    out._backward = _backward
    return out


def leaky_relu(a: Tensor, alpha: float = 0.01) -> Tensor:
    """Apply the Leaky ReLU activation elementwise.

    Args:
        a (Tensor): Input tensor.
        alpha (float): Negative slope.

    Returns:
        Tensor: Leaky ReLU output.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        a.xp.where(a.data > 0, a.data, a.data * alpha),
        a.requires_grad,
        a._backend,
        (a,),
        "leaky_relu",
    )

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        grad = a.xp.where(a.data > 0, 1.0, alpha)
        a.grad += grad * out.grad

    out._backward = _backward
    return out


def softplus(a: Tensor) -> Tensor:
    """Apply the softplus activation elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Softplus output.
    """
    return log1p(exp(a))


def softmax(a: Tensor, dim: int | tuple[int, ...] = -1) -> Tensor:
    """Apply softmax over a given dimension.

    Args:
        a (Tensor): Input tensor.
        dim (int | tuple[int, ...]): Dimension or dimensions to normalize over.

    Returns:
        Tensor: Softmax output.
    """
    a_max = max(a, axis=dim, keepdims=True)
    exp_a = exp(a - a_max)
    return exp_a / sum(exp_a, axis=dim, keepdims=True)
