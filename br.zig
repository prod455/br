//! br: o que todo sistema brasileiro reescreve, em Zig. Mesmo comportamento do pacote npm @prod455/br (src/),
//! conferido pelos mesmos casos (vetores/casos.json): CPF e CNPJ (também o alfanumérico), chave Pix e Pix copia e
//! cola, telefone e WhatsApp, reais em centavos, slug e texto sem acento.
//!
//! Funções que devolvem texto novo recebem um allocator (pense numa arena); o resultado é do chamador.
const std = @import("std");

// ---------------------------------------------------------------------------
// CPF e CNPJ
// ---------------------------------------------------------------------------

fn digitoVerificador(base: []const u8, pesos: []const u8) u8 {
    var soma: u32 = 0;
    for (base, pesos) |c, p| soma += @as(u32, c -% '0') * p;
    const r = soma % 11;
    return if (r < 2) 0 else @intCast(11 - r);
}

fn todosIguais(s: []const u8) bool {
    for (s[1..]) |c| if (c != s[0]) return false;
    return true;
}

/// CPF com os dois dígitos verificadores certos. Só dígitos (sem pontuação); repetidos (111…) não valem.
pub fn cpfValido(c: []const u8) bool {
    if (c.len != 11) return false;
    for (c) |ch| if (!std.ascii.isDigit(ch)) return false;
    if (todosIguais(c)) return false;
    const d1 = digitoVerificador(c[0..9], &.{ 10, 9, 8, 7, 6, 5, 4, 3, 2 });
    const d2 = digitoVerificador(c[0..10], &.{ 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 });
    return c[9] - '0' == d1 and c[10] - '0' == d2;
}

/// CNPJ numérico ou alfanumérico (12 letras maiúsculas ou dígitos + 2 dígitos), sem pontuação. O valor de cada
/// caractere é o código ASCII menos 48, como manda a Receita.
pub fn cnpjValido(c: []const u8) bool {
    if (c.len != 14) return false;
    for (c[0..12]) |ch| if (!(std.ascii.isDigit(ch) or std.ascii.isUpper(ch))) return false;
    if (!std.ascii.isDigit(c[12]) or !std.ascii.isDigit(c[13])) return false;
    if (todosIguais(c)) return false;
    const d1 = digitoVerificador(c[0..12], &.{ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 });
    const d2 = digitoVerificador(c[0..13], &.{ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 });
    return c[12] - '0' == d1 and c[13] - '0' == d2;
}

/// Só as letras (maiúsculas) e os dígitos de um documento digitado com pontuação.
pub fn soDocumento(a: std.mem.Allocator, texto: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    for (texto) |c| if (std.ascii.isAlphanumeric(c)) try out.append(a, std.ascii.toUpper(c));
    return out.toOwnedSlice(a);
}

// ---------------------------------------------------------------------------
// Telefone e WhatsApp
// ---------------------------------------------------------------------------

/// DDD + número, se for telefone do Brasil: celular de 9 dígitos começando com 9, ou fixo de 8 começando com 2 a 5.
fn nacional(digitos: []const u8) ?[]const u8 {
    var d = digitos;
    if ((d.len == 12 or d.len == 13) and std.mem.startsWith(u8, d, "55")) {
        d = d[2..];
    } else if ((d.len == 11 or d.len == 12) and d[0] == '0') d = d[1..]; // 0 de discagem antes do DDD
    if (d.len != 10 and d.len != 11) return null;
    if (d[0] == '0' or d[1] == '0') return null;
    if (d.len == 11) return if (d[2] == '9') d else null;
    return if (d[2] >= '2' and d[2] <= '5') d else null;
}

/// "(62) 99999-0001", "+55 62 99999-0001", "062 99999-0001" -> "+5562999990001"; null se não é telefone do Brasil.
pub fn telefoneE164(a: std.mem.Allocator, texto: []const u8) !?[]u8 {
    const t = std.mem.trim(u8, texto, " \t\r\n");
    var buf: [32]u8 = undefined;
    var n: usize = 0;
    for (t) |c| switch (c) {
        '0'...'9' => {
            if (n == buf.len) return null;
            buf[n] = c;
            n += 1;
        },
        ' ', '\t', '(', ')', '+', '.', '-' => {},
        else => return null,
    };
    if (t.len > 0 and t[0] == '+' and !std.mem.startsWith(u8, buf[0..n], "55")) return null;
    const nac = nacional(buf[0..n]) orelse return null;
    return try std.fmt.allocPrint(a, "+55{s}", .{nac});
}

/// Os dígitos que o wa.me e a API do WhatsApp usam ("5562999990001").
pub fn whatsappDigitos(a: std.mem.Allocator, texto: []const u8) !?[]u8 {
    const e = try telefoneE164(a, texto) orelse return null;
    return e[1..];
}

// ---------------------------------------------------------------------------
// Pix
// ---------------------------------------------------------------------------

pub const TipoChave = enum { cpf, cnpj, telefone, email, aleatoria };

pub const ErroChave = enum {
    /// Não é chave de nenhum tipo (ou CPF/CNPJ com dígito errado).
    invalida,
    /// Pix copia e cola com o CRC errado: cortado ou alterado ao copiar.
    copia_e_cola_corrompido,
    /// Pix copia e cola de cobrança (QR dinâmico, com link): não tem chave fixa.
    copia_e_cola_dinamico,

    pub fn mensagem(self: ErroChave) []const u8 {
        return switch (self) {
            .invalida => "Chave Pix inválida. Use o CPF ou CNPJ (com os dígitos certos), o celular com DDD, o e-mail, a chave aleatória ou cole o Pix copia e cola do seu banco.",
            .copia_e_cola_corrompido => "Este Pix copia e cola está incompleto ou foi alterado. Copie de novo no app do banco e cole aqui.",
            .copia_e_cola_dinamico => "Este Pix copia e cola é de uma cobrança (tem link). Cole a sua chave Pix ou o Pix copia e cola de receber, sem valor.",
        };
    }
};

pub const ChavePix = union(enum) { ok: struct { chave: []const u8, tipo: TipoChave }, erro: ErroChave };

/// Tamanho máximo de uma chave no DICT (e-mail).
pub const chave_max = 77;

/// CRC16-CCITT-FALSE, o do BR Code.
pub fn crc16(texto: []const u8) u16 {
    var crc: u16 = 0xffff;
    for (texto) |b| {
        crc ^= @as(u16, b) << 8;
        for (0..8) |_| crc = if (crc & 0x8000 != 0) (crc << 1) ^ 0x1021 else crc << 1;
    }
    return crc;
}

fn emailValido(e: []const u8) bool {
    const at = std.mem.indexOfScalar(u8, e, '@') orelse return false;
    if (at == 0 or std.mem.lastIndexOfScalar(u8, e, '@').? != at) return false;
    for (e[0..at]) |c| if (!(std.ascii.isAlphanumeric(c) or std.mem.indexOfScalar(u8, ".!#$%&'*+/=?^_`{|}~-", c) != null)) return false;
    const dominio = e[at + 1 ..];
    if (std.mem.indexOfScalar(u8, dominio, '.') == null) return false;
    var it = std.mem.splitScalar(u8, dominio, '.');
    while (it.next()) |parte| {
        if (parte.len == 0) return false;
        for (parte) |c| if (!(std.ascii.isAlphanumeric(c) or c == '-')) return false;
    }
    return true;
}

fn uuid(t: []const u8) bool {
    if (t.len != 36) return false;
    for (t, 0..) |c, i| {
        if (i == 8 or i == 13 or i == 18 or i == 23) {
            if (c != '-') return false;
        } else if (!std.ascii.isHex(c)) return false;
    }
    return true;
}

fn minusculas(a: std.mem.Allocator, t: []const u8) ![]u8 {
    const out = try a.alloc(u8, t.len);
    for (t, out) |c, *o| o.* = std.ascii.toLower(c);
    return out;
}

fn chaveDireta(a: std.mem.Allocator, t: []const u8) !?ChavePix {
    if (t.len < 5 or t.len > chave_max) return null;
    if (std.mem.indexOfScalar(u8, t, '@') != null) {
        const e = try minusculas(a, t);
        return if (emailValido(e)) .{ .ok = .{ .chave = e, .tipo = .email } } else null;
    }
    if (uuid(t)) return .{ .ok = .{ .chave = try minusculas(a, t), .tipo = .aleatoria } };
    for (t, 0..) |c, i| {
        const pontuacao = c == '.' or c == '-' or c == '/' or c == '(' or c == ')' or c == ' ';
        if (!(std.ascii.isAlphanumeric(c) or pontuacao or (c == '+' and i == 0))) return null;
    }
    if (t[0] != '+') {
        const k = try soDocumento(a, t);
        if (k.len == 14 and cnpjValido(k)) return .{ .ok = .{ .chave = k, .tipo = .cnpj } };
        if (cpfValido(k)) return .{ .ok = .{ .chave = k, .tipo = .cpf } };
        // Escrito como documento (123.456.789-00): é CPF ou CNPJ com dígito errado, não telefone.
        if (std.mem.indexOfAny(u8, t, "./") != null) return null;
        for (k) |c| if (!std.ascii.isDigit(c)) return null;
    }
    const fone = try telefoneE164(a, t) orelse return null;
    return .{ .ok = .{ .chave = fone, .tipo = .telefone } };
}

const Campo = struct { id: []const u8, valor: []const u8, fim: usize };

fn campo(s: []const u8, i: usize) ?Campo {
    if (i + 4 > s.len) return null;
    const n = std.fmt.parseInt(usize, s[i + 2 .. i + 4], 10) catch return null;
    if (i + 4 + n > s.len) return null;
    return .{ .id = s[i .. i + 2], .valor = s[i + 4 .. i + 4 + n], .fim = i + 4 + n };
}

fn lerCopiaECola(a: std.mem.Allocator, s: []const u8) !ChavePix {
    if (s.len < 8 or !std.mem.eql(u8, s[s.len - 8 .. s.len - 4], "6304")) return .{ .erro = .copia_e_cola_corrompido };
    const informado = std.fmt.parseInt(u16, s[s.len - 4 ..], 16) catch return .{ .erro = .copia_e_cola_corrompido };
    if (crc16(s[0 .. s.len - 4]) != informado) return .{ .erro = .copia_e_cola_corrompido };
    var i: usize = 0;
    var link = false;
    while (i < s.len - 8) {
        const c = campo(s, i) orelse return .{ .erro = .copia_e_cola_corrompido };
        i = c.fim;
        const id = std.fmt.parseInt(u8, c.id, 10) catch continue;
        if (id < 26 or id > 51) continue;
        var j: usize = 0;
        var gui = false;
        var chave: ?[]const u8 = null;
        while (j < c.valor.len) {
            const sub = campo(c.valor, j) orelse return .{ .erro = .copia_e_cola_corrompido };
            j = sub.fim;
            if (std.mem.eql(u8, sub.id, "00")) gui = std.ascii.eqlIgnoreCase(sub.valor, "br.gov.bcb.pix");
            if (std.mem.eql(u8, sub.id, "01")) chave = sub.valor;
            if (std.mem.eql(u8, sub.id, "25")) link = true;
        }
        if (!gui) continue;
        const k = chave orelse continue;
        return try chaveDireta(a, k) orelse .{ .erro = .invalida };
    }
    return .{ .erro = if (link) .copia_e_cola_dinamico else .invalida };
}

/// Chave Pix do jeito que a pessoa colou (CPF, CNPJ, celular, e-mail, chave aleatória ou Pix copia e cola estático),
/// conferida e no formato que o app do banco aceita: CPF e CNPJ só caracteres, telefone +55…, e-mail e aleatória
/// em minúsculas. Não precisa dizer o tipo.
pub fn normalizarChave(a: std.mem.Allocator, texto: []const u8) !ChavePix {
    const t = std.mem.trim(u8, texto, " \t\r\n");
    if (t.len > 512) return .{ .erro = .invalida };
    if (std.mem.startsWith(u8, t, "000201")) return lerCopiaECola(a, t);
    return try chaveDireta(a, t) orelse .{ .erro = .invalida };
}

fn tlv(out: *std.ArrayList(u8), a: std.mem.Allocator, id: []const u8, valor: []const u8) !void {
    if (valor.len > 99) return error.CampoGrandeDemais;
    try out.print(a, "{s}{d:0>2}{s}", .{ id, valor.len, valor });
}

/// Pix copia e cola estático para receber. `chave` já normalizada (`normalizarChave`). Com `centavos`, o valor vem
/// preenchido no app do banco. Nome até 25 e cidade até 15 caracteres (ASCII).
pub fn gerarCopiaECola(a: std.mem.Allocator, o: struct { chave: []const u8, nome: []const u8, cidade: []const u8, centavos: ?u64 = null }) ![]u8 {
    var conta: std.ArrayList(u8) = .empty;
    try tlv(&conta, a, "00", "br.gov.bcb.pix");
    try tlv(&conta, a, "01", o.chave);
    var out: std.ArrayList(u8) = .empty;
    try tlv(&out, a, "00", "01");
    try tlv(&out, a, "26", conta.items);
    try tlv(&out, a, "52", "0000");
    try tlv(&out, a, "53", "986");
    if (o.centavos) |c| if (c > 0) try tlv(&out, a, "54", try std.fmt.allocPrint(a, "{d}.{d:0>2}", .{ c / 100, c % 100 }));
    try tlv(&out, a, "58", "BR");
    const nome = try asciiPix(a, o.nome);
    const cidade = try asciiPix(a, o.cidade);
    try tlv(&out, a, "59", nome[0..@min(nome.len, 25)]);
    try tlv(&out, a, "60", cidade[0..@min(cidade.len, 15)]);
    try tlv(&out, a, "62", "0503***");
    try out.appendSlice(a, "6304");
    try out.print(a, "{X:0>4}", .{crc16(out.items)});
    return out.toOwnedSlice(a);
}

// ---------------------------------------------------------------------------
// Reais
// ---------------------------------------------------------------------------

/// 123456 -> "R$ 1.234,56"; -550 -> "-R$ 5,50".
pub fn formatarReais(a: std.mem.Allocator, centavos: i64) ![]u8 {
    const abs: u64 = @abs(centavos);
    var dig: [24]u8 = undefined;
    const reais = std.fmt.bufPrint(&dig, "{d}", .{abs / 100}) catch unreachable;
    var out: std.ArrayList(u8) = .empty;
    if (centavos < 0) try out.append(a, '-');
    try out.appendSlice(a, "R$ ");
    for (reais, 0..) |d, i| {
        if (i > 0 and (reais.len - i) % 3 == 0) try out.append(a, '.');
        try out.append(a, d);
    }
    try out.print(a, ",{d:0>2}", .{abs % 100});
    return out.toOwnedSlice(a);
}

/// "12,90", "R$ 1.234,56", "1.290" (milhar), "12.9" -> centavos; null se vazio ou não é valor em reais.
pub fn lerReais(texto: []const u8) ?u64 {
    var s = std.mem.trim(u8, texto, " \t\r\n");
    if (s.len >= 2 and (s[0] == 'R' or s[0] == 'r') and s[1] == '$') s = std.mem.trimStart(u8, s[2..], " ");
    if (s.len == 0) return null;
    var inteiro: u64 = 0;
    var fracao: u64 = 0;
    var casas: u8 = 0;
    const virgula = std.mem.indexOfScalar(u8, s, ',') != null;
    // Sem vírgula, o ponto é milhar só quando agrupa de três em três ("1.290"); senão é a casa decimal.
    const ponto_milhar = virgula or milharPorPonto(s);
    var decimal = false;
    for (s) |c| switch (c) {
        '0'...'9' => if (decimal) {
            casas += 1;
            if (casas > 2) return null;
            fracao = fracao * 10 + (c - '0');
        } else {
            inteiro = std.math.mul(u64, inteiro, 10) catch return null;
            inteiro = std.math.add(u64, inteiro, c - '0') catch return null;
        },
        '.' => if (!ponto_milhar) {
            if (decimal) return null;
            decimal = true;
        },
        ',' => {
            if (decimal) return null;
            decimal = true;
        },
        else => return null,
    };
    if (decimal and casas == 0) return null;
    if (casas == 1) fracao *= 10;
    const total = std.math.mul(u64, inteiro, 100) catch return null;
    return std.math.add(u64, total, fracao) catch null;
}

fn milharPorPonto(s: []const u8) bool {
    var it = std.mem.splitScalar(u8, s, '.');
    const primeiro = it.next().?;
    if (primeiro.len == 0 or primeiro.len > 3 or std.mem.indexOfScalar(u8, s, '.') == null) return false;
    while (it.next()) |g| if (g.len != 3) return false;
    return true;
}

// ---------------------------------------------------------------------------
// Texto
// ---------------------------------------------------------------------------

/// A letra sem acento das letras acentuadas do português (e do Latin-1); null nas outras.
fn baseDe(cp: u21) ?u8 {
    return switch (cp) {
        'á', 'à', 'â', 'ã', 'ä', 'å' => 'a',
        'Á', 'À', 'Â', 'Ã', 'Ä', 'Å' => 'A',
        'é', 'è', 'ê', 'ë' => 'e',
        'É', 'È', 'Ê', 'Ë' => 'E',
        'í', 'ì', 'î', 'ï' => 'i',
        'Í', 'Ì', 'Î', 'Ï' => 'I',
        'ó', 'ò', 'ô', 'õ', 'ö' => 'o',
        'Ó', 'Ò', 'Ô', 'Õ', 'Ö' => 'O',
        'ú', 'ù', 'û', 'ü' => 'u',
        'Ú', 'Ù', 'Û', 'Ü' => 'U',
        'ç' => 'c',
        'Ç' => 'C',
        'ñ' => 'n',
        'Ñ' => 'N',
        else => null,
    };
}

/// "Goiânia" -> "Goiania". Só tira os acentos; texto que não é UTF-8 volta igual.
pub fn semAcento(a: std.mem.Allocator, texto: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    var it = (std.unicode.Utf8View.init(texto) catch return a.dupe(u8, texto)).iterator();
    while (it.nextCodepointSlice()) |bytes| {
        const cp = std.unicode.utf8Decode(bytes) catch unreachable;
        if (baseDe(cp)) |b| try out.append(a, b) else try out.appendSlice(a, bytes);
    }
    return out.toOwnedSlice(a);
}

/// O que o BR Code aceita: ASCII em maiúsculas, letras, números e espaço único.
pub fn asciiPix(a: std.mem.Allocator, texto: []const u8) ![]u8 {
    const sem = try semAcento(a, texto);
    var out: std.ArrayList(u8) = .empty;
    for (sem) |c| {
        const ok = c < 128 and std.ascii.isAlphanumeric(c);
        if (ok) {
            try out.append(a, std.ascii.toUpper(c));
        } else if (out.items.len > 0 and out.items[out.items.len - 1] != ' ') try out.append(a, ' ');
    }
    while (out.items.len > 0 and out.items[out.items.len - 1] == ' ') _ = out.pop();
    return out.toOwnedSlice(a);
}

/// "Empório Maná" -> "emporio-mana". Vazio se não há letra nem número. `max` corta sem deixar hífen na ponta.
pub fn slug(a: std.mem.Allocator, texto: []const u8, max: usize) ![]u8 {
    const sem = try semAcento(a, texto);
    var out: std.ArrayList(u8) = .empty;
    for (sem) |c| {
        if (c < 128 and std.ascii.isAlphanumeric(c)) {
            try out.append(a, std.ascii.toLower(c));
        } else if (out.items.len > 0 and out.items[out.items.len - 1] != '-') try out.append(a, '-');
    }
    if (out.items.len > max) out.shrinkRetainingCapacity(max);
    while (out.items.len > 0 and out.items[out.items.len - 1] == '-') _ = out.pop();
    return out.toOwnedSlice(a);
}

// ---------------------------------------------------------------------------
// Testes: os mesmos casos do pacote npm
// ---------------------------------------------------------------------------

const testing = std.testing;
const casos_json = @embedFile("vetores/casos.json");

const Casos = struct {
    cpf: struct { validos: []const []const u8, invalidos: []const []const u8 },
    cnpj: struct { validos: []const []const u8, invalidos: []const []const u8 },
    pix_chave: []const struct { entrada: []const u8, chave: []const u8, tipo: []const u8 },
    pix_chave_recusada: []const struct { entrada: []const u8, erro: []const u8 },
    crc16: []const struct { entrada: []const u8, crc: []const u8 },
    pix_gerado: []const struct { chave: []const u8, nome: []const u8, cidade: []const u8, centavos: ?u64, codigo: []const u8 },
    telefone: []const struct { entrada: []const u8, e164: ?[]const u8 },
    reais: []const struct { centavos: i64, texto: []const u8 },
    ler_reais: []const struct { entrada: []const u8, centavos: ?u64 },
    slug: []const struct { entrada: []const u8, slug: []const u8 },
    sem_acento: []const struct { entrada: []const u8, saida: []const u8 },
};

fn casos(a: std.mem.Allocator) !Casos {
    return std.json.parseFromSliceLeaky(Casos, a, casos_json, .{});
}

test "CPF e CNPJ pelo dígito verificador" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const c = try casos(arena.allocator());
    for (c.cpf.validos) |d| try testing.expect(cpfValido(d));
    for (c.cpf.invalidos) |d| try testing.expect(!cpfValido(d));
    for (c.cnpj.validos) |d| try testing.expect(cnpjValido(d));
    for (c.cnpj.invalidos) |d| try testing.expect(!cnpjValido(d));
}

test "chave Pix: cada tipo normalizado, sem dizer o tipo" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const c = try casos(a);
    for (c.pix_chave) |k| {
        const r = try normalizarChave(a, k.entrada);
        errdefer std.debug.print("entrada: {s}\n", .{k.entrada});
        try testing.expectEqualStrings(k.chave, r.ok.chave);
        try testing.expectEqualStrings(k.tipo, @tagName(r.ok.tipo));
    }
    for (c.pix_chave_recusada) |k| {
        const r = try normalizarChave(a, k.entrada);
        errdefer std.debug.print("entrada: {s}\n", .{k.entrada});
        try testing.expectEqualStrings(k.erro, @tagName(r.erro));
    }
}

test "Pix copia e cola: CRC do Manual do BR Code e código gerado" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const c = try casos(a);
    for (c.crc16) |k| try testing.expectEqual(try std.fmt.parseInt(u16, k.crc, 16), crc16(k.entrada));
    for (c.pix_gerado) |k| try testing.expectEqualStrings(k.codigo, try gerarCopiaECola(a, .{ .chave = k.chave, .nome = k.nome, .cidade = k.cidade, .centavos = k.centavos }));
}

test "telefone e WhatsApp" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const c = try casos(a);
    for (c.telefone) |k| {
        const r = try telefoneE164(a, k.entrada);
        errdefer std.debug.print("entrada: {s}\n", .{k.entrada});
        if (k.e164) |e| try testing.expectEqualStrings(e, r.?) else try testing.expect(r == null);
    }
    try testing.expectEqualStrings("5562999990001", (try whatsappDigitos(a, "(62) 99999-0001")).?);
}

test "reais em centavos, nos dois sentidos" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const c = try casos(a);
    for (c.reais) |k| try testing.expectEqualStrings(k.texto, try formatarReais(a, k.centavos));
    for (c.ler_reais) |k| {
        errdefer std.debug.print("entrada: {s}\n", .{k.entrada});
        try testing.expectEqual(k.centavos, lerReais(k.entrada));
    }
}

test "texto: slug e sem acento" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const c = try casos(a);
    for (c.slug) |k| try testing.expectEqualStrings(k.slug, try slug(a, k.entrada, 60));
    for (c.sem_acento) |k| try testing.expectEqualStrings(k.saida, try semAcento(a, k.entrada));
}
