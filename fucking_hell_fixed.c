/* Exynos SSS hardware hash/HMAC engine. Reverse-engineering inspiration       */
/* from halal-beef fucking_hell.c					       */
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

/* MMIO accessors provided by the EL3 runtime. */
extern uint32_t readl(unsigned long addr);
extern void     writel(uint32_t val, unsigned long addr);

#define KEY_TOO_FAT   0x3700
#define HASH_TIMEOUT  0x3701

#define BUS1_BASE 0x1A400000
#define CRYPTO_ENGINE_BASE (BUS1_BASE + 0x120000)

#define KEY_PRESENT (1 << 0)

/* Busy-wait bound so a stalled engine can't hang EL3 forever. */
#define HASH_SPIN_MAX 1000000u

/* SHA-384 shares the SHA-512 datapath; it is only distinguished by the SHA-384
 * initial values, selected by BIT(6) at offset 0x2C, plus a 48-byte output. */
#define SHA384_VARIANT_SEL (1 << 6)

enum hash_algo
{
    SHA1,
    SHA256,
    SHA512,
    SHA384,
    SHA224
};

int do_hw_crypto(void *dst, long addr, uint32_t size, void *opt_key, uint32_t key_len, enum hash_algo hash_algo)
{
	bool key_present = opt_key != 0;
	uint32_t key_buf[32];
	uint32_t algo_value = 0;
	uint32_t result_size = 0;
	uint32_t spin;

	if (key_len > 128 && key_present)
		return KEY_TOO_FAT;

	writel((1 << 10), CRYPTO_ENGINE_BASE + 0x0184);

	if((readl(CRYPTO_ENGINE_BASE + 0x018C) >> 10) & 1)
		writel((1 << 10), CRYPTO_ENGINE_BASE + 0x018C);

	if((readl(CRYPTO_ENGINE_BASE + 0x1010) >> 6) & 1)
		writel((1 << 6), CRYPTO_ENGINE_BASE + 0x1010);

	writel(0xF, CRYPTO_ENGINE_BASE + 0x100C);
	writel(readl(CRYPTO_ENGINE_BASE + 0x0014) & 0xFFFFFFFC, CRYPTO_ENGINE_BASE + 0x0014);

	/* Clear the SHA-384 variant selector so a stale bit from a previous call
	 * can't leak into SHA-1/256/512; set it again below only for SHA-384. */
	writel(0, CRYPTO_ENGINE_BASE + 0x002C);

	if(key_present)
	{
		/* Copy the whole key (any length, not just full words) then zero-pad
		 * to the 128-byte block. The old whole-word loop left 1-3 tail bytes
		 * uninitialised for non-word-aligned keys. */
		memcpy(key_buf, opt_key, key_len);
		memset((uint8_t *)key_buf + key_len, 0, 128 - key_len);

		for (int i = 0; i < 32; i++)
			writel(key_buf[i], (CRYPTO_ENGINE_BASE + 0x1100 + i * 4));

		memset((uint8_t *)key_buf, 0, 128);
	}

	switch(hash_algo)
	{
		case SHA1:
			algo_value = 0x10;
			break;
		case SHA256:
			algo_value = 0x14;
			break;
		case SHA512:
			algo_value = 0x1A;
			break;
		case SHA384:
			/* SHA-384 = SHA-512 mode + the 384-IV variant bit. */
			algo_value = 0x1A;
			writel(SHA384_VARIANT_SEL, CRYPTO_ENGINE_BASE + 0x002C);
			break;
		case SHA224:
			/* SHA-224 = SHA-256 datapath + a 224-IV variant. Its selector
			 * bit is UNKNOWN (the RE reference only documented 0x2C BIT(6)
			 * for SHA-384). As written this runs with the SHA-256 IV, so the
			 * output is NOT valid SHA-224 yet — find the 224 select bit (try
			 * the neighbouring bits of 0x2C) and set it here. */
			algo_value = 0x14;
			/* writel(SHA224_VARIANT_SEL, CRYPTO_ENGINE_BASE + 0x002C);  <-- TODO */
			break;
	}

	if(key_present)
		algo_value |= KEY_PRESENT;

	writel(1, CRYPTO_ENGINE_BASE + 0x1008);
	writel(size, CRYPTO_ENGINE_BASE + 0x1020);
	writel(0, CRYPTO_ENGINE_BASE + 0x1024);
	writel(0, CRYPTO_ENGINE_BASE + 0x1030);
	writel(0, CRYPTO_ENGINE_BASE + 0x1034);

	writel(algo_value, CRYPTO_ENGINE_BASE + 0x1000);

	writel((uint32_t)addr, CRYPTO_ENGINE_BASE + 0x0044);
	writel((uint32_t)(addr >> 32), CRYPTO_ENGINE_BASE + 0x0040);
	writel(size, CRYPTO_ENGINE_BASE + 0x0048);

	spin = HASH_SPIN_MAX;
	while(!((readl(CRYPTO_ENGINE_BASE + 0x0180) >> 10) & 1))
		if(!--spin)
			return HASH_TIMEOUT;
	writel((1 << 10), CRYPTO_ENGINE_BASE + 0x018C);

	spin = HASH_SPIN_MAX;
	while(!((readl(CRYPTO_ENGINE_BASE + 0x1010) >> 6) & 1))
		if(!--spin)
			return HASH_TIMEOUT;
	writel((1 << 6), CRYPTO_ENGINE_BASE + 0x1010);

	switch(hash_algo)
	{
		case SHA1:
			result_size = 20;   /* SHA-1 is 160 bits = 20 bytes (was 16) */
			break;
		case SHA224:
			result_size = 28;   /* 224 bits (see SHA-224 caveat above) */
			break;
		case SHA256:
			result_size = 32;
			break;
		case SHA384:
			result_size = 48;   /* 384 bits */
			break;
		case SHA512:
			result_size = 64;
			break;
	}

	/* Store the digest into the plain memory buffer. Use a real store, not
	 * writel() with a 32-bit-truncated pointer: under EL3 (aarch64) dst may
	 * live above 4 GB. */
	for (uint32_t i = 0; i < result_size; i += 4)
		*(uint32_t *)((uint8_t *)dst + i) = readl(CRYPTO_ENGINE_BASE + 0x11C0 + i);

	if (key_present)
		for (int i = 0; i < 128; i += 4)
			writel(0, CRYPTO_ENGINE_BASE + 0x1100 + i);

	return 0;
}
