// @prod455/br: o que todo sistema brasileiro reescreve. Mesmo comportamento no pacote Zig (zig/br.zig), conferido
// pelos mesmos casos (vetores/casos.json).
export { cpfValido, cnpjValido, soDocumento, formatarDocumento } from "./documento.ts";
export { normalizarChave, gerarCopiaECola, crc16, MENSAGEM_ERRO, CHAVE_MAX, type ChavePix, type TipoChave, type ErroChave } from "./pix.ts";
export { telefoneE164, whatsappDigitos, linkWhatsapp, formatarTelefone } from "./telefone.ts";
export { formatarReais, lerReais } from "./dinheiro.ts";
export { semAcento, asciiPix, slug } from "./texto.ts";
