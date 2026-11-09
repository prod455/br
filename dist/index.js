// @prod455/br: o que todo sistema brasileiro reescreve. Mesmo comportamento no pacote Zig (zig/br.zig), conferido
// pelos mesmos casos (vetores/casos.json).
export { cpfValido, cnpjValido, soDocumento, formatarDocumento } from "./documento.js";
export { normalizarChave, gerarCopiaECola, crc16, MENSAGEM_ERRO, CHAVE_MAX } from "./pix.js";
export { telefoneE164, whatsappDigitos, linkWhatsapp, formatarTelefone } from "./telefone.js";
export { formatarReais, lerReais } from "./dinheiro.js";
export { semAcento, asciiPix, slug } from "./texto.js";
