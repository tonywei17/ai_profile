const XMP_HEADER = 'http://ns.adobe.com/xap/1.0/\0'
const CONTENT_PRODUCER = '羽飞科技(广西)有限责任公司'

const encodeUtf8 = (value) => {
  const encoded = unescape(encodeURIComponent(value))
  const bytes = new Uint8Array(encoded.length)
  for (let index = 0; index < encoded.length; index += 1) {
    bytes[index] = encoded.charCodeAt(index)
  }
  return bytes
}

const escapeXml = (value) =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

const createXmpBytes = (produceId) => {
  const metadata = {
    Label: '1',
    ContentProducer: CONTENT_PRODUCER,
    ProduceID: produceId,
    ReservedCode1: '',
    ContentPropagator: '',
    PropagateID: '',
    ReservedCode2: ''
  }
  const xmp =
    '<?xpacket begin="﻿" id="W5M0MpCehiHzreSzNTczkc9d"?>' +
    '<x:xmpmeta xmlns:x="adobe:ns:meta/">' +
    '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' +
    '<rdf:Description rdf:about="" xmlns:aigc="http://cvdca.org.cn/ns/aigc/1.0/">' +
    `<aigc:Info>${escapeXml(JSON.stringify(metadata))}</aigc:Info>` +
    '</rdf:Description></rdf:RDF></x:xmpmeta>' +
    '<?xpacket end="w"?>'
  return encodeUtf8(xmp)
}

const addJpegXmp = (imageBytes, produceId) => {
  if (imageBytes[0] !== 0xff || imageBytes[1] !== 0xd8) {
    throw new Error('排版图片不是可标识的 JPEG 格式')
  }
  const headerBytes = encodeUtf8(XMP_HEADER)
  const xmpBytes = createXmpBytes(produceId)
  const payloadLength = headerBytes.length + xmpBytes.length
  const segmentLength = payloadLength + 2
  if (segmentLength > 0xffff) {
    throw new Error('AI 内容标识数据过长')
  }
  const output = new Uint8Array(imageBytes.length + payloadLength + 4)
  output[0] = 0xff
  output[1] = 0xd8
  output[2] = 0xff
  output[3] = 0xe1
  output[4] = (segmentLength >> 8) & 0xff
  output[5] = segmentLength & 0xff
  output.set(headerBytes, 6)
  output.set(xmpBytes, 6 + headerBytes.length)
  output.set(imageBytes.subarray(2), 6 + payloadLength)
  return output.buffer
}

const addAigcMetadataToJpegFile = (filePath, produceId) =>
  new Promise((resolve, reject) => {
    if (!produceId) {
      reject(new Error('生成内容标识缺失'))
      return
    }
    const fileSystem = uni.getFileSystemManager()
    fileSystem.readFile({
      filePath,
      success: (result) => {
        try {
          const labeledData = addJpegXmp(
            new Uint8Array(result.data),
            produceId
          )
          const outputPath = `${wx.env.USER_DATA_PATH}/print_aigc_${Date.now()}.jpg`
          fileSystem.writeFile({
            filePath: outputPath,
            data: labeledData,
            success: () => resolve(outputPath),
            fail: reject
          })
        } catch (error) {
          reject(error)
        }
      },
      fail: reject
    })
  })

export default {
  addAigcMetadataToJpegFile
}
