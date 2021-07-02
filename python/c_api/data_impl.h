#ifndef DATA_IMPL
#define DATA_IMPL
#include "./device_type.h"
template<typename T, typename Device>
class data_impl{
  public:
    data_impl(T* val, Device d)
      :data(val),
      device(d) {

      }
  private:
      T* data;
      Device device;
}

#endif
