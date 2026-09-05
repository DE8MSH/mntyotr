#!/usr/bin/env python3
"""Convert authentic C64 enemy sprite blocks needed by Rooms $00-$08.

C64 UnpackSpriteGraphics deinterleaves each 32-byte source chunk into one
64-byte VIC sprite frame. Types with four source frames are duplicated into
the opposite-direction group exactly like the original enemy_copy_flag path.
Every generated PCE file therefore contains eight 512-byte frames (4096 bytes).
"""
from pathlib import Path
from monty_sprite import convert_frame

SKATE = bytes.fromhex(
"0003070f0f2f2f3700c0e0f0f0f4f4ec3b3c7f78c10a5000dc3cfe0e432805"
"0003070c3a3f0f253bc0e0f0f0f0f4ecdc3c7f7ff005a800003cfefe0f502500"
"000003070d090f2d3600c0e0d090f0b46c3b3c7fff00550000dc3cfeff005500"
"00000003070f0f0f2f0000c02050fcfcf0273b7c7ff005a800acdc3efe0f502500")
LAMP = bytes.fromhex(
"071c3b393c3f1f03e0f07878f8f8f0e0000000000000001f00408040804080e0"
"071f38393c3f1f03e0f07878f8f8f0e0000000000000000720404030083040f8"
"071f3f383c3f1f03e0f0f878f8f8f0e0000000000000010e60c020300c788000"
"071f38393c3f1f03e0f07878f8f8f0e000000000011f00006080408000e00000"
"070f1e1e1f1f0f07e038dc9c3cfcf8c0000201020102010700000000000000f8"
"070f1e1e1f1f0f07e0f81c9c3cfcf8c00402020c100c021f00000000000000e0"
"070f1f1e1f1f0f07e0f8fc1c3cfcf8c00603040c301e01000000000000008070"
"070f1e1e1f1f0f07e0f81c9c3cfcf8c006010201000700000000000080f80000")
KNIGHT = bytes.fromhex(
"213317070f0f0f3084cce8e0f0f0f0086fdddadd6fa300f8f65abd5dc0df1f1f"
"213317070f0f0f3084cce8e0f0f0f00cefdddadd5f03f8f8f65bbb5bfac01f1f"
"213317070f0f0f1084cce8e0f0f0f00c6f5abdba03fbf8f8f6bb5bbbf6c5001f"
"213317070f0f0f3084cce8e0f0f0f00cefdddadd5f03f8f8f65bbb5bfac01f1f"
"213317040c0f0f1684cce8a0b0f0f06c695fbebd02faf9f896fb7bbb5655801f"
"213317050d0f0f3684cce82030f0f06c69dfdedd5a02f9f897fb7bbb5a409f1f"
"213317060e0f0f3684cce82030f0f06869dfdedd6aaa01f896fa7dbd405f9f1f"
"213317040c0f0f3684cce86070f0f06c69dfdedd5a02f9f897fb7bbb5a409f1f")
CLOCK = bytes.fromhex(
"00fc330e19362f6f003fcc70186c74765e566d37190e0300ea7af66c9a76c400"
"c07c330e19362f6f033ecc70186c74765e566d37190e0300ea7af66c9a76c400"
"00fc330e19362f6f003fcc70186c74765e566d37190e0300ea7af66c9a76c400"
"001c73ce19362f6f0038ce73186c74765e566d37190e0300ea7af66c9a76c400")
BIG_NOSE = bytes.fromhex(
"00000001073e7fff18649616acdc7c7cfef8700000050b0b78f834e8140cbcfc"
"000000010f7effff18648616acdc7c7cfe7000000001020278f834ea1646eef8"
"00000000033f7f7f0c324383d66ebebe7f3e000002050500bc7c1a748adefe"
"0000000000031f3f7f0c324383c66ebebe7f7c3800000a17173c7c18740c1478f8"
"18266968353b3e3e00000080e07cfeff1e1f2c1728303d3f7f1f0e0000a0d0d0"
"18266168353b3e3e00000080f07effff1e1f2c576862771f7f0e000000804040"
"304cc2c16b767d7d00000000c0fcfefe3d3e582e517b7f00fe7c000040a0a0"
"00304cc2c163767d7d00000000c0f8fcfe3c3e182e30281e1ffe3e1c000050e8e8")
RUBIK = bytes.fromhex(
"030f304e324c732c00c0304830c810a87d6a5e340e0200005088502000000000"
"030f304c304c732c00c0308830c810a87d6a5e340e0200005088502000000000"
"030f3042304c732c00c030c830c810a87d6a5e340e0200005088502000000000"
"030f3049304c732c00c0304830c810a87d6a5e340e0200005088502000000000")
PI_PIE = bytes.fromhex(
"030f1c3a3e7d7f00c0f018bcbcdefe00ffff007f7f3f3f00f9f900e2e6ccdc00"
"00030f1c3a3e7d0000c0f018bcbcde00ffff007f7f3f3f00f9f900e2e6ccdc00"
"0000030f1c3a3e000000c0f018bcbc00ffff007f7f3f3f00f9f900e2e6ccdc00"
"00030f1c3a3e7d0000c0f018bcbcde00ffff007f7f3f3f00f9f900e2e6ccdc00")
WASP = bytes.fromhex(
"0c060602020202013060604040404080040b150b57cf83a120d0a8d0eaf3c185"
"0000701c0c06020100000e3830604080040b150b57cf83a120d0a8d0eaf3c185"
"0000000070fc0601000000000e3f6080040b150b57cf83a120d0a8d0eaf3c185"
"0000701c0c06020100000e3830604080040b150b57cf83a120d0a8d0eaf3c185")
BUBBLE = bytes.fromhex(
"000000073f7fffdf000000e0fcc6f3fbdfcf633f07000000fbfffefce0000000"
"00071f3f7f7fffff0080e0b098c8ececdfdf4f67371f0700fcfcf8f8f0e08000"
"03070f0f0f1f1f1fc0e03090d0d8d8f81f1b1b0b090c0703f8f8f8f0f0f0e0c0"
"00071f3f7f7fffff0080e0b098c8ececdfdf4f67371f0700fcfcf8f8f0e08000")
SAD_GHOST = bytes.fromhex(
"0f3f7f7fdfa0b2c780e0f0f8d82c6c1cfff87060effff760fcfc3e3e9efffb99"
"0f3f7f7fdfa0b2c780e0f0f8f80c6c1cfff87067effff160fcfc3ebedeff7b19"
"0f3f7f7fff80b2c780e0f0f8f86c0c1cfff8776ffffaf060fcfc3ebedeff7b19"
"0f3f7f7fff80b2c780e0f0f8f80c6c1cfff8706feffff160fcfc3e3edeff7b19")
KETTLE = bytes.fromhex(
"08a101000107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"40a141804107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"c82911200107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"a419a1000107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"00030201030dc0f51085800080e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0"
"00030201030dc0f50285820182e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0"
"00030201030dc0f51394880480e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0"
"00030201030dc0f52598850080e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0")
SMILEY = bytes.fromhex(
"01070c1b383a7ccfc0f0986c0e4f1ff1b3acce4666223c07cb1ae6c4cc9830e0"
"01070c18383a7ccfc0f0980c0e4f1ff1b3acce66381f0703cb1ae6c41cf8f0c0"
"01070c1838387ccfc0f0980c0e0f1ff1f3fcff7f3f1f0703cf1efefcfcf8f0c0"
"01070c18383a7ccfc0f0980c0e4f1ff1b3acce66381f0703cb1ae6c41cf8f0c0")
HAND = bytes.fromhex(
"0119191d0c0ccec7809898dbdbdbd7f6ef777c7f3f3f1f07fefcfc7cb8b8f0e0"
"000001191804cec70000809858c3dbf4ef777c7f3f3f1f07fefefc7cb8b8f0e0"
"00000101191dccc300008098989a5bc7ef777c7f3f3f1f07f6f8fc7cb8b8f0e0"
"000000001b5bdbc30000000000207060d86f797e3f3f1f076c1cd8e07070e0c0"
"071f3f3f7f7c77efe0f0b8b87cfcfcfec7ce0c0c1d191901f6d7dbdbdb989880"
"071f3f3f7f7c77efe0f0b8b87cfcfefec7ce041819010000f4dbc35898800000"
"071f3f3f7f7c77efe0f0b8b87cfcf8f6c3cc1d1901010000c75b9a9898800000"
"071f3f3f7e796fd8c0e07070e0d81c6cc3db5b1b000000006070200000000000")
TANK = bytes.fromhex(
"003c4fb79bab837f000080c0f0f8fcfe00ffffc0155c401900ffff038000019900"
"3c4f879bab837f000080c0f0f8fcfe00ffffc01d01404c00ffff03b88101cc00"
"3c4fb783ab837f000080c0f0f8fcfe00ffffc00100006600ffff03a839006600"
"3c4fb7b3bb837f000080c0f0f8fcfe00ffffc01c40003300ffff033800003300"
"0001030f1f3f7f003cf2edd9d5c1fe00ffffc00100809900ffff03a83a029800"
"0001030f1f3f7f003cf2e1d9d5c1fe00ffffc01d81803300ffff03b880023200"
"0001030f1f3f7f003cf2edc1d5c1fe00ffffc0159c006600ffff038000006600"
"0001030f1f3f7f003cf2edcdddc1fe00ffffc01c0000cc00ffff03380200cc")
JELLY_FISH = bytes.fromhex(
"000e3b301337ef8c00f0980cc4e67273ce6e272330101f1931f3e2c604745cc0"
"705e632023276ecce0b09f01c3e272338cee373320605e733171e1c3327654dc"
"735aceec23e78e8ec040701cc6e2f233cc4f6723e086ce7b7177e4c437f19b8e"
"01fb8ee023674fcec070161ec2e3f1718eef272360406e3b71f3e2c634f49c80")


def deinterleave(src: bytes) -> bytes:
    assert len(src) == 32
    out = bytearray(64)
    y = 0
    for x in range(8):
        out[y] = src[x]
        out[y + 1] = src[8 + x]
        y += 3
    for x in range(8):
        out[y] = src[16 + x]
        out[y + 1] = src[24 + x]
        y += 3
    return bytes(out)


def build8(blob: bytes) -> bytes:
    assert len(blob) in (128, 256)
    frames = [deinterleave(blob[i:i + 32]) for i in range(0, len(blob), 32)]
    if len(frames) == 4:
        frames += frames
    assert len(frames) == 8
    out = b''.join(convert_frame(frame) for frame in frames)
    assert len(out) == 4096
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser()
    specs = (
        ('skate', SKATE), ('lamp', LAMP), ('knight', KNIGHT), ('clock', CLOCK),
        ('big-nose', BIG_NOSE), ('rubik', RUBIK), ('pi-pie', PI_PIE),
        ('wasp', WASP), ('bubble', BUBBLE), ('sad-ghost', SAD_GHOST),
        ('kettle', KETTLE), ('smiley', SMILEY), ('hand', HAND), ('tank', TANK),
        ('jelly-fish', JELLY_FISH),
    )
    for name, _ in specs:
        ap.add_argument('--' + name, type=Path, required=True)
    a = ap.parse_args()
    for name, blob in specs:
        path = getattr(a, name.replace('-', '_'))
        path.write_bytes(build8(blob))
    print('Rooms00-08 enemies: 15 authentic C64 types -> 15 x 8 PCE frames')


if __name__ == '__main__':
    main()
