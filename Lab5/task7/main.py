s = 'plain text'
enc = ''
dec = ''
k = 3

for c in s:
    if c.isalpha():
        enc += chr(((ord(c) + k - ord('a')) % 26) + ord('a'))
    else:
        enc += c

print(s)
print(enc)

s = 'subho snaw'
for c in s:
    if c.isalpha():
        dec += chr(((ord(c) - k - ord('a') + 26) % 26) + ord('a'))
    else:
        dec += c
print(dec)
