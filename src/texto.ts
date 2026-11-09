// Texto em português: sem acento, ASCII do BR Code e slug de endereço.

/** "Goiânia" -> "Goiania". Só tira os acentos; o resto do texto fica como está. */
export function semAcento(texto: string): string {
  return texto.normalize("NFKD").replace(/[̀-ͯ]/g, "");
}

/** O que o BR Code (Pix copia e cola) aceita: ASCII em maiúsculas, letras, números e espaço. */
export function asciiPix(texto: string): string {
  return semAcento(texto)
    .replace(/[^\x00-\x7f]/g, "")
    .replace(/[^A-Za-z0-9 ]/g, " ")
    .replace(/ +/g, " ")
    .trim()
    .toUpperCase();
}

/** "Empório Maná" -> "emporio-mana". Vazio se não há letra nem número. `max` corta sem deixar hífen na ponta. */
export function slug(texto: string, max = 60): string {
  const s = semAcento(texto).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  return s.slice(0, max).replace(/-+$/g, "");
}
