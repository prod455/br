// CPF e CNPJ (também o CNPJ alfanumérico da Receita, emitido desde julho de 2026), pelo dígito verificador.
function digitoVerificador(base, pesos) {
    let soma = 0;
    for (let i = 0; i < base.length; i++)
        soma += (base.charCodeAt(i) - 48) * pesos[i];
    const r = soma % 11;
    return r < 2 ? 0 : 11 - r;
}
/** Só os dígitos do CPF (ou as letras e dígitos do CNPJ), sem pontuação, em maiúsculas. */
export function soDocumento(texto) {
    return texto.toUpperCase().replace(/[^A-Z0-9]/g, "");
}
/** CPF com os dois dígitos verificadores certos. Recebe só dígitos (use `soDocumento`). Repetidos (111…) não valem. */
export function cpfValido(c) {
    if (!/^\d{11}$/.test(c) || /^(\d)\1{10}$/.test(c))
        return false;
    const d1 = digitoVerificador(c.slice(0, 9), [10, 9, 8, 7, 6, 5, 4, 3, 2]);
    const d2 = digitoVerificador(c.slice(0, 10), [11, 10, 9, 8, 7, 6, 5, 4, 3, 2]);
    return c.endsWith(`${d1}${d2}`);
}
/** CNPJ numérico ou alfanumérico (12 letras/dígitos + 2 dígitos), em maiúsculas e sem pontuação. */
export function cnpjValido(c) {
    if (!/^[A-Z0-9]{12}\d{2}$/.test(c) || /^(.)\1{13}$/.test(c))
        return false;
    const d1 = digitoVerificador(c.slice(0, 12), [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    const d2 = digitoVerificador(c.slice(0, 13), [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    return c.endsWith(`${d1}${d2}`);
}
/** "12345678909" -> "123.456.789-09"; "12345678000195" -> "12.345.678/0001-95". Outro tamanho volta como veio. */
export function formatarDocumento(c) {
    if (c.length === 11)
        return `${c.slice(0, 3)}.${c.slice(3, 6)}.${c.slice(6, 9)}-${c.slice(9)}`;
    if (c.length === 14)
        return `${c.slice(0, 2)}.${c.slice(2, 5)}.${c.slice(5, 8)}/${c.slice(8, 12)}-${c.slice(12)}`;
    return c;
}
