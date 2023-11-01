# htons() function translates a short integer from host byte order to network byte order

# instead of implementing it to asm, we can manually calculate

port = 6969
print("port", port)
hex_representation = hex(port)
print("hex_representation", hex_representation)
hex_data = hex_representation.split("0x")[1]
inverse_hex = "0x" + hex_data[2] + hex_data[3] + hex_data[0] + hex_data[1]
print("inverse_hex", inverse_hex)
inversed_port = int(inverse_hex, 0)
print("inversed_port", inversed_port)
