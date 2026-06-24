"""Linear algebra tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

from numpy.typing import ArrayLike

from .helpers import ensure_tensor

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor

from tensor_forge.errors import InvalidMatmulDimensionError


def matmul(a: Tensor, b: Tensor | ArrayLike) -> Tensor:
    """Multiply two tensors using matrix multiplication rules.

    Args:
        a (Tensor): Left tensor with 1D or 2D shape.
        b (Tensor | ArrayLike): Right tensor or array-like input with 1D or 2D shape.

    Returns:
        Tensor: Matrix multiplication result.

    Raises:
        ValueError: If either input is not 1D or 2D.
    """
    from tensor_forge.tensor import Tensor

    b = ensure_tensor(b, a._backend)
    xp = a.xp

    requires_grad = a.requires_grad or b.requires_grad
    out = Tensor(xp.matmul(a.data, b.data), requires_grad, a._backend, (a, b), "@")

    a_ndim = a.data.ndim
    b_ndim = b.data.ndim

    if a_ndim not in (1, 2) or b_ndim not in (1, 2):
        raise InvalidMatmulDimensionError(a_ndim, b_ndim)

    def _backward() -> None:
        """Backpropagate gradients to both operands."""
        if not out.requires_grad:
            return

        grad = out.grad

        VECTOR_NDIM = 1
        MATRIX_NDIM = 2

        if (a_ndim, b_ndim) == (VECTOR_NDIM, VECTOR_NDIM):
            a.grad += b.data * grad
            b.grad += a.data * grad
            return

        if (a_ndim, b_ndim) == (VECTOR_NDIM, MATRIX_NDIM):
            a.grad += xp.matmul(grad, b.data.T)
            b.grad += xp.outer(a.data, grad)
            return

        if (a_ndim, b_ndim) == (MATRIX_NDIM, VECTOR_NDIM):
            a.grad += xp.outer(grad, b.data)
            b.grad += xp.matmul(a.data.T, grad)
            return

        if (a_ndim, b_ndim) == (MATRIX_NDIM, MATRIX_NDIM):
            a.grad += xp.matmul(grad, b.data.T)
            b.grad += xp.matmul(a.data.T, grad)
            return

    out._backward = _backward
    return out
