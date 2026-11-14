#include <node_api.h>

/* Returns "real-node-api" when the calls reach the host's Node-API.
   If they reach a stub instead, the value stays NULL and `exports` is returned. */
NAPI_MODULE_INIT() {
  napi_value v = NULL;
  if (napi_create_string_utf8(env, "real-node-api", NAPI_AUTO_LENGTH, &v) != napi_ok || v == NULL)
    return exports;
  return v;
}
