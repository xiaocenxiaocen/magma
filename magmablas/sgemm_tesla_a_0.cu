/*
    -- MAGMA (version 1.6.0) --
       Univ. of Tennessee, Knoxville
       Univ. of California, Berkeley
       Univ. of Colorado, Denver
       @date November 2014

       @generated from dgemm_tesla_a_0.cu normal d -> s, Sat Nov 15 19:53:59 2014
*/
#include "common_magma.h"
#include "commonblas_s.h"

/*
 * Computes C = alpha*A*B + beta*C when alpha == 0 and beta != 0.
 * That is, C *= beta.
 */
__global__ void
sgemm_kernel_a_0(
    float*       __restrict__ C,
    const float* __restrict__ A,
    const float* __restrict__ B,
    int m, int n, int k,
    int lda, int ldb, int ldc,
    float alpha, float beta )
{
    const int tx = threadIdx.x;
    const int ty = threadIdx.y;

    int ibx = blockIdx.x * 64;
    int iby = blockIdx.y * 16;

    const int idt = ty * 16 + tx;

    C += ibx + idt + __mul24(iby, ldc);

    ibx = ibx + idt - m;
    
    if ( (iby+16) >= n ) {
        lda = n - iby;
    }
    else {
        lda = 16;
    }
    if ( ibx >= 0 )
        lda = 0;
    else
        lda = lda;

    switch(lda) {
        case 16:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                C[10*ldc] *= beta;
                C[11*ldc] *= beta;
                C[12*ldc] *= beta;
                C[13*ldc] *= beta;
                C[14*ldc] *= beta;
                C[15*ldc] *= beta;
                break;
        case 15:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                C[10*ldc] *= beta;
                C[11*ldc] *= beta;
                C[12*ldc] *= beta;
                C[13*ldc] *= beta;
                C[14*ldc] *= beta;
                break;
        case 14:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                C[10*ldc] *= beta;
                C[11*ldc] *= beta;
                C[12*ldc] *= beta;
                C[13*ldc] *= beta;
                break;
        case 13:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                C[10*ldc] *= beta;
                C[11*ldc] *= beta;
                C[12*ldc] *= beta;
                break;
        case 12:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                C[10*ldc] *= beta;
                C[11*ldc] *= beta;
                break;
        case 11:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                C[10*ldc] *= beta;
                break;
        case 10:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                C[ 9*ldc] *= beta;
                break;
        case 9:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                C[ 8*ldc] *= beta;
                break;
        case 8:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                C[ 7*ldc] *= beta;
                break;
        case 7:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                C[ 6*ldc] *= beta;
                break;
        case 6:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                C[ 5*ldc] *= beta;
                break;
        case 5:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                C[ 4*ldc] *= beta;
                break;
        case 4:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                C[ 3*ldc] *= beta;
                break;
        case 3:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                C[ 2*ldc] *= beta;
                break;
        case 2:
                C[ 0    ] *= beta;
                C[ 1*ldc] *= beta;
                break;
        case 1:
                C[ 0    ] *= beta;
                break;
        case 0:
                break;
    }
}


extern "C" void
magmablas_sgemm_a_0(
    float *C, const float *A, const float *B,
    magma_int_t m, magma_int_t n, magma_int_t k,
    magma_int_t lda, magma_int_t ldb, magma_int_t ldc,
    float alpha, float beta )
{
    dim3 threads( 16, 4 );
    dim3 grid( (m - 1)/64 + 1, (n - 1)/16 + 1 );
    sgemm_kernel_a_0<<< grid, threads, 0, magma_stream >>>
        ( C, A, B, m, n, k, lda, ldb, ldc, alpha, beta );
}
