// Pix: chave como o DICT do Banco Central define, e o Pix copia e cola (BR Code, Manual do BR Code do BC).
import { cnpjValido, cpfValido } from "./documento.js";
import { telefoneE164 } from "./telefone.js";
import { asciiPix } from "./texto.js";
export const MENSAGEM_ERRO = {
    invalida: "Chave Pix inválida. Use o CPF ou CNPJ (com os dígitos certos), o celular com DDD, o e-mail, a chave aleatória ou cole o Pix copia e cola do seu banco.",
    copia_e_cola_corrompido: "Este Pix copia e cola está incompleto ou foi alterado. Copie de novo no app do banco e cole aqui.",
    copia_e_cola_dinamico: "Este Pix copia e cola é de uma cobrança (tem link). Cole a sua chave Pix ou o Pix copia e cola de receber, sem valor.",
};
/** Tamanho máximo de uma chave no DICT (e-mail). */
export const CHAVE_MAX = 77;
/** CRC16-CCITT-FALSE, o do BR Code, em 4 dígitos hexadecimais maiúsculos. */
export function crc16(texto) {
    let crc = 0xffff;
    for (const b of new TextEncoder().encode(texto)) {
        crc ^= b << 8;
        for (let i = 0; i < 8; i++)
            crc = crc & 0x8000 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
    }
    return crc.toString(16).toUpperCase().padStart(4, "0");
}
const EMAIL = /^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9-]+(\.[a-z0-9-]+)+$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
/** A chave como digitada (com ou sem pontuação), sem dizer o tipo. */
function chaveDireta(t) {
    if (t.length < 5 || t.length > CHAVE_MAX)
        return null;
    if (t.includes("@")) {
        const e = t.toLowerCase();
        return EMAIL.test(e) ? { chave: e, tipo: "email" } : null;
    }
    if (UUID.test(t))
        return { chave: t.toLowerCase(), tipo: "aleatoria" };
    if (/[^A-Za-z0-9.\-/() +]/.test(t) || t.indexOf("+") > 0)
        return null;
    const k = t.toUpperCase().replace(/[^A-Z0-9+]/g, "");
    if (!k.startsWith("+")) {
        if (k.length === 14 && cnpjValido(k))
            return { chave: k, tipo: "cnpj" };
        if (/^\d{11}$/.test(k) && cpfValido(k))
            return { chave: k, tipo: "cpf" };
        // Escrito como documento (123.456.789-00): é CPF ou CNPJ com dígito errado, não telefone.
        if (/[./]/.test(t) || /[A-Z]/.test(k))
            return null;
    }
    const fone = telefoneE164(t);
    return fone ? { chave: fone, tipo: "telefone" } : null;
}
function campo(s, i) {
    if (i + 4 > s.length)
        return null;
    const n = Number(s.slice(i + 2, i + 4));
    if (!Number.isInteger(n) || i + 4 + n > s.length)
        return null;
    return { id: s.slice(i, i + 2), valor: s.slice(i + 4, i + 4 + n), fim: i + 4 + n };
}
function lerCopiaECola(s) {
    if (s.length < 8 || s.slice(-8, -4) !== "6304" || crc16(s.slice(0, -4)) !== s.slice(-4).toUpperCase())
        return { ok: false, erro: "copia_e_cola_corrompido" };
    let link = false;
    for (let i = 0; i < s.length - 8;) {
        const c = campo(s, i);
        if (!c)
            return { ok: false, erro: "copia_e_cola_corrompido" };
        i = c.fim;
        const id = Number(c.id);
        if (!(id >= 26 && id <= 51))
            continue;
        let gui = false;
        let chave = null;
        for (let j = 0; j < c.valor.length;) {
            const sub = campo(c.valor, j);
            if (!sub)
                return { ok: false, erro: "copia_e_cola_corrompido" };
            j = sub.fim;
            if (sub.id === "00")
                gui = sub.valor.toLowerCase() === "br.gov.bcb.pix";
            if (sub.id === "01")
                chave = sub.valor;
            if (sub.id === "25")
                link = true;
        }
        if (!gui || chave === null)
            continue;
        const k = chaveDireta(chave);
        return k ? { ok: true, ...k } : { ok: false, erro: "invalida" };
    }
    return { ok: false, erro: link ? "copia_e_cola_dinamico" : "invalida" };
}
/**
 * Chave Pix do jeito que a pessoa colou (CPF, CNPJ, celular, e-mail, chave aleatória ou Pix copia e cola estático),
 * conferida e no formato que o app do banco aceita: CPF e CNPJ só caracteres, telefone +55…, e-mail e aleatória em
 * minúsculas. Não precisa dizer o tipo.
 */
export function normalizarChave(texto) {
    const t = texto.trim();
    if (t.length > 512)
        return { ok: false, erro: "invalida" };
    if (t.startsWith("000201"))
        return lerCopiaECola(t);
    const k = chaveDireta(t);
    return k ? { ok: true, ...k } : { ok: false, erro: "invalida" };
}
function tlv(id, valor) {
    if (valor.length > 99)
        throw new RangeError(`campo ${id} do Pix passou de 99 caracteres`);
    return id + String(valor.length).padStart(2, "0") + valor;
}
/**
 * Pix copia e cola estático para receber. `chave` já normalizada (`normalizarChave`). Com `centavos`, o valor vem
 * preenchido no app do banco; sem, quem paga digita. Nome até 25 e cidade até 15 caracteres (ASCII).
 */
export function gerarCopiaECola(o) {
    const valor = o.centavos ? tlv("54", `${Math.floor(o.centavos / 100)}.${String(o.centavos % 100).padStart(2, "0")}`) : "";
    const corpo = tlv("00", "01") +
        tlv("26", tlv("00", "br.gov.bcb.pix") + tlv("01", o.chave)) +
        tlv("52", "0000") +
        tlv("53", "986") +
        valor +
        tlv("58", "BR") +
        tlv("59", asciiPix(o.nome).slice(0, 25)) +
        tlv("60", asciiPix(o.cidade).slice(0, 15)) +
        tlv("62", tlv("05", o.txid ? asciiPix(o.txid).replace(/ /g, "").slice(0, 25) : "***")) +
        "6304";
    return corpo + crc16(corpo);
}
