// Os mesmos casos que o pacote Zig confere (vetores/casos.json): os dois dão a mesma resposta.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import * as br from "../src/index.ts";

const casos = JSON.parse(readFileSync(new URL("../vetores/casos.json", import.meta.url), "utf8"));

test("CPF e CNPJ pelo dígito verificador", () => {
  for (const c of casos.cpf.validos) assert.ok(br.cpfValido(c), c);
  for (const c of casos.cpf.invalidos) assert.ok(!br.cpfValido(c), c);
  for (const c of casos.cnpj.validos) assert.ok(br.cnpjValido(c), c);
  for (const c of casos.cnpj.invalidos) assert.ok(!br.cnpjValido(c), c);
  assert.equal(br.formatarDocumento("12345678909"), "123.456.789-09");
  assert.equal(br.formatarDocumento("12345678000195"), "12.345.678/0001-95");
});

test("chave Pix: cada tipo normalizado, sem dizer o tipo", () => {
  for (const c of casos.pix_chave) assert.deepEqual(br.normalizarChave(c.entrada), { ok: true, chave: c.chave, tipo: c.tipo }, c.entrada);
  for (const c of casos.pix_chave_recusada) assert.deepEqual(br.normalizarChave(c.entrada), { ok: false, erro: c.erro }, c.entrada);
});

test("Pix copia e cola: CRC do Manual do BR Code e código gerado", () => {
  for (const c of casos.crc16) assert.equal(br.crc16(c.entrada), c.crc);
  for (const c of casos.pix_gerado) assert.equal(br.gerarCopiaECola({ chave: c.chave, nome: c.nome, cidade: c.cidade, centavos: c.centavos }), c.codigo);
});

test("telefone e WhatsApp", () => {
  for (const c of casos.telefone) assert.equal(br.telefoneE164(c.entrada), c.e164, c.entrada);
  assert.equal(br.whatsappDigitos("(62) 99999-0001"), "5562999990001");
  assert.equal(br.linkWhatsapp("(62) 99999-0001", "Oi, quero 2 pães"), "https://wa.me/5562999990001?text=Oi%2C%20quero%202%20p%C3%A3es");
  assert.equal(br.formatarTelefone("+5562999990001"), "(62) 99999-0001");
  assert.equal(br.formatarTelefone("6233334444"), "(62) 3333-4444");
});

test("reais em centavos, nos dois sentidos", () => {
  for (const c of casos.reais) assert.equal(br.formatarReais(c.centavos), c.texto);
  for (const c of casos.ler_reais) assert.equal(br.lerReais(c.entrada), c.centavos, c.entrada);
});

test("texto: slug e sem acento", () => {
  for (const c of casos.slug) assert.equal(br.slug(c.entrada), c.slug, c.entrada);
  for (const c of casos.sem_acento) assert.equal(br.semAcento(c.entrada), c.saida);
});
