/** "(62) 99999-0001", "+55 62 99999-0001", "062 99999-0001" -> "+5562999990001"; null se não é telefone do Brasil. */
export declare function telefoneE164(texto: string): string | null;
/** Os dígitos que o wa.me e a API do WhatsApp usam ("5562999990001"); null se não é telefone do Brasil. */
export declare function whatsappDigitos(texto: string): string | null;
/** Link para abrir a conversa no WhatsApp, com a mensagem já escrita. */
export declare function linkWhatsapp(texto: string, mensagem?: string): string | null;
/** "+5562999990001" -> "(62) 99999-0001". */
export declare function formatarTelefone(texto: string): string | null;
