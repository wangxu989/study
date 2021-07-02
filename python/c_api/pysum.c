#include<python3.8/Python.h>
static int sum(int a, int b) {
 
  return a + b;
}
static PyObject*
pysum(PyObject* self, PyObject* args) {
  int a;
  int b;
  if(!PyArg_ParseTuple(args, "ii", &a, &b)) {
    return NULL;
  }
  return Py_BuildValue("i", sum(a, b));
}
static PyMethodDef module_methods[] = {
  {
    "test_sum",
    (PyCFunction)pysum,
    METH_VARARGS,
    ""
  },
  {NULL,NULL,0,NULL}
};
static struct PyModuleDef pysum_module = {
  PyModuleDef_HEAD_INIT,
  "pysum_module",
  "Usage",
  -1,
  module_methods
};
PyMODINIT_FUNC PyInit_pysum_module(void) {
  return PyModule_Create(&pysum_module);
}
