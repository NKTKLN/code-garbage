"""Reduction operations for tensors."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def sum(
    a: Tensor,
    axis: int | tuple[int, ...] | None = None,
    keepdims: bool = False,
) -> Tensor:
    """Sum tensor elements over given axes.

    Args:
        a (Tensor): Input tensor.
        axis (int | tuple[int, ...] | None): Reduction axis or axes.
        keepdims (bool): Whether to keep reduced dimensions.

    Returns:
        Tensor: Reduced tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        a.xp.sum(a.data, axis=axis, keepdims=keepdims),
        a.requires_grad,
        a._backend,
        (a,),
        f"sum({axis=}, {keepdims=})",
    )

    input_shape = a.data.shape

    if axis is None:
        axes: tuple[int, ...] | None = None
    elif isinstance(axis, int):
        axes = (axis,)
    else:
        axes = axis

    if axes is not None:
        axes = tuple(ax if ax >= 0 else ax + len(input_shape) for ax in axes)

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        grad = out.grad
        if not keepdims and axes is not None:
            for ax in sorted(axes):
                grad = a.xp.expand_dims(grad, axis=ax)

        a.grad += a.xp.broadcast_to(grad, input_shape)

    out._backward = _backward
    return out


def mean(
    a: Tensor,
    axis: int | tuple[int, ...] | None = None,
    keepdims: bool = False,
) -> Tensor:
    """Compute the mean over given axes.

    Args:
        a (Tensor): Input tensor.
        axis (int | tuple[int, ...] | None): Reduction axis or axes.
        keepdims (bool): Whether to keep reduced dimensions.

    Returns:
        Tensor: Reduced tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        a.xp.mean(a.data, axis=axis, keepdims=keepdims),
        a.requires_grad,
        a._backend,
        (a,),
        f"mean({axis=}, {keepdims=})",
    )

    input_shape = a.data.shape

    if axis is None:
        axes: tuple[int, ...] | None = None
        n = a.data.size
    elif isinstance(axis, int):
        axes = (axis,)
    else:
        axes = axis

    if axes is not None:
        axes = tuple(ax if ax >= 0 else ax + len(input_shape) for ax in axes)

        n = 1
        for ax in axes:
            n *= a.data.shape[ax]

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        grad = out.grad
        if not keepdims and axes is not None:
            for ax in sorted(axes):
                grad = a.xp.expand_dims(grad, axis=ax)

        a.grad += a.xp.broadcast_to(grad, input_shape) / n

    out._backward = _backward
    return out


def max(
    a: Tensor,
    axis: int | tuple[int, ...] | None = None,
    keepdims: bool = False,
) -> Tensor:
    """Compute the maximum over given axes.

    Args:
        a (Tensor): Input tensor.
        axis (int | tuple[int, ...] | None): Reduction axis or axes.
        keepdims (bool): Whether to keep reduced dimensions.

    Returns:
        Tensor: Reduced tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        a.xp.max(a.data, axis=axis, keepdims=keepdims),
        a.requires_grad,
        a._backend,
        (a,),
        f"max({axis=}, {keepdims=})",
    )

    input_shape = a.data.shape

    if axis is None:
        axes: tuple[int, ...] | None = None
    elif isinstance(axis, int):
        axes = (axis,)
    else:
        axes = axis

    if axes is not None:
        axes = tuple(ax if ax >= 0 else ax + len(input_shape) for ax in axes)

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        grad = out.grad
        out_data = out.data

        if axis is None:
            mask = a.data == out_data
            n = mask.sum(axis=axes)
            a.grad += grad * mask / n
            return

        if not keepdims and axes is not None:
            for ax in sorted(axes):
                grad = a.xp.expand_dims(grad, axis=ax)
                out_data = a.xp.expand_dims(out_data, axis=ax)

        grad = a.xp.broadcast_to(grad, input_shape)
        out_data = a.xp.broadcast_to(out_data, input_shape)

        mask = a.data == out_data
        n = mask.sum(axis=axes, keepdims=True)
        a.grad += grad * mask / n

    out._backward = _backward
    return out


def min(
    a: Tensor,
    axis: int | tuple[int, ...] | None = None,
    keepdims: bool = False,
) -> Tensor:
    """Compute the minimum over given axes.

    Args:
        a (Tensor): Input tensor.
        axis (int | tuple[int, ...] | None): Reduction axis or axes.
        keepdims (bool): Whether to keep reduced dimensions.

    Returns:
        Tensor: Reduced tensor.
    """
    from tensor_forge.tensor import Tensor

    out = Tensor(
        a.xp.min(a.data, axis=axis, keepdims=keepdims),
        a.requires_grad,
        a._backend,
        (a,),
        f"min({axis=}, {keepdims=})",
    )

    input_shape = a.data.shape

    if axis is None:
        axes: tuple[int, ...] | None = None
    elif isinstance(axis, int):
        axes = (axis,)
    else:
        axes = axis

    if axis is not None:
        axes = tuple(ax if ax >= 0 else ax + len(input_shape) for ax in axes)

    def _backward() -> None:
        """Backpropagate gradients to the input tensor."""
        if not out.requires_grad:
            return

        grad = out.grad
        out_data = out.data

        if axis is None:
            mask = a.data == out_data
            n = mask.sum(axis=axes)
            a.grad += grad * mask / n
            return

        if not keepdims and axes is not None:
            for ax in sorted(axes):
                grad = a.xp.expand_dims(grad, axis=ax)
                out_data = a.xp.expand_dims(out_data, axis=ax)

        grad = a.xp.broadcast_to(grad, input_shape)
        out_data = a.xp.broadcast_to(out_data, input_shape)

        mask = a.data == out_data
        n = mask.sum(axis=axes, keepdims=True)
        a.grad += grad * mask / n

    out._backward = _backward
    return out
