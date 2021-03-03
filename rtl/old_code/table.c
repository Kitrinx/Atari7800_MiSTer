#include <stdio.h>
#include <stdint.h>
#include <math.h>

double R_MAX = 30.;
double R = 1.;

uint16_t mixingTableEntry(uint8_t v, uint8_t vMax)
{
    return (
    floor(0x7fff * (double)(v) / (double)(vMax) * (R_MAX + R * (double)(vMax)) / (R_MAX + R * (double)(v)))
    );
}

int main ()
{
    for (int32_t x = 0; x < 31; x++) {
        uint16_t val = mixingTableEntry(x, 30);
        printf("16'h%04X, ", val);
    }
}