// Reais em centavos inteiros: nada de ponto flutuante no caminho do dinheiro.
/** 123456 -> "R$ 1.234,56"; -550 -> "-R$ 5,50". Sem depender do Intl (sai igual no Node, no navegador e no Zig). */
export function formatarReais(centavos) {
    if (!Number.isSafeInteger(centavos))
        throw new RangeError("centavos precisa ser inteiro");
    const neg = centavos < 0;
    const abs = Math.abs(centavos);
    const reais = String(Math.floor(abs / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    return `${neg ? "-" : ""}R$ ${reais},${String(abs % 100).padStart(2, "0")}`;
}
/** "12,90", "R$ 1.234,56", "1.290" (milhar), "12.9" -> centavos; null se vazio ou não é valor em reais. */
export function lerReais(texto) {
    const s = texto.trim().replace(/^R\$\s*/i, "");
    if (s === "")
        return null;
    // Com vírgula, o ponto é milhar; sem vírgula, só é milhar quando agrupa de três em três ("1.290").
    const n = s.includes(",") ? s.replace(/\./g, "").replace(",", ".") : /^\d{1,3}(\.\d{3})+$/.test(s) ? s.replace(/\./g, "") : s;
    if (!/^\d+(\.\d{1,2})?$/.test(n))
        return null;
    const [inteiro, fracao = ""] = n.split(".");
    const v = Number(inteiro) * 100 + Number((fracao + "00").slice(0, 2));
    return Number.isSafeInteger(v) ? v : null;
}
