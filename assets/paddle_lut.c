// Make Paddle values
#include <math.h>
#include <stdint.h>
#include <stdio.h>

// Note these are Nanoseconds * 100
#define BASE_TIME (6034284.0)
#define T_PER_KO (4532214.0)

int32_t main ()
{
	for (int32_t x = 0; x < 1024; x++) {
		double ind_value = BASE_TIME + ((double)x * T_PER_KO);
		if (x % 8 == 0)
			printf("\n\t");
		printf("33'h%09lX, ", (uint64_t)round(ind_value));
	}
	printf ("\n");
}