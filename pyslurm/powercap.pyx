# cython: embedsignature=True
"""
===============
:mod:`powercap`
===============

The powercap extension module is used to get Slurm powercapping information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_load_powercap
- slurm_free_powercap_info_msg
- slurm_print_powercap_info_msg

Powercap Object
---------------

Functions in this module wrap the ``powercap_info_msg_t`` struct found in
`slurm.h`. The members of this struct are converted to a :class:`Powercap` object,
which implements Python properties to retrieve the value of each attribute.

"""
from __future__ import absolute_import, unicode_literals

from libc.stdio cimport stdout

from .c_powercap cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Powercap:
    """An object to wrap `powercap_info_msg_t` structs."""
    cdef:
        uint32_t power_cap
        readonly uint32_t power_floor
        readonly uint32_t power_change_rate
        readonly uint32_t min_watts
        readonly uint32_t current_watts
        readonly uint32_t adjusted_max_watts
        readonly uint32_t max_watts

    @property
    def power_cap(self):
        """Power cap value in watts"""
        if self.power_cap == 0:
            return False
        elif self.power_cap == INFINITE:
            return "INFINITE"
        else:
            return self.power_cap


def get_powercap():
    """ src/api/powercap_info.c"""
    cdef:
        powercap_info_msg_t *powercap_info_msg_ptr = NULL
        int rc

    rc = slurm_load_powercap(&powercap_info_msg_ptr)

    if rc == SLURM_SUCCESS:
        powercap = Powercap()

        powercap.power_cap = powercap_info_msg_ptr.power_cap
        powercap.min_watts = powercap_info_msg_ptr.min_watts
        powercap.current_watts = powercap_info_msg_ptr.cur_max_watts
        powercap.power_floor = powercap_info_msg_ptr.power_floor
        powercap.power_change_rate = powercap_info_msg_ptr.power_change
        powercap.adjusted_max_watts = powercap_info_msg_ptr.adj_max_watts
        powercap.max_watts = powercap_info_msg_ptr.max_watts

        slurm_free_powercap_info_msg(powercap_info_msg_ptr)
        powercap_info_msg_ptr = NULL

        return powercap
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def print_powercap_info_msg(int one_liner=False):
    """
    Print information about powercapping to stdout.

    This function outputs information about all Slurm partitions based upon
    the message loaded by ``slurm_load_powercap``. It uses the
    ``slurm_print_powercap_info_msg`` function to print to stdout.  The
    output is equivalent to *scontrol show powercap*.

    Args:
        one_liner (Optional[bool]): print powercap info on one line if True
            (default False)
    Raises:
        PySlurmError: If ``slurm_load_powercap`` is not successful.
    """
    cdef:
        powercap_info_msg_t *powercap_info_msg_ptr = NULL
        int rc

    rc = slurm_load_powercap(&powercap_info_msg_ptr)

    if rc == SLURM_SUCCESS:
        slurm_print_powercap_info_msg(stdout, powercap_info_msg_ptr, one_liner)
        slurm_free_powercap_info_msg(powercap_info_msg_ptr)
        powercap_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
