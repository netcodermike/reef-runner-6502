"""Assemble the original Reef Runner 6502 NROM cartridge with cc65."""

from argparse import ArgumentParser
from pathlib import Path
from shutil import which
from struct import unpack_from
from subprocess import CalledProcessError, run
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parent
CHR = ROOT / 'assets/reef-runner.chr'
ROM = ROOT / 'web/reef-runner.nes'
PRG_SIZE = 16 * 1024
CHR_SIZE = 8 * 1024
# iNES: one PRG bank, one CHR bank, mapper 0, horizontal mirroring.
HEADER = b'NES\x1a\x01\x01' + bytes(10)


def assemble(ca65, ld65, build_dir):
    cartridge = build_dir / 'cartridge.s'
    header = ', '.join(f'${byte:02X}' for byte in HEADER)
    cartridge.write_text(
        f'.segment "HEADER"\n.byte {header}\n'
        f'.segment "CHR"\n.incbin "{CHR.relative_to(ROOT).as_posix()}"\n',
        encoding='ascii',
    )
    program_object = build_dir / 'game.o'
    cartridge_object = build_dir / 'cartridge.o'
    output = build_dir / ROM.name
    for source, target in [(ROOT / 'src/game.s', program_object), (cartridge, cartridge_object)]:
        run([ca65, '--cpu', '6502', '--bin-include-dir', str(ROOT), '-o', str(target), str(source)],
            cwd=ROOT, check=True)
    labels = build_dir / 'reef-runner.lbl'
    run([ld65, '-C', str(ROOT / 'nes.cfg'), '-o', str(output), '-Ln', str(labels),
         str(cartridge_object), str(program_object)],
        cwd=ROOT, check=True)
    return output, labels


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--tools', type=Path, help='directory containing ca65 and ld65, if the tools are outside PATH')
    parser.add_argument('--check', action='store_true', help='verify that the current sources reproduce the checked-in ROM')
    parser.add_argument('--labels', type=Path, help='also write ld65 debug labels for the emulator playthrough test')
    args = parser.parse_args()

    tool_path = str(args.tools.resolve()) if args.tools else None
    ca65 = which('ca65', path=tool_path)
    ld65 = which('ld65', path=tool_path)
    if not ca65 or not ld65:
        parser.error('Install cc65, then add its bin directory to PATH or pass --tools.')
    if not CHR.is_file() or CHR.stat().st_size != CHR_SIZE:
        parser.error('Build the 8 KiB graphics bank first with python assets/generate_chr.py.')
    if args.labels and args.labels.resolve() == ROM:
        parser.error('Choose a separate file for the debug labels.')

    ROM.parent.mkdir(exist_ok=True)
    try:
        with TemporaryDirectory(prefix='.reef-build-', dir=ROM.parent) as temporary:
            output, labels = assemble(ca65, ld65, Path(temporary))
            data = output.read_bytes()
            prg_end = len(HEADER) + PRG_SIZE
            if (len(data) != prg_end + CHR_SIZE or data[:len(HEADER)] != HEADER
                    or data[prg_end:] != CHR.read_bytes()):
                raise ValueError('Incorrect iNES header, PRG size, or CHR bank.')
            for pointer in unpack_from('<HHH', data, prg_end - 6):
                if not 0xC000 <= pointer < 0xFFFA:
                    raise ValueError(f'Invalid interrupt vector ${pointer:04X}.')
            if args.check:
                if not ROM.is_file() or ROM.read_bytes() != data:
                    raise ValueError('The checked-in ROM is stale. Run python build.py to update it.')
            else:
                output.replace(ROM)
            if args.labels:
                args.labels.write_bytes(labels.read_bytes())
    except CalledProcessError as error:
        return error.returncode
    except (OSError, ValueError) as error:
        parser.exit(1, f'Build failed: {error}\n')

    action = 'Verified' if args.check else 'Built'
    print(f'{action} {ROM.relative_to(ROOT).as_posix()} ({len(data)} bytes)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
