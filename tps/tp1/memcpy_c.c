#include <stdio.h>
#include <stdlib.h>
#include <string.h>


// En caso de que se quiera implementar la copia mediante la abi, aqui esta la funcion c:
void memcpy_c(void*, const void*, unsigned int);

void memcpy_c(void *dest, const void *orig, unsigned int num_bytes)
{
    int *dest = malloc(num_bytes*4);
    memcpy(dest, orig, sizeof(int));
}