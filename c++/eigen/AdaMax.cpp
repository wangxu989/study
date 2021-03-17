#include<iostream>
#define EIGEN_USE_THREADS
#define EIGEN_TEST_NO_LONGDOUBLE
#define EIGEN_TEST_NO_COMPLEX
#define EIGEN_TEST_FUNC cxx11_tensor_cuda
#define EIGEN_DEFAULT_DENSE_INDEX_TYPE int
#define EIGEN_USE_GPU
#include<unsupported/Eigen/CXX11/Tensor>
#define N 40000
//#define CPU
using namespace Eigen;
typedef Eigen::CudaStreamDevice GPUStream;
typedef Eigen::GpuDevice GPUDevice;
typedef Eigen::DenseIndex IndexType;
typedef Eigen::ThreadPoolDevice CPUDevice;
#define NDIMS 1
template<typename T>
using TTensor =  Eigen::TensorMap<Eigen::Tensor<T, NDIMS, Eigen::RowMajor, IndexType>,Eigen::Aligned>;
template<typename T>
using Flat = Eigen::TensorMap<Eigen::Tensor<T, 1, Eigen::RowMajor, IndexType>,Eigen::Aligned>;
template<typename T>
using  ConstScalar = Eigen::TensorMap<Eigen::TensorFixedSize<const T, Eigen::Sizes<>,Eigen::RowMajor, IndexType>,Eigen::Aligned>;
template<typename T>
using ConstFlat =  Eigen::TensorMap<
Eigen::Tensor<const T, 1, Eigen::RowMajor, IndexType>, Eigen::Aligned>;

template<typename T>
struct test_cpu{
  Flat<T> call(T* _m,T* _v,T* _var,T* _grad) {
    NonBlockingThreadPool p(4);
    CPUDevice d(&p,4);
    Flat<T> m(_m,N),v(_v,N),var(_var,N);
    const T a = 0.5;
    ConstScalar<T> beta1_power(&a), lr(&a),beta1(&a),
      beta2(&a),epsilon(&a);
    ConstFlat<T> grad(_grad,N);
    m.device(d) += (grad - m)*(T(1) - beta1());
    v.device(d) = (beta2()*v).cwiseMax(grad.abs());
    var.device(d) -= lr() / (T(1) - beta1_power()) * (m/(v + epsilon()));
    return var;
  }
};
template<typename T>
struct test_gpu{
  Flat<T> call(T* _m,T* _v,T* _var,T* _grad) {
    GPUStream p;
    GPUDevice d(&p);
    Flat<T> m(_m,N),v(_v,N),var(_var,N);
    const T a = 0.5;
    ConstScalar<T> beta1_power(&a), lr(&a),beta1(&a),
      beta2(&a),epsilon(&a);
    ConstFlat<T> grad(_grad,N);
    m.device(d) += (grad - m)*(T(1) - beta1());
    v.device(d) = (beta2()*v).cwiseMax(grad.abs());
    var.device(d) -= lr() / (T(1) - beta1_power()) * (m/(v + epsilon()));
    return var;
  }
};
int main() {
  float _m[N],_v[N],_var[N],_grad[N];
  for (int i = 0;i < N;i++) {
    _m[i] = (float)rand();
    _v[i] = (float)rand();
    _var[i] = (float)rand();
    _grad[i] = (float)rand();
  }
  test_cpu<float> cpu_gen;
  Flat<float>out_cpu =  cpu_gen.call(_m,_v,_var,_grad);
  std::cout<<out_cpu<<std::endl;
}
