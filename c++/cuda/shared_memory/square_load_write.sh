nvcc square_load_write.cu
nvprof --metrics shared_load_transactions_per_request,shared_store_transactions_per_request ./a.out 

