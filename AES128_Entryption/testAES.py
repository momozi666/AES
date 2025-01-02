from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

# 验证AES加密算法verilog代码的正确性

# 定义密钥和明文
key = bytes.fromhex('0123456789ABCDEF0123456789ABCDEF')
plaintext = bytes.fromhex('d7e5dbd3324595f8fdc7d7c571da6c2a')
#525a0bb6f6626e941a81cd7b5fe8b620
# 创建AES加密器
cipher = AES.new(key, AES.MODE_ECB)

# 加密
ciphertext = cipher.encrypt(plaintext)
print("Ciphertext:", ciphertext.hex())

# 解密
decrypted = cipher.decrypt(ciphertext)
print("Decrypted:", decrypted.hex())