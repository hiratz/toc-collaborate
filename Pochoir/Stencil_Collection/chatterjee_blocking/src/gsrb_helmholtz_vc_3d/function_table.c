#define PREFETCH_INDEX_TYPES 4	// no prefetch, or prefetch for register block, leading planes, or leading pencils
#define PREFETCH_DISTANCES 6	// the distances ahead being prefetched
#define RB_SIZES 9		// the number of register block sizes

void (*helmholtz_per_thread[PREFETCH_INDEX_TYPES][PREFETCH_DISTANCES][RB_SIZES])() =
{{{	&helmholtz_per_thread_no_0_2x2x2RB, 	&helmholtz_per_thread_no_0_2x2x4RB, 	&helmholtz_per_thread_no_0_2x2x8RB, 	&helmholtz_per_thread_no_0_2x4x2RB, 	&helmholtz_per_thread_no_0_2x4x4RB, 	&helmholtz_per_thread_no_0_4x2x2RB, 	&helmholtz_per_thread_no_0_4x2x4RB, 	&helmholtz_per_thread_no_0_4x4x2RB, 	&helmholtz_per_thread_no_0_4x4x4RB},
{	&helmholtz_per_thread_no_32_2x2x2RB, 	&helmholtz_per_thread_no_32_2x2x4RB, 	&helmholtz_per_thread_no_32_2x2x8RB, 	&helmholtz_per_thread_no_32_2x4x2RB, 	&helmholtz_per_thread_no_32_2x4x4RB, 	&helmholtz_per_thread_no_32_4x2x2RB, 	&helmholtz_per_thread_no_32_4x2x4RB, 	&helmholtz_per_thread_no_32_4x4x2RB, 	&helmholtz_per_thread_no_32_4x4x4RB},
{	&helmholtz_per_thread_no_64_2x2x2RB, 	&helmholtz_per_thread_no_64_2x2x4RB, 	&helmholtz_per_thread_no_64_2x2x8RB, 	&helmholtz_per_thread_no_64_2x4x2RB, 	&helmholtz_per_thread_no_64_2x4x4RB, 	&helmholtz_per_thread_no_64_4x2x2RB, 	&helmholtz_per_thread_no_64_4x2x4RB, 	&helmholtz_per_thread_no_64_4x4x2RB, 	&helmholtz_per_thread_no_64_4x4x4RB},
{	&helmholtz_per_thread_no_128_2x2x2RB, 	&helmholtz_per_thread_no_128_2x2x4RB, 	&helmholtz_per_thread_no_128_2x2x8RB, 	&helmholtz_per_thread_no_128_2x4x2RB, 	&helmholtz_per_thread_no_128_2x4x4RB, 	&helmholtz_per_thread_no_128_4x2x2RB, 	&helmholtz_per_thread_no_128_4x2x4RB, 	&helmholtz_per_thread_no_128_4x4x2RB, 	&helmholtz_per_thread_no_128_4x4x4RB},
{	&helmholtz_per_thread_no_256_2x2x2RB, 	&helmholtz_per_thread_no_256_2x2x4RB, 	&helmholtz_per_thread_no_256_2x2x8RB, 	&helmholtz_per_thread_no_256_2x4x2RB, 	&helmholtz_per_thread_no_256_2x4x4RB, 	&helmholtz_per_thread_no_256_4x2x2RB, 	&helmholtz_per_thread_no_256_4x2x4RB, 	&helmholtz_per_thread_no_256_4x4x2RB, 	&helmholtz_per_thread_no_256_4x4x4RB},
{	&helmholtz_per_thread_no_512_2x2x2RB, 	&helmholtz_per_thread_no_512_2x2x4RB, 	&helmholtz_per_thread_no_512_2x2x8RB, 	&helmholtz_per_thread_no_512_2x4x2RB, 	&helmholtz_per_thread_no_512_2x4x4RB, 	&helmholtz_per_thread_no_512_4x2x2RB, 	&helmholtz_per_thread_no_512_4x2x4RB, 	&helmholtz_per_thread_no_512_4x4x2RB, 	&helmholtz_per_thread_no_512_4x4x4RB}
},
{{	&helmholtz_per_thread_re_0_2x2x2RB, 	&helmholtz_per_thread_re_0_2x2x4RB, 	&helmholtz_per_thread_re_0_2x2x8RB, 	&helmholtz_per_thread_re_0_2x4x2RB, 	&helmholtz_per_thread_re_0_2x4x4RB, 	&helmholtz_per_thread_re_0_4x2x2RB, 	&helmholtz_per_thread_re_0_4x2x4RB, 	&helmholtz_per_thread_re_0_4x4x2RB, 	&helmholtz_per_thread_re_0_4x4x4RB},
{	&helmholtz_per_thread_re_32_2x2x2RB, 	&helmholtz_per_thread_re_32_2x2x4RB, 	&helmholtz_per_thread_re_32_2x2x8RB, 	&helmholtz_per_thread_re_32_2x4x2RB, 	&helmholtz_per_thread_re_32_2x4x4RB, 	&helmholtz_per_thread_re_32_4x2x2RB, 	&helmholtz_per_thread_re_32_4x2x4RB, 	&helmholtz_per_thread_re_32_4x4x2RB, 	&helmholtz_per_thread_re_32_4x4x4RB},
{	&helmholtz_per_thread_re_64_2x2x2RB, 	&helmholtz_per_thread_re_64_2x2x4RB, 	&helmholtz_per_thread_re_64_2x2x8RB, 	&helmholtz_per_thread_re_64_2x4x2RB, 	&helmholtz_per_thread_re_64_2x4x4RB, 	&helmholtz_per_thread_re_64_4x2x2RB, 	&helmholtz_per_thread_re_64_4x2x4RB, 	&helmholtz_per_thread_re_64_4x4x2RB, 	&helmholtz_per_thread_re_64_4x4x4RB},
{	&helmholtz_per_thread_re_128_2x2x2RB, 	&helmholtz_per_thread_re_128_2x2x4RB, 	&helmholtz_per_thread_re_128_2x2x8RB, 	&helmholtz_per_thread_re_128_2x4x2RB, 	&helmholtz_per_thread_re_128_2x4x4RB, 	&helmholtz_per_thread_re_128_4x2x2RB, 	&helmholtz_per_thread_re_128_4x2x4RB, 	&helmholtz_per_thread_re_128_4x4x2RB, 	&helmholtz_per_thread_re_128_4x4x4RB},
{	&helmholtz_per_thread_re_256_2x2x2RB, 	&helmholtz_per_thread_re_256_2x2x4RB, 	&helmholtz_per_thread_re_256_2x2x8RB, 	&helmholtz_per_thread_re_256_2x4x2RB, 	&helmholtz_per_thread_re_256_2x4x4RB, 	&helmholtz_per_thread_re_256_4x2x2RB, 	&helmholtz_per_thread_re_256_4x2x4RB, 	&helmholtz_per_thread_re_256_4x4x2RB, 	&helmholtz_per_thread_re_256_4x4x4RB},
{	&helmholtz_per_thread_re_512_2x2x2RB, 	&helmholtz_per_thread_re_512_2x2x4RB, 	&helmholtz_per_thread_re_512_2x2x8RB, 	&helmholtz_per_thread_re_512_2x4x2RB, 	&helmholtz_per_thread_re_512_2x4x4RB, 	&helmholtz_per_thread_re_512_4x2x2RB, 	&helmholtz_per_thread_re_512_4x2x4RB, 	&helmholtz_per_thread_re_512_4x4x2RB, 	&helmholtz_per_thread_re_512_4x4x4RB}
},
{{	&helmholtz_per_thread_pl_0_2x2x2RB, 	&helmholtz_per_thread_pl_0_2x2x4RB, 	&helmholtz_per_thread_pl_0_2x2x8RB, 	&helmholtz_per_thread_pl_0_2x4x2RB, 	&helmholtz_per_thread_pl_0_2x4x4RB, 	&helmholtz_per_thread_pl_0_4x2x2RB, 	&helmholtz_per_thread_pl_0_4x2x4RB, 	&helmholtz_per_thread_pl_0_4x4x2RB, 	&helmholtz_per_thread_pl_0_4x4x4RB},
{	&helmholtz_per_thread_pl_32_2x2x2RB, 	&helmholtz_per_thread_pl_32_2x2x4RB, 	&helmholtz_per_thread_pl_32_2x2x8RB, 	&helmholtz_per_thread_pl_32_2x4x2RB, 	&helmholtz_per_thread_pl_32_2x4x4RB, 	&helmholtz_per_thread_pl_32_4x2x2RB, 	&helmholtz_per_thread_pl_32_4x2x4RB, 	&helmholtz_per_thread_pl_32_4x4x2RB, 	&helmholtz_per_thread_pl_32_4x4x4RB},
{	&helmholtz_per_thread_pl_64_2x2x2RB, 	&helmholtz_per_thread_pl_64_2x2x4RB, 	&helmholtz_per_thread_pl_64_2x2x8RB, 	&helmholtz_per_thread_pl_64_2x4x2RB, 	&helmholtz_per_thread_pl_64_2x4x4RB, 	&helmholtz_per_thread_pl_64_4x2x2RB, 	&helmholtz_per_thread_pl_64_4x2x4RB, 	&helmholtz_per_thread_pl_64_4x4x2RB, 	&helmholtz_per_thread_pl_64_4x4x4RB},
{	&helmholtz_per_thread_pl_128_2x2x2RB, 	&helmholtz_per_thread_pl_128_2x2x4RB, 	&helmholtz_per_thread_pl_128_2x2x8RB, 	&helmholtz_per_thread_pl_128_2x4x2RB, 	&helmholtz_per_thread_pl_128_2x4x4RB, 	&helmholtz_per_thread_pl_128_4x2x2RB, 	&helmholtz_per_thread_pl_128_4x2x4RB, 	&helmholtz_per_thread_pl_128_4x4x2RB, 	&helmholtz_per_thread_pl_128_4x4x4RB},
{	&helmholtz_per_thread_pl_256_2x2x2RB, 	&helmholtz_per_thread_pl_256_2x2x4RB, 	&helmholtz_per_thread_pl_256_2x2x8RB, 	&helmholtz_per_thread_pl_256_2x4x2RB, 	&helmholtz_per_thread_pl_256_2x4x4RB, 	&helmholtz_per_thread_pl_256_4x2x2RB, 	&helmholtz_per_thread_pl_256_4x2x4RB, 	&helmholtz_per_thread_pl_256_4x4x2RB, 	&helmholtz_per_thread_pl_256_4x4x4RB},
{	&helmholtz_per_thread_pl_512_2x2x2RB, 	&helmholtz_per_thread_pl_512_2x2x4RB, 	&helmholtz_per_thread_pl_512_2x2x8RB, 	&helmholtz_per_thread_pl_512_2x4x2RB, 	&helmholtz_per_thread_pl_512_2x4x4RB, 	&helmholtz_per_thread_pl_512_4x2x2RB, 	&helmholtz_per_thread_pl_512_4x2x4RB, 	&helmholtz_per_thread_pl_512_4x4x2RB, 	&helmholtz_per_thread_pl_512_4x4x4RB}
},
{{	&helmholtz_per_thread_pe_0_2x2x2RB, 	&helmholtz_per_thread_pe_0_2x2x4RB, 	&helmholtz_per_thread_pe_0_2x2x8RB, 	&helmholtz_per_thread_pe_0_2x4x2RB, 	&helmholtz_per_thread_pe_0_2x4x4RB, 	&helmholtz_per_thread_pe_0_4x2x2RB, 	&helmholtz_per_thread_pe_0_4x2x4RB, 	&helmholtz_per_thread_pe_0_4x4x2RB, 	&helmholtz_per_thread_pe_0_4x4x4RB},
{	&helmholtz_per_thread_pe_32_2x2x2RB, 	&helmholtz_per_thread_pe_32_2x2x4RB, 	&helmholtz_per_thread_pe_32_2x2x8RB, 	&helmholtz_per_thread_pe_32_2x4x2RB, 	&helmholtz_per_thread_pe_32_2x4x4RB, 	&helmholtz_per_thread_pe_32_4x2x2RB, 	&helmholtz_per_thread_pe_32_4x2x4RB, 	&helmholtz_per_thread_pe_32_4x4x2RB, 	&helmholtz_per_thread_pe_32_4x4x4RB},
{	&helmholtz_per_thread_pe_64_2x2x2RB, 	&helmholtz_per_thread_pe_64_2x2x4RB, 	&helmholtz_per_thread_pe_64_2x2x8RB, 	&helmholtz_per_thread_pe_64_2x4x2RB, 	&helmholtz_per_thread_pe_64_2x4x4RB, 	&helmholtz_per_thread_pe_64_4x2x2RB, 	&helmholtz_per_thread_pe_64_4x2x4RB, 	&helmholtz_per_thread_pe_64_4x4x2RB, 	&helmholtz_per_thread_pe_64_4x4x4RB},
{	&helmholtz_per_thread_pe_128_2x2x2RB, 	&helmholtz_per_thread_pe_128_2x2x4RB, 	&helmholtz_per_thread_pe_128_2x2x8RB, 	&helmholtz_per_thread_pe_128_2x4x2RB, 	&helmholtz_per_thread_pe_128_2x4x4RB, 	&helmholtz_per_thread_pe_128_4x2x2RB, 	&helmholtz_per_thread_pe_128_4x2x4RB, 	&helmholtz_per_thread_pe_128_4x4x2RB, 	&helmholtz_per_thread_pe_128_4x4x4RB},
{	&helmholtz_per_thread_pe_256_2x2x2RB, 	&helmholtz_per_thread_pe_256_2x2x4RB, 	&helmholtz_per_thread_pe_256_2x2x8RB, 	&helmholtz_per_thread_pe_256_2x4x2RB, 	&helmholtz_per_thread_pe_256_2x4x4RB, 	&helmholtz_per_thread_pe_256_4x2x2RB, 	&helmholtz_per_thread_pe_256_4x2x4RB, 	&helmholtz_per_thread_pe_256_4x4x2RB, 	&helmholtz_per_thread_pe_256_4x4x4RB},
{	&helmholtz_per_thread_pe_512_2x2x2RB, 	&helmholtz_per_thread_pe_512_2x2x4RB, 	&helmholtz_per_thread_pe_512_2x2x8RB, 	&helmholtz_per_thread_pe_512_2x4x2RB, 	&helmholtz_per_thread_pe_512_2x4x4RB, 	&helmholtz_per_thread_pe_512_4x2x2RB, 	&helmholtz_per_thread_pe_512_4x2x4RB, 	&helmholtz_per_thread_pe_512_4x4x2RB, 	&helmholtz_per_thread_pe_512_4x4x4RB}
}
};
