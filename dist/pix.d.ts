export type TipoChave = "cpf" | "cnpj" | "telefone" | "email" | "aleatoria";
export type ErroChave = 
/** Não é chave de nenhum tipo (ou CPF/CNPJ com dígito errado). */
"invalida"
/** Pix copia e cola com o CRC errado: cortado ou alterado ao copiar. */
 | "copia_e_cola_corrompido"
/** Pix copia e cola de cobrança (QR dinâmico, com link): não tem chave fixa. */
 | "copia_e_cola_dinamico";
export type ChavePix = {
    ok: true;
    chave: string;
    tipo: TipoChave;
} | {
    ok: false;
    erro: ErroChave;
};
export declare const MENSAGEM_ERRO: Record<ErroChave, string>;
/** Tamanho máximo de uma chave no DICT (e-mail). */
export declare const CHAVE_MAX = 77;
/** CRC16-CCITT-FALSE, o do BR Code, em 4 dígitos hexadecimais maiúsculos. */
export declare function crc16(texto: string): string;
/**
 * Chave Pix do jeito que a pessoa colou (CPF, CNPJ, celular, e-mail, chave aleatória ou Pix copia e cola estático),
 * conferida e no formato que o app do banco aceita: CPF e CNPJ só caracteres, telefone +55…, e-mail e aleatória em
 * minúsculas. Não precisa dizer o tipo.
 */
export declare function normalizarChave(texto: string): ChavePix;
/**
 * Pix copia e cola estático para receber. `chave` já normalizada (`normalizarChave`). Com `centavos`, o valor vem
 * preenchido no app do banco; sem, quem paga digita. Nome até 25 e cidade até 15 caracteres (ASCII).
 */
export declare function gerarCopiaECola(o: {
    chave: string;
    nome: string;
    cidade: string;
    centavos?: number | null;
    txid?: string;
}): string;
