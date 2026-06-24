"""Trigonometric tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def sin(a: Tensor) -> Tensor:
    """Compute the sine elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``sin(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.sin(a.data), a.requires_grad, a._backend, (a,), "sin")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += a.xp.cos(a.data) * out.grad

    out._backward = _backward
    return out


def cos(a: Tensor) -> Tensor:
    """Compute the cosine elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``cos(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.cos(a.data), a.requires_grad, a._backend, (a,), "cos")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += -a.xp.sin(a.data) * out.grad

    out._backward = _backward
    return out


def tan(a: Tensor) -> Tensor:
    """Compute the tangent elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``tan(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.tan(a.data), a.requires_grad, a._backend, (a,), "tan")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += 1.0 / a.xp.cos(a.data) ** 2 * out.grad

    out._backward = _backward
    return out


def arcsin(a: Tensor) -> Tensor:
    """Compute the inverse sine elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``arcsin(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.arcsin(a.data), a.requires_grad, a._backend, (a,), "arcsin")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += 1.0 / a.xp.sqrt(1.0 - a.data**2) * out.grad

    out._backward = _backward
    return out


def arccos(a: Tensor) -> Tensor:
    """Compute the inverse cosine elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``arccos(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.arccos(a.data), a.requires_grad, a._backend, (a,), "arccos")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += -1.0 / a.xp.sqrt(1.0 - a.data**2) * out.grad

    out._backward = _backward
    return out


def arctan(a: Tensor) -> Tensor:
    """Compute the inverse tangent elementwise.

    Args:
        a (Tensor): Input tensor.

    Returns:
        Tensor: Result of ``arctan(a)``.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(a.xp.arctan(a.data), a.requires_grad, a._backend, (a,), "arctan")

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        a.grad += 1.0 / (1.0 + a.data**2) * out.grad

    out._backward = _backward
    return out
