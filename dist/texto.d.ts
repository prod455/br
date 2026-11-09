/** "Goiânia" -> "Goiania". Só tira os acentos; o resto do texto fica como está. */
export declare function semAcento(texto: string): string;
/** O que o BR Code (Pix copia e cola) aceita: ASCII em maiúsculas, letras, números e espaço. */
export declare function asciiPix(texto: string): string;
/** "Empório Maná" -> "emporio-mana". Vazio se não há letra nem número. `max` corta sem deixar hífen na ponta. */
export declare function slug(texto: string, max?: number): string;
