/** 123456 -> "R$ 1.234,56"; -550 -> "-R$ 5,50". Sem depender do Intl (sai igual no Node, no navegador e no Zig). */
export declare function formatarReais(centavos: number): string;
/** "12,90", "R$ 1.234,56", "1.290" (milhar), "12.9" -> centavos; null se vazio ou não é valor em reais. */
export declare function lerReais(texto: string): number | null;
