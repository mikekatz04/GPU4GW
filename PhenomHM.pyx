import numpy as np
cimport numpy as np

assert sizeof(int) == sizeof(np.int32_t)

cdef extern from "src/c_manager.h":
    cdef cppclass PhenomHMwrap "PhenomHM":
        PhenomHMwrap(int,
        np.uint32_t *,
        np.uint32_t *,
        int,
        np.float64_t*,
        np.complex128_t *, np.complex128_t *, np.complex128_t *, int, np.float64_t*, np.float64_t*, np.float64_t*, int)

        void gen_amp_phase(np.float64_t *, int,
                            double,
                            double,
                            double,
                            double,
                            double,
                            double,
                            double)

        void GetAmpPhase(np.float64_t*, np.float64_t*)

cdef class PhenomHM:
    cdef PhenomHMwrap* g
    cdef int num_modes
    cdef int data_length
    cdef data_channel1
    cdef data_channel2
    cdef data_channel3
    cdef int current_length

    def __cinit__(self, max_length_init,
     np.ndarray[ndim=1, dtype=np.uint32_t] l_vals,
     np.ndarray[ndim=1, dtype=np.uint32_t] m_vals,
     np.ndarray[ndim=1, dtype=np.float64_t] data_freqs,
     np.ndarray[ndim=1, dtype=np.complex128_t] data_channel1,
     np.ndarray[ndim=1, dtype=np.complex128_t] data_channel2,
     np.ndarray[ndim=1, dtype=np.complex128_t] data_channel3,
     np.ndarray[ndim=1, dtype=np.float64_t] X_ASDinv,
     np.ndarray[ndim=1, dtype=np.float64_t] Y_ASDinv,
     np.ndarray[ndim=1, dtype=np.float64_t] Z_ASDinv,
     TDItag):
        self.num_modes = len(l_vals)
        self.data_channel1 = data_channel1
        self.data_channel2 = data_channel2
        self.data_channel3 = data_channel3
        self.data_length = len(data_channel1)
        self.g = new PhenomHMwrap(max_length_init,
        &l_vals[0],
        &m_vals[0],
        self.num_modes, &data_freqs[0],
        &data_channel1[0], &data_channel2[0], &data_channel3[0],
        self.data_length, &X_ASDinv[0], &Y_ASDinv[0], &Z_ASDinv[0], TDItag)

    def gen_amp_phase(self, np.ndarray[ndim=1, dtype=np.float64_t] freqs,
                        m1, #solar masses
                        m2, #solar masses
                        chi1z,
                        chi2z,
                        distance,
                        phiRef,
                        f_ref):

        self.current_length = len(freqs)
        self.g.gen_amp_phase(&freqs[0], self.current_length,
                                m1, #solar masses
                                m2, #solar masses
                                chi1z,
                                chi2z,
                                distance,
                                phiRef,
                                f_ref)

    def GetAmpPhase(self):
        cdef np.ndarray[ndim=1, dtype=np.float64_t] amp_
        cdef np.ndarray[ndim=1, dtype=np.float64_t] phase_

        amp_ = np.zeros((self.num_modes*self.current_length,), dtype=np.float64)
        phase_ = np.zeros((self.num_modes*self.current_length,), dtype=np.float64)

        self.g.GetAmpPhase(&amp_[0], &phase_[0])
        return (amp_.reshape(self.num_modes, self.current_length), phase_.reshape(self.num_modes, self.current_length))