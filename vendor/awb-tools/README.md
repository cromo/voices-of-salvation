# AWB Tools

These are tools for dealing with AWB pack files from https://steamcommunity.com/sharedfiles/filedetails/?id=632355452 .

## What's Included

- `ADX2WAV.EXE` - A tool for converting ADX audio files to WAV
- `AWB_repacker.c` - The source for `AWB_repacker`
- `AWB_repacker.exe` - A tool that will pack BIN files into an AWB pack
- `AWB_unpacker.c` - The source for `AWB_unpacker`
- `AWB_unpacker.exe` - A tool that unpacks AWB files into BIN files
- `WAV2ADX.EXE` - A tool for converting WAV audio files to ADX

## Usage

### ADX Converters

```
ADX2WAV <infile> <outfile>
```

It appears that if using relative paths, the leading `.\` must be included.

```
WAV2ADX <Input PCM File> [Output Dir] [Options]
```

### AWB Packers

```
AWB_unpacker <files> ...
```

This will create a directory named `<file>_extracted_files` and dump raw BIN files from that AWB pack in it.

```
AWB_repacker <files> ...
```

## Licence

None of these tools appear to have proper licenses, so here are the credits
instead:

- `ADX2WAV` and `WAV2ADX` appear to be written by berobero, who had [a GeoCities JP site](http://www.geocities.co.jp/Playtown/2004/)([archive](https://web.archive.org/web/20190331142215/http://www.geocities.co.jp/Playtown/2004/)).
- `AWB_repacker` and `AWB_unpacker` appear to be written by Somnides who released them in [a Steam Community guide](https://steamcommunity.com/sharedfiles/filedetails/?id=632355452).