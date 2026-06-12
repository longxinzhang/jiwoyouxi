#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const ROOT_DIR = path.resolve(new URL('..', import.meta.url).pathname);
const FRUIT_DIR = path.join(ROOT_DIR, 'entry/src/main/resources/rawfile/games/suika/fruits');
const PREVIEW_DIR = path.join(FRUIT_DIR, 'preview');
const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const EDGE_ALPHA_THRESHOLD = 16;
const BLEED_RADIUS = 10;

const crcTable = new Uint32Array(256);
for (let i = 0; i < 256; i += 1) {
  let value = i;
  for (let bit = 0; bit < 8; bit += 1) {
    value = (value & 1) !== 0 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
  }
  crcTable[i] = value >>> 0;
}

function crc32(buffer) {
  let crc = 0xffffffff;
  for (let i = 0; i < buffer.length; i += 1) {
    crc = crcTable[(crc ^ buffer[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function readChunk(buffer, offset) {
  const length = buffer.readUInt32BE(offset);
  const type = buffer.toString('ascii', offset + 4, offset + 8);
  const dataStart = offset + 8;
  const dataEnd = dataStart + length;
  return {
    type,
    data: buffer.subarray(dataStart, dataEnd),
    nextOffset: dataEnd + 4
  };
}

function parsePng(filePath) {
  const fileBuffer = fs.readFileSync(filePath);
  if (!fileBuffer.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
    throw new Error(`${filePath} is not a PNG file`);
  }

  let offset = PNG_SIGNATURE.length;
  let width = 0;
  let height = 0;
  let bitDepth = 0;
  let colorType = 0;
  let interlace = 0;
  const idatChunks = [];

  while (offset < fileBuffer.length) {
    const chunk = readChunk(fileBuffer, offset);
    offset = chunk.nextOffset;
    if (chunk.type === 'IHDR') {
      width = chunk.data.readUInt32BE(0);
      height = chunk.data.readUInt32BE(4);
      bitDepth = chunk.data[8];
      colorType = chunk.data[9];
      interlace = chunk.data[12];
    } else if (chunk.type === 'IDAT') {
      idatChunks.push(chunk.data);
    } else if (chunk.type === 'IEND') {
      break;
    }
  }

  if (bitDepth !== 8 || colorType !== 6 || interlace !== 0) {
    throw new Error(`${filePath} must be 8-bit non-interlaced RGBA PNG`);
  }

  const inflated = zlib.inflateSync(Buffer.concat(idatChunks));
  const pixels = unfilterRgba(inflated, width, height);
  return { width, height, pixels };
}

function paethPredictor(left, up, upLeft) {
  const estimate = left + up - upLeft;
  const leftDistance = Math.abs(estimate - left);
  const upDistance = Math.abs(estimate - up);
  const upLeftDistance = Math.abs(estimate - upLeft);
  if (leftDistance <= upDistance && leftDistance <= upLeftDistance) {
    return left;
  }
  if (upDistance <= upLeftDistance) {
    return up;
  }
  return upLeft;
}

function unfilterRgba(inflated, width, height) {
  const bytesPerPixel = 4;
  const stride = width * bytesPerPixel;
  const pixels = Buffer.alloc(width * height * bytesPerPixel);
  let sourceOffset = 0;

  for (let y = 0; y < height; y += 1) {
    const filter = inflated[sourceOffset];
    sourceOffset += 1;
    const rowStart = y * stride;
    const prevRowStart = rowStart - stride;

    for (let x = 0; x < stride; x += 1) {
      const raw = inflated[sourceOffset + x];
      const left = x >= bytesPerPixel ? pixels[rowStart + x - bytesPerPixel] : 0;
      const up = y > 0 ? pixels[prevRowStart + x] : 0;
      const upLeft = y > 0 && x >= bytesPerPixel ? pixels[prevRowStart + x - bytesPerPixel] : 0;
      let value = raw;

      if (filter === 1) {
        value = raw + left;
      } else if (filter === 2) {
        value = raw + up;
      } else if (filter === 3) {
        value = raw + Math.floor((left + up) / 2);
      } else if (filter === 4) {
        value = raw + paethPredictor(left, up, upLeft);
      } else if (filter !== 0) {
        throw new Error(`Unsupported PNG filter: ${filter}`);
      }

      pixels[rowStart + x] = value & 0xff;
    }
    sourceOffset += stride;
  }

  return pixels;
}

function bleedTransparentEdges(pixels, width, height) {
  const totalPixels = width * height;
  const original = Buffer.from(pixels);
  let colors = Buffer.from(pixels);
  let hasColor = new Uint8Array(totalPixels);

  for (let i = 0; i < totalPixels; i += 1) {
    if (original[i * 4 + 3] >= EDGE_ALPHA_THRESHOLD) {
      hasColor[i] = 1;
    }
  }

  for (let pass = 0; pass < BLEED_RADIUS; pass += 1) {
    const nextColors = Buffer.from(colors);
    const nextHasColor = new Uint8Array(hasColor);
    let changed = false;

    for (let y = 0; y < height; y += 1) {
      for (let x = 0; x < width; x += 1) {
        const index = y * width + x;
        if (hasColor[index] !== 0) {
          continue;
        }

        let red = 0;
        let green = 0;
        let blue = 0;
        let count = 0;

        for (let dy = -1; dy <= 1; dy += 1) {
          for (let dx = -1; dx <= 1; dx += 1) {
            if (dx === 0 && dy === 0) {
              continue;
            }
            const nx = x + dx;
            const ny = y + dy;
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
              continue;
            }
            const neighborIndex = ny * width + nx;
            if (hasColor[neighborIndex] === 0) {
              continue;
            }
            const pixelOffset = neighborIndex * 4;
            red += colors[pixelOffset];
            green += colors[pixelOffset + 1];
            blue += colors[pixelOffset + 2];
            count += 1;
          }
        }

        if (count > 0) {
          const offset = index * 4;
          nextColors[offset] = Math.round(red / count);
          nextColors[offset + 1] = Math.round(green / count);
          nextColors[offset + 2] = Math.round(blue / count);
          nextHasColor[index] = 1;
          changed = true;
        }
      }
    }

    colors = nextColors;
    hasColor = nextHasColor;
    if (!changed) {
      break;
    }
  }

  const output = Buffer.from(original);
  for (let i = 0; i < totalPixels; i += 1) {
    const offset = i * 4;
    if (original[offset + 3] < 255 && hasColor[i] !== 0) {
      output[offset] = colors[offset];
      output[offset + 1] = colors[offset + 1];
      output[offset + 2] = colors[offset + 2];
    }
  }
  return output;
}

function createChunk(type, data) {
  const typeBuffer = Buffer.from(type, 'ascii');
  const lengthBuffer = Buffer.alloc(4);
  lengthBuffer.writeUInt32BE(data.length, 0);
  const crcBuffer = Buffer.alloc(4);
  crcBuffer.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 0);
  return Buffer.concat([lengthBuffer, typeBuffer, data, crcBuffer]);
}

function encodePng(width, height, pixels) {
  const bytesPerPixel = 4;
  const stride = width * bytesPerPixel;
  const scanlines = Buffer.alloc((stride + 1) * height);

  for (let y = 0; y < height; y += 1) {
    const scanlineOffset = y * (stride + 1);
    scanlines[scanlineOffset] = 0;
    pixels.copy(scanlines, scanlineOffset + 1, y * stride, y * stride + stride);
  }

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  return Buffer.concat([
    PNG_SIGNATURE,
    createChunk('IHDR', ihdr),
    createChunk('IDAT', zlib.deflateSync(scanlines, { level: 9 })),
    createChunk('IEND', Buffer.alloc(0))
  ]);
}

function previewName(fileName) {
  return fileName.replace(/\.png$/u, '_preview.png');
}

function main() {
  fs.mkdirSync(PREVIEW_DIR, { recursive: true });
  const files = fs.readdirSync(FRUIT_DIR)
    .filter((fileName) => /^fruit_\d{2}_.+\.png$/u.test(fileName))
    .sort();

  if (files.length === 0) {
    throw new Error(`No fruit PNG files found in ${FRUIT_DIR}`);
  }

  for (const fileName of files) {
    const sourcePath = path.join(FRUIT_DIR, fileName);
    const targetPath = path.join(PREVIEW_DIR, previewName(fileName));
    const png = parsePng(sourcePath);
    const outputPixels = bleedTransparentEdges(png.pixels, png.width, png.height);
    fs.writeFileSync(targetPath, encodePng(png.width, png.height, outputPixels));
    console.log(`Generated ${path.relative(ROOT_DIR, targetPath)}`);
  }
}

main();
