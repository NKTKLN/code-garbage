"""Binary differentiable tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

from numpy.typing import ArrayLike

from tensor_forge.tensor.autodiff import unbroadcast

from .helpers import ensure_tensor

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def add(a: Tensor, b: Tensor | ArrayLike) -> Tensor:
    """Add two tensors elementwise.

    Args:
        a (Tensor): Left tensor.
        b (Tensor | ArrayLike): Right tensor or array-like input.

    Returns:
        Tensor: Result of ``a + b``.
    """
    from tensor_forge.tensor import Tensor

    b = ensure_tensor(b, a._backend)
    requires_grad = a.requires_grad or b.requires_grad
    out = Tensor(a.data + b.data, requires_grad, a._backend, (a, b), "+")

    def _backward() -> None:
        """Backpropagate gradients to both operands."""
        if not out.requires_grad:
            return

        a.grad += unbroadcast(1.0 * out.grad, a.data.shape)
        b.grad += unbroadcast(1.0 * out.grad, b.data.shape)

    out._backward = _backward
    return out


def mul(a: Tensor, b: Tensor | ArrayLike) -> Tensor:
    """Multiply two tensors elementwise.

    Args:
        a (Tensor): Left tensor.
        b (Tensor | ArrayLike): Right tensor or array-like input.

    Returns:
        Tensor: Result of ``a * b``.
    """
    from tensor_forge.tensor import Tensor

    b = ensure_tensor(b, a._backend)
    requires_grad = a.requires_grad or b.requires_grad
    out = Tensor(a.data * b.data, requires_grad, a._backend, (a, b), "*")

    def _backward() -> None:
        """Backpropagate gradients to both operands."""
        if not out.requires_grad:
            return

        a.grad += unbroadcast(b.data * out.grad, a.data.shape)
        b.grad += unbroadcast(a.data * out.grad, b.data.shape)

    out._backward = _backward
    return out
