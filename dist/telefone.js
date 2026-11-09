// Telefone do Brasil: DDD + celular (9 dígitos, começa com 9) ou fixo (8 dígitos, começa com 2 a 5).
/** O número nacional (DDD + número) se for um telefone brasileiro válido; null se não. */
function nacional(digitos) {
    let d = digitos;
    if ((d.length === 12 || d.length === 13) && d.startsWith("55"))
        d = d.slice(2);
    else if (d.length === 11 && d.startsWith("0"))
        d = d.slice(1); // 0 de discagem antes do DDD (062…)
    else if (d.length === 12 && d.startsWith("0"))
        d = d.slice(1);
    if (d.length !== 10 && d.length !== 11)
        return null;
    if (d[0] === "0" || d[1] === "0")
        return null;
    if (d.length === 11)
        return d[2] === "9" ? d : null;
    return d[2] >= "2" && d[2] <= "5" ? d : null;
}
/** "(62) 99999-0001", "+55 62 99999-0001", "062 99999-0001" -> "+5562999990001"; null se não é telefone do Brasil. */
export function telefoneE164(texto) {
    const t = texto.trim();
    if (/[^\d\s()+.\-]/.test(t))
        return null;
    if (t.startsWith("+") && !t.replace(/\D/g, "").startsWith("55"))
        return null;
    const n = nacional(t.replace(/\D/g, ""));
    return n ? `+55${n}` : null;
}
/** Os dígitos que o wa.me e a API do WhatsApp usam ("5562999990001"); null se não é telefone do Brasil. */
export function whatsappDigitos(texto) {
    return telefoneE164(texto)?.slice(1) ?? null;
}
/** Link para abrir a conversa no WhatsApp, com a mensagem já escrita. */
export function linkWhatsapp(texto, mensagem = "") {
    const d = whatsappDigitos(texto);
    if (!d)
        return null;
    return mensagem ? `https://wa.me/${d}?text=${encodeURIComponent(mensagem)}` : `https://wa.me/${d}`;
}
/** "+5562999990001" -> "(62) 99999-0001". */
export function formatarTelefone(texto) {
    const e = telefoneE164(texto);
    if (!e)
        return null;
    const n = e.slice(3);
    return n.length === 11 ? `(${n.slice(0, 2)}) ${n.slice(2, 7)}-${n.slice(7)}` : `(${n.slice(0, 2)}) ${n.slice(2, 6)}-${n.slice(6)}`;
}
