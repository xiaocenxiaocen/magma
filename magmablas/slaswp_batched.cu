/*
    -- MAGMA (version 2.1.0) --
       Univ. of Tennessee, Knoxville
       Univ. of California, Berkeley
       Univ. of Colorado, Denver
       @date August 2016

       @generated from magmablas/zlaswp_batched.cu, normal z -> s, Tue Aug 30 09:38:39 2016
       
       @author Azzam Haidar
       @author Tingxing Dong
*/
#include "magma_internal.h"
#include "batched_kernel_param.h"

#define BLK_SIZE 256
// SWP_WIDTH is number of threads in a block
// 64 and 256 are better on Kepler; 
extern __shared__ float shared_data[];


/******************************************************************************/
static __device__ 
void slaswp_rowparallel_devfunc(  
                              int n, int width, int height,
                              float *dA, int lda, 
                              float *dout, int ldo,
                              magma_int_t* pivinfo)
{
    //int height = k2- k1;
    //int height = blockDim.x;
    unsigned int tid = threadIdx.x;
    dA   += SWP_WIDTH * blockIdx.x * lda;
    dout += SWP_WIDTH * blockIdx.x * ldo;
    float *sdata = shared_data;

    if (blockIdx.x == gridDim.x -1)
    {
        width = n - blockIdx.x * SWP_WIDTH;
    }

    if (tid < height)
    {
        int mynewroworig = pivinfo[tid]-1; //-1 to get the index in C
        int itsreplacement = pivinfo[mynewroworig] -1; //-1 to get the index in C
        #pragma unroll
        for (int i=0; i < width; i++)
        {
            sdata[ tid + i * height ]    = dA[ mynewroworig + i * lda ];
            dA[ mynewroworig + i * lda ] = dA[ itsreplacement + i * lda ];
        }
    }
    __syncthreads();

    if (tid < height)
    {
        // copy back the upper swapped portion of A to dout 
        #pragma unroll
        for (int i=0; i < width; i++)
        {
            dout[tid + i * ldo] = sdata[tid + i * height];
        }
    }
}


/******************************************************************************/
// parallel swap the swaped dA(1:nb,i:n) is stored in dout 
__global__ 
void slaswp_rowparallel_kernel( 
                                int n, int width, int height,
                                float *dinput, int ldi, 
                                float *doutput, int ldo,
                                magma_int_t*  pivinfo)
{
    slaswp_rowparallel_devfunc(n, width, height, dinput, ldi, doutput, ldo, pivinfo);
}


/******************************************************************************/
__global__ 
void slaswp_rowparallel_kernel_batched(
                                int n, int width, int height,
                                float **input_array, int ldi, 
                                float **output_array, int ldo,
                                magma_int_t** pivinfo_array)
{
    int batchid = blockIdx.z;
    slaswp_rowparallel_devfunc(n, width, height, input_array[batchid], ldi, output_array[batchid], ldo, pivinfo_array[batchid]);
}


/******************************************************************************/
extern "C" void
magma_slaswp_rowparallel_batched( magma_int_t n, 
                       float** input_array, magma_int_t ldi,
                       float** output_array, magma_int_t ldo,
                       magma_int_t k1, magma_int_t k2,
                       magma_int_t **pivinfo_array, 
                       magma_int_t batchCount, magma_queue_t queue)
{
    if (n == 0 ) return;
    int height = k2-k1;
    if ( height  > 1024) 
    {
        fprintf( stderr, "%s: n=%lld > 1024, not supported\n", __func__, (long long) n );
    }

    int blocks = magma_ceildiv( n, SWP_WIDTH );
    dim3  grid(blocks, 1, batchCount);

    if ( n < SWP_WIDTH)
    {
        size_t shmem = sizeof(float) * height * n;
        slaswp_rowparallel_kernel_batched
            <<< grid, height, shmem, queue->cuda_stream() >>>
            ( n, n, height, input_array, ldi, output_array, ldo, pivinfo_array ); 
    }
    else
    {
        size_t shmem = sizeof(float) * height * SWP_WIDTH;
        slaswp_rowparallel_kernel_batched
            <<< grid, height, shmem, queue->cuda_stream() >>>
            ( n, SWP_WIDTH, height, input_array, ldi, output_array, ldo, pivinfo_array );
    }
}


/******************************************************************************/
extern "C" void
magma_slaswp_rowparallel(
    magma_int_t n, 
    float* input, magma_int_t ldi,
    float* output, magma_int_t ldo,
    magma_int_t k1, magma_int_t k2,
    magma_int_t *pivinfo, 
    magma_queue_t queue)
{
    if (n == 0 ) return;
    int height = k2-k1;
    if ( height  > MAX_NTHREADS) 
    {
        fprintf( stderr, "%s: height=%lld > %lld, magma_slaswp_rowparallel_q not supported\n",
                 __func__, (long long) n, (long long) MAX_NTHREADS );
    }

    int blocks = magma_ceildiv( n, SWP_WIDTH );
    dim3  grid(blocks, 1, 1);

    if ( n < SWP_WIDTH)
    {
        size_t shmem = sizeof(float) * height * n;
        slaswp_rowparallel_kernel
            <<< grid, height, shmem, queue->cuda_stream() >>>
            ( n, n, height, input, ldi, output, ldo, pivinfo ); 
    }
    else
    {
        size_t shmem = sizeof(float) * height * SWP_WIDTH;
        slaswp_rowparallel_kernel
            <<< grid, height, shmem, queue->cuda_stream() >>>
            ( n, SWP_WIDTH, height, input, ldi, output, ldo, pivinfo ); 
    }
}


/******************************************************************************/
// serial swap that does swapping one row by one row
__global__ void slaswp_rowserial_kernel_batched( int n, float **dA_array, int lda, int k1, int k2, magma_int_t** ipiv_array )
{
    float* dA = dA_array[blockIdx.z];
    magma_int_t *d_ipiv = ipiv_array[blockIdx.z];
    
    unsigned int tid = threadIdx.x + blockDim.x*blockIdx.x;
    
    k1--;
    k2--;

    if (tid < n) {
        float A1;

        for (int i1 = k1; i1 < k2; i1++) 
        {
            int i2 = d_ipiv[i1] - 1;  // Fortran index, switch i1 and i2
            if ( i2 != i1)
            {
                A1 = dA[i1 + tid * lda];
                dA[i1 + tid * lda] = dA[i2 + tid * lda];
                dA[i2 + tid * lda] = A1;
            }
        }
    }
}


/******************************************************************************/
// serial swap that does swapping one row by one row, similar to LAPACK
// K1, K2 are in Fortran indexing  
extern "C" void
magma_slaswp_rowserial_batched(magma_int_t n, float** dA_array, magma_int_t lda,
                   magma_int_t k1, magma_int_t k2,
                   magma_int_t **ipiv_array, 
                   magma_int_t batchCount, magma_queue_t queue)
{
    if (n == 0) return;

    int blocks = magma_ceildiv( n, BLK_SIZE );
    dim3  grid(blocks, 1, batchCount);

    slaswp_rowserial_kernel_batched
        <<< grid, max(BLK_SIZE, n), 0, queue->cuda_stream() >>>
        (n, dA_array, lda, k1, k2, ipiv_array);
}



/******************************************************************************/
// serial swap that does swapping one column by one column
__global__ void slaswp_columnserial_kernel_batched( int n, float **dA_array, int lda, int k1, int k2, magma_int_t** ipiv_array )
{
    float* dA = dA_array[blockIdx.z];
    magma_int_t *d_ipiv = ipiv_array[blockIdx.z];
    
    unsigned int tid = threadIdx.x + blockDim.x*blockIdx.x;
    k1--;
    k2--;
    if ( k1 < 0 || k2 < 0 ) return;


    if ( tid < n) {
        float A1;
        if (k1 <= k2)
        {
            for (int i1 = k1; i1 <= k2; i1++) 
            {
                int i2 = d_ipiv[i1] - 1;  // Fortran index, switch i1 and i2
                if ( i2 != i1)
                {
                    A1 = dA[i1 * lda + tid];
                    dA[i1 * lda + tid] = dA[i2 * lda + tid];
                    dA[i2 * lda + tid] = A1;
                }
            }
        } else
        {
            for (int i1 = k1; i1 >= k2; i1--) 
            {
                int i2 = d_ipiv[i1] - 1;  // Fortran index, switch i1 and i2
                if ( i2 != i1)
                {
                    A1 = dA[i1 * lda + tid];
                    dA[i1 * lda + tid] = dA[i2 * lda + tid];
                    dA[i2 * lda + tid] = A1;
                }
            }
        }
    }
}


/******************************************************************************/
// serial swap that does swapping one column by one column
// K1, K2 are in Fortran indexing  
extern "C" void
magma_slaswp_columnserial_batched(magma_int_t n, float** dA_array, magma_int_t lda,
                   magma_int_t k1, magma_int_t k2,
                   magma_int_t **ipiv_array, 
                   magma_int_t batchCount, magma_queue_t queue)
{
    if (n == 0 ) return;

    int blocks = magma_ceildiv( n, BLK_SIZE );
    dim3  grid(blocks, 1, batchCount);

    slaswp_columnserial_kernel_batched
        <<< grid, min(BLK_SIZE, n), 0, queue->cuda_stream() >>>
        (n, dA_array, lda, k1, k2, ipiv_array);
}
