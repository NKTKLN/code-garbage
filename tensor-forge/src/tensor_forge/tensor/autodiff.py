"""Autodiff helper utilities."""

from __future__ import annotations

from typing import TYPE_CHECKING

from .backends import Array

if TYPE_CHECKING:
    from .tensor import Tensor


def unbroadcast(grad: Array, shape: tuple[int, ...]) -> Array:
    """Reduce a broadcasted gradient to a target shape.

    Args:
        grad (Array): Broadcasted gradient.
        shape (tuple[int, ...]): Target shape.

    Returns:
        Array: Gradient reduced to the target shape.
    """
    while len(grad.shape) > len(shape):
        grad = grad.sum(axis=0)

    for axis, size in enumerate(shape):
        if size == 1:
            grad = grad.sum(axis=axis, keepdims=True)

    return grad


def topological_sort(root: Tensor) -> list[Tensor]:
    """Return tensors in topological order.

    Args:
        root (Tensor): Root tensor of the computation graph.

    Returns:
        list[Tensor]: Tensors in topological order.
    """
    order: list[Tensor] = []
    visited: set[Tensor] = set()

    def build_order(node: Tensor) -> None:
        """Visit graph nodes recursively.

        Args:
            node (Tensor): Current tensor node.
        """
        if node in visited:
            return

        visited.add(node)

        for child in node._prev:
            build_order(child)

        order.append(node)

    build_order(root)
    return order
