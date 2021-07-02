#ifndef TENSOR_FUNCTION
#define TENSOR_FUNCTION
#include "tensorbody.h"
namespace fun{
 tensor sum(const& lhs, const& rhs) {
    assert(lhs.device == rhs.device); 
    return std::move(tensor(dispatch(lhs.data, rhs.data, lhs.device)));
 }
}
#endif
