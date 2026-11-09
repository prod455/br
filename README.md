# br

[![ci](https://github.com/prod455/br/actions/workflows/ci.yml/badge.svg)](https://github.com/prod455/br/actions/workflows/ci.yml)
![TypeScript](https://img.shields.io/badge/TypeScript-zero%20deps-3178c6)
![Zig](https://img.shields.io/badge/Zig-0.17-f7a41d)
![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-green)

CPF, CNPJ, Pix, telefone, WhatsApp, reais e slug: o que todo sistema brasileiro reescreve, escrito **uma vez** em
**TypeScript** e em **Zig**, com o mesmo comportamento nos dois.

- **Zero dependências** nos dois lados.
- **Os mesmos casos de teste** nos dois: `vetores/casos.json` é lido pelo `npm test` e pelo `zig build test`. Se um
  muda e o outro não, a CI quebra.
- **Pronto para colar no banco**: a chave Pix sai no formato que o app do banco aceita (CPF só números, telefone
  `+55…`, e-mail em minúsculas).
- **CNPJ alfanumérico** (o novo da Receita, emitido desde julho de 2026) já vale.
- **Dinheiro em centavos inteiros**: nada de ponto flutuante no caminho do dinheiro, e `R$ 1.234,56` sai igual no
  Node, no navegador e no Zig (sem depender do `Intl`).

## O que tem

| Tema | TypeScript | Zig |
|---|---|---|
| CPF e CNPJ pelo dígito verificador | `cpfValido`, `cnpjValido`, `soDocumento`, `formatarDocumento` | `cpfValido`, `cnpjValido`, `soDocumento` |
| Chave Pix sem dizer o tipo | `normalizarChave`, `MENSAGEM_ERRO`, `CHAVE_MAX` | `normalizarChave`, `ErroChave.mensagem`, `chave_max` |
| Pix copia e cola para receber, com ou sem valor | `gerarCopiaECola`, `crc16` | `gerarCopiaECola`, `crc16` |
| Telefone do Brasil e WhatsApp | `telefoneE164`, `whatsappDigitos`, `linkWhatsapp`, `formatarTelefone` | `telefoneE164`, `whatsappDigitos` |
| Reais em centavos | `formatarReais`, `lerReais` | `formatarReais`, `lerReais` |
| Texto | `slug`, `semAcento`, `asciiPix` | `slug`, `semAcento`, `asciiPix` |

## Instalar

**TypeScript / JavaScript** (Node 20+, Vite, Workers, navegador):

```bash
npm install github:prod455/br#v0.1.0
```

**Zig 0.17:**

```bash
zig fetch --save git+https://github.com/prod455/br#v0.1.0
```

```zig
// build.zig
const br = b.dependency("br", .{ .target = target, .optimize = optimize }).module("br");
exe.root_module.addImport("br", br);
```

## Exemplos

### Chave Pix (do jeito que a pessoa colar)

Aceita CPF, CNPJ, celular, fixo, e-mail, chave aleatória ou o **Pix copia e cola** do app do banco. Descobre o tipo
sozinha, confere e devolve a chave no formato do DICT do Banco Central.

```ts
import { normalizarChave, MENSAGEM_ERRO } from "@prod455/br";

normalizarChave("123.456.789-09");     // { ok: true, chave: "12345678909", tipo: "cpf" }
normalizarChave("(62) 99999-0001");    // { ok: true, chave: "+5562999990001", tipo: "telefone" }
normalizarChave("Loja@Exemplo.com.br"); // { ok: true, chave: "loja@exemplo.com.br", tipo: "email" }
normalizarChave("00020126330014br.gov.bcb.pix0111…6304…"); // a chave de dentro do copia e cola

const r = normalizarChave("123.456.789-00");
if (!r.ok) console.log(MENSAGEM_ERRO[r.erro]); // "Chave Pix inválida. Use o CPF ou CNPJ (com os dígitos certos)…"
```

| Entrada | Resultado |
|---|---|
| CPF ou CNPJ com dígito errado | `invalida` |
| Pix copia e cola cortado ou alterado (CRC não confere) | `copia_e_cola_corrompido` |
| Pix copia e cola de cobrança (QR dinâmico, com link) | `copia_e_cola_dinamico` |

```zig
const br = @import("br");

switch (try br.normalizarChave(arena, texto)) {
    .ok => |k| try salvar(k.chave),          // k.tipo: .cpf, .cnpj, .telefone, .email, .aleatoria
    .erro => |e| return falha(e.mensagem()), // texto pronto para mostrar a quem digitou
}
```

### Pix copia e cola para o cliente pagar

```ts
import { gerarCopiaECola } from "@prod455/br";

gerarCopiaECola({ chave: "+5562999990001", nome: "Empório Maná", cidade: "Goiânia", centavos: 1290 });
// "00020126360014br.gov.bcb.pix0114+5562999990001…540512.90…6304…" (o app do banco já abre com R$ 12,90)
```

Sem `centavos`, quem paga digita o valor. Nome e cidade viram ASCII em maiúsculas e são cortados no tamanho do BR
Code (25 e 15).

### Telefone e WhatsApp

```ts
import { telefoneE164, linkWhatsapp, formatarTelefone } from "@prod455/br";

telefoneE164("062 99999-0001");                 // "+5562999990001"
telefoneE164("(62) 89999-0001");                // null (celular começa com 9)
linkWhatsapp("(62) 99999-0001", "Quero 2 pães"); // "https://wa.me/5562999990001?text=Quero%202%20p%C3%A3es"
formatarTelefone("+556233334444");              // "(62) 3333-4444"
```

### Reais

```ts
import { formatarReais, lerReais } from "@prod455/br";

formatarReais(123456); // "R$ 1.234,56"
lerReais("R$ 1.234,56"); // 123456
lerReais("1.290");       // 129000 (ponto de milhar)
lerReais("12.9");        // 1290
lerReais("doze");        // null
```

### CPF, CNPJ e texto

```ts
import { cpfValido, cnpjValido, soDocumento, formatarDocumento, slug, semAcento } from "@prod455/br";

cpfValido(soDocumento("123.456.789-09"));     // true
cnpjValido(soDocumento("12.ABC.345/01DE-35")); // true (CNPJ alfanumérico)
formatarDocumento("12345678000195");          // "12.345.678/0001-95"
slug("Empório Maná");                          // "emporio-mana"
semAcento("Goiânia");                          // "Goiania"
```

## Regras que valem

- **CPF**: 11 dígitos, dois dígitos verificadores; repetidos (`111.111.111-11`) não valem.
- **CNPJ**: 12 letras maiúsculas ou dígitos + 2 dígitos verificadores (cada caractere vale o código ASCII menos 48,
  como manda a Receita).
- **Telefone**: DDD sem zero + celular de 9 dígitos começando com 9, ou fixo de 8 começando com 2 a 5. Aceita `+55`,
  `55` e o `0` de discagem na frente. Número de outro país não é telefone do Brasil.
- **Escrito como documento** (`123.456.789-00`): se o dígito não bate, é CPF errado, nunca vira telefone.
- **Pix copia e cola**: só o estático (com a chave dentro). O CRC16-CCITT é conferido; o exemplo do Manual do BR Code
  do Banco Central está nos casos de teste.

## Mudar alguma coisa

1. Acrescente o caso em `vetores/casos.json`.
2. Ajuste `src/` (TypeScript) e `br.zig` (Zig) até os dois passarem:

   ```bash
   npm test
   zig build test
   ```

3. `npm run build`: o `dist/` vai no commit, é o que o `npm install github:…` usa.
4. Suba a versão em `package.json` e `build.zig.zon` e marque a tag `vX.Y.Z`.

## Licença

MIT.
