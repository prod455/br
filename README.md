# br

O que todo sistema brasileiro reescreve, uma vez só, em **TypeScript** (pacote npm `@prod455/br`) e em **Zig**
(módulo `br`), com o mesmo comportamento: os dois conferem os mesmos casos de `vetores/casos.json`.

| Tema | TypeScript | Zig |
|---|---|---|
| CPF e CNPJ (também o alfanumérico de 2026), pelo dígito verificador | `cpfValido`, `cnpjValido`, `soDocumento`, `formatarDocumento` | `cpfValido`, `cnpjValido`, `soDocumento` |
| Chave Pix sem dizer o tipo (CPF, CNPJ, celular, e-mail, aleatória ou Pix copia e cola estático) | `normalizarChave`, `MENSAGEM_ERRO` | `normalizarChave`, `ErroChave.mensagem` |
| Pix copia e cola para receber, com ou sem valor | `gerarCopiaECola`, `crc16` | `gerarCopiaECola`, `crc16` |
| Telefone do Brasil e WhatsApp | `telefoneE164`, `whatsappDigitos`, `linkWhatsapp`, `formatarTelefone` | `telefoneE164`, `whatsappDigitos` |
| Reais em centavos inteiros | `formatarReais`, `lerReais` | `formatarReais`, `lerReais` |
| Texto | `slug`, `semAcento`, `asciiPix` | `slug`, `semAcento`, `asciiPix` |

## Usar no TypeScript

```bash
npm install github:prod455/br#v0.1.0
```

```ts
import { normalizarChave, formatarReais, MENSAGEM_ERRO } from "@prod455/br";

const r = normalizarChave("123.456.789-09");
if (!r.ok) throw new Error(MENSAGEM_ERRO[r.erro]);
r.chave; // "12345678909"
formatarReais(123456); // "R$ 1.234,56"
```

## Usar no Zig (0.17)

```bash
zig fetch --save git+https://github.com/prod455/br#v0.1.0
```

```zig
// build.zig
const br = b.dependency("br", .{ .target = target, .optimize = optimize }).module("br");
exe.root_module.addImport("br", br);
```

```zig
const br = @import("br");
switch (try br.normalizarChave(arena, texto)) {
    .ok => |k| guardar(k.chave),
    .erro => |e| return falha(e.mensagem()),
}
```

## Mudar alguma coisa

1. Acrescente o caso em `vetores/casos.json`.
2. Ajuste `src/` (TypeScript) e `br.zig` (Zig) até os dois passarem: `npm test` e `zig build test`.
3. `npm run build` (o `dist/` vai no commit: é o que o `npm install github:…` usa), suba a versão em `package.json` e
   `build.zig.zon`, e marque a tag `vX.Y.Z`.
