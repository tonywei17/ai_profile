import crypto from "crypto";
import fs from "fs";
import path from "path";
import { config } from "../config";

const XMP_HEADER = "http://ns.adobe.com/xap/1.0/\0";
const PNG_SIGNATURE = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
]);
const CONTENT_PRODUCER = "羽飞科技(广西)有限责任公司";
const exportLogPath = path.join(
  path.dirname(config.paymentDataPath),
  "aigc-export.log"
);

interface AigcMetadata {
  Label: "1";
  ContentProducer: string;
  ProduceID: string;
  ReservedCode1: string;
  ContentPropagator: string;
  PropagateID: string;
  ReservedCode2: string;
}

function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function createXmp(metadata: AigcMetadata): Buffer {
  const json = escapeXml(JSON.stringify(metadata));
  return Buffer.from(
    `<?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>` +
      `<x:xmpmeta xmlns:x="adobe:ns:meta/">` +
      `<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">` +
      `<rdf:Description rdf:about="" xmlns:aigc="http://cvdca.org.cn/ns/aigc/1.0/">` +
      `<aigc:Info>${json}</aigc:Info>` +
      `</rdf:Description></rdf:RDF></x:xmpmeta>` +
      `<?xpacket end="w"?>`,
    "utf8"
  );
}

function addJpegXmp(image: Buffer, xmp: Buffer): Buffer {
  const payload = Buffer.concat([Buffer.from(XMP_HEADER, "ascii"), xmp]);
  const segmentLength = payload.length + 2;
  if (segmentLength > 0xffff) {
    throw new Error("AIGC XMP metadata is too large for JPEG APP1");
  }
  const app1 = Buffer.alloc(payload.length + 4);
  app1[0] = 0xff;
  app1[1] = 0xe1;
  app1.writeUInt16BE(segmentLength, 2);
  payload.copy(app1, 4);
  return Buffer.concat([image.subarray(0, 2), app1, image.subarray(2)]);
}

let crcTable: number[] | null = null;

function getCrcTable(): number[] {
  if (crcTable) {
    return crcTable;
  }
  crcTable = Array.from({ length: 256 }, (_, index) => {
    let value = index;
    for (let bit = 0; bit < 8; bit += 1) {
      value = (value & 1) !== 0 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
    }
    return value >>> 0;
  });
  return crcTable;
}

function crc32(buffer: Buffer): number {
  let crc = 0xffffffff;
  const table = getCrcTable();
  for (const byte of buffer) {
    crc = table[(crc ^ byte) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function createPngChunk(type: string, data: Buffer): Buffer {
  const typeBuffer = Buffer.from(type, "ascii");
  const chunk = Buffer.alloc(data.length + 12);
  chunk.writeUInt32BE(data.length, 0);
  typeBuffer.copy(chunk, 4);
  data.copy(chunk, 8);
  chunk.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), data.length + 8);
  return chunk;
}

function addPngXmp(image: Buffer, xmp: Buffer): Buffer {
  const keyword = Buffer.from("XML:com.adobe.xmp\0", "ascii");
  const iTxtData = Buffer.concat([
    keyword,
    Buffer.from([0, 0, 0, 0, 0]),
    xmp,
  ]);
  const iTxtChunk = createPngChunk("iTXt", iTxtData);
  const firstChunkLength = image.readUInt32BE(PNG_SIGNATURE.length);
  const firstChunkEnd = PNG_SIGNATURE.length + 12 + firstChunkLength;
  if (
    image
      .subarray(PNG_SIGNATURE.length + 4, PNG_SIGNATURE.length + 8)
      .toString("ascii") !== "IHDR"
  ) {
    throw new Error("Invalid PNG: IHDR must be the first chunk");
  }
  return Buffer.concat([
    image.subarray(0, firstChunkEnd),
    iTxtChunk,
    image.subarray(firstChunkEnd),
  ]);
}

function appendAuditLog(record: Record<string, unknown>): void {
  fs.mkdirSync(path.dirname(exportLogPath), { recursive: true });
  fs.appendFileSync(
    exportLogPath,
    `${JSON.stringify({ timestamp: new Date().toISOString(), ...record })}\n`,
    { encoding: "utf8", mode: 0o600 }
  );
}

export function labelGeneratedImage(
  imageBase64: string,
  provider: string,
  userId?: string
): { image: string; produceId: string } {
  const produceId = crypto.randomUUID();
  const metadata: AigcMetadata = {
    Label: "1",
    ContentProducer: CONTENT_PRODUCER,
    ProduceID: produceId,
    ReservedCode1: "",
    ContentPropagator: "",
    PropagateID: "",
    ReservedCode2: "",
  };
  const image = Buffer.from(imageBase64, "base64");
  const xmp = createXmp(metadata);
  let labeled: Buffer;
  if (image[0] === 0xff && image[1] === 0xd8) {
    labeled = addJpegXmp(image, xmp);
  } else if (image.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
    labeled = addPngXmp(image, xmp);
  } else {
    throw new Error("Unsupported generated image format for AIGC metadata");
  }
  appendAuditLog({
    event: "generated",
    produceId,
    provider,
    userId: userId || null,
  });
  return { image: labeled.toString("base64"), produceId };
}

export function recordUnmarkedExport(
  produceId: string,
  userId: string,
  exportType: string
): void {
  appendAuditLog({
    event: "unmarked_export_requested",
    produceId,
    userId,
    exportType,
  });
}
