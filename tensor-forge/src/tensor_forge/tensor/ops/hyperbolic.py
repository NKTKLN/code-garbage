"""Hyperbolic tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def sinh(a: Tensor) -> Tensor:
    """Compute the hyperbolic sine elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``sinh(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.sinh(a.data), a.requires_grad, a._backend, (a,), "sinh")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += a.xp.cosh(a.data) * out.grad

    out._backward = _backward
    return out


def cosh(a: Tensor) -> Tensor:
    """Compute the hyperbolic cosine elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``cosh(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.cosh(a.data), a.requires_grad, a._backend, (a,), "cosh")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += a.xp.sinh(a.data) * out.grad

    out._backward = _backward
    return out


def tanh(a: Tensor) -> Tensor:
    """Compute the hyperbolic tangent elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``tanh(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.tanh(a.data), a.requires_grad, a._backend, (a,), "tanh")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += (1.0 - a.xp.tanh(a.data) ** 2) * out.grad

    out._backward = _backward
    return out
