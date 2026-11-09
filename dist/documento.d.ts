/** Só os dígitos do CPF (ou as letras e dígitos do CNPJ), sem pontuação, em maiúsculas. */
export declare function soDocumento(texto: string): string;
/** CPF com os dois dígitos verificadores certos. Recebe só dígitos (use `soDocumento`). Repetidos (111…) não valem. */
export declare function cpfValido(c: string): boolean;
/** CNPJ numérico ou alfanumérico (12 letras/dígitos + 2 dígitos), em maiúsculas e sem pontuação. */
export declare function cnpjValido(c: string): boolean;
/** "12345678909" -> "123.456.789-09"; "12345678000195" -> "12.345.678/0001-95". Outro tamanho volta como veio. */
export declare function formatarDocumento(c: string): string;
