/*---------------------------------------------------------------------------
 * json_report.c - INI2MAP Tester JSON log (mission.log) -> standalone HTML
 * report: summary cards, severity filter chips, live search, colored rows.
 *
 * Build (MSYS2 MinGW-w64 i686, Windows XP compatible - see build_xp.bat):
 *   gcc -O2 -Wall -D_WIN32_WINNT=0x0501 -DWINVER=0x0501 -municode -static -s
 *       -Xlinker --subsystem=console:5.1 -o json_report.exe json_report.c -lshell32
 * The -Xlinker colon form matters: -Wl,--subsystem,console,5.1 makes ld treat
 * "5.1" as an input file, and the default subsystem of this ld is 4.0.
 * Verify after building: PE32, MajorSubsystemVersion 5.1, imports only
 * KERNEL32/msvcrt/SHELL32 (ucrt api-ms-win-crt-* would not run on XP).
 *
 * Usage:
 *   json_report [-o out.html] [-open] <mission.log.json> [more.json...]
 *     -o out.html   output path (single input only; default: <input>.html)
 *     -open         open the generated report in the default browser
 *
 * Exit codes: 0 = ok, 1 = bad arguments / unreadable file / invalid JSON.
 *--------------------------------------------------------------------------*/
#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <locale.h>
#include <errno.h>

/* ------------------------- minimal JSON tree ------------------------- */

typedef enum { JN_STR, JN_OBJ, JN_ARR, JN_NUM, JN_BOOL, JN_NULL } JType;

typedef struct JNode {
    JType type;
    char *key;                      /* member name for object members      */
    char *str;                      /* JN_STR decoded, JN_NUM raw text     */
    struct JNode *first, *next;
} JNode;

static const char *g_p, *g_end, *g_start;
static int g_depth;
static char g_err[256];

static int pfail(const char *msg)
{
    if (!g_err[0])
        snprintf(g_err, sizeof g_err, "%s (byte %ld)", msg, (long)(g_p - g_start));
    return 0;
}

static void skip_ws(void)
{
    while (g_p < g_end && (*g_p == ' ' || *g_p == '\t' || *g_p == '\r' || *g_p == '\n'))
        g_p++;
}

static JNode *node_new(JType t)
{
    JNode *n = (JNode *)calloc(1, sizeof *n);
    if (n) n->type = t;
    return n;
}

static void child_add(JNode *parent, JNode *child)
{
    if (!parent->first) parent->first = child;
    else { JNode *t = parent->first; while (t->next) t = t->next; t->next = child; }
}

/* Parse a JSON string starting at the opening quote; returns decoded bytes.
 * Escapes are decoded byte-wise (the log writer escapes \ " \n \t \r only);
 * \uXXXX becomes UTF-8, surrogate pairs combined. */
static char *parse_string(void)
{
    if (g_p >= g_end || *g_p != '"') { pfail("expected string"); return NULL; }
    g_p++;
    size_t cap = 32, len = 0;
    char *buf = (char *)malloc(cap);
    if (!buf) { pfail("out of memory"); return NULL; }
    while (g_p < g_end) {
        unsigned char c = (unsigned char)*g_p;
        if (c == '"') { g_p++; buf[len] = 0; return buf; }
        if (c == '\\') {
            g_p++;
            if (g_p >= g_end) break;
            char e = *g_p++;
            char tmp[8];
            int tn = 0;
            unsigned cp = 0;
            switch (e) {
            case '"':  tmp[tn++] = '"';  break;
            case '\\': tmp[tn++] = '\\'; break;
            case '/':  tmp[tn++] = '/';  break;
            case 'n':  tmp[tn++] = '\n'; break;
            case 't':  tmp[tn++] = '\t'; break;
            case 'r':  tmp[tn++] = '\r'; break;
            case 'b':  tmp[tn++] = '\b'; break;
            case 'f':  tmp[tn++] = '\f'; break;
            case 'u': {
                if (g_end - g_p < 4) { free(buf); pfail("truncated \\u escape"); return NULL; }
                for (int i = 0; i < 4; i++) {
                    char h = *g_p++;
                    cp <<= 4;
                    if      (h >= '0' && h <= '9') cp |= (unsigned)(h - '0');
                    else if (h >= 'a' && h <= 'f') cp |= (unsigned)(h - 'a' + 10);
                    else if (h >= 'A' && h <= 'F') cp |= (unsigned)(h - 'A' + 10);
                    else { free(buf); pfail("bad \\u escape"); return NULL; }
                }
                if (cp >= 0xD800 && cp <= 0xDBFF && g_end - g_p >= 6 &&
                    g_p[0] == '\\' && g_p[1] == 'u') {
                    const char *save = g_p;
                    g_p += 2;
                    unsigned lo = 0;
                    int ok = 1;
                    for (int i = 0; i < 4 && ok; i++) {
                        char h = *g_p++;
                        lo <<= 4;
                        if      (h >= '0' && h <= '9') lo |= (unsigned)(h - '0');
                        else if (h >= 'a' && h <= 'f') lo |= (unsigned)(h - 'a' + 10);
                        else if (h >= 'A' && h <= 'F') lo |= (unsigned)(h - 'A' + 10);
                        else ok = 0;
                    }
                    if (ok && lo >= 0xDC00 && lo <= 0xDFFF)
                        cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                    else g_p = save;
                }
                if      (cp < 0x80)    tmp[tn++] = (char)cp;
                else if (cp < 0x800)   { tmp[tn++] = (char)(0xC0 | (cp >> 6));
                                         tmp[tn++] = (char)(0x80 | (cp & 0x3F)); }
                else if (cp < 0x10000) { tmp[tn++] = (char)(0xE0 | (cp >> 12));
                                         tmp[tn++] = (char)(0x80 | ((cp >> 6) & 0x3F));
                                         tmp[tn++] = (char)(0x80 | (cp & 0x3F)); }
                else                   { tmp[tn++] = (char)(0xF0 | (cp >> 18));
                                         tmp[tn++] = (char)(0x80 | ((cp >> 12) & 0x3F));
                                         tmp[tn++] = (char)(0x80 | ((cp >> 6) & 0x3F));
                                         tmp[tn++] = (char)(0x80 | (cp & 0x3F)); }
                break;
            }
            default:
                free(buf);
                pfail("unknown escape in string");
                return NULL;
            }
            if (len + (size_t)tn + 1 > cap) {
                cap = (len + (size_t)tn + 1) * 2;
                char *nb = (char *)realloc(buf, cap);
                if (!nb) { free(buf); pfail("out of memory"); return NULL; }
                buf = nb;
            }
            memcpy(buf + len, tmp, (size_t)tn);
            len += (size_t)tn;
            continue;
        }
        if (len + 2 > cap) {
            cap *= 2;
            char *nb = (char *)realloc(buf, cap);
            if (!nb) { free(buf); pfail("out of memory"); return NULL; }
            buf = nb;
        }
        buf[len++] = (char)c;
        g_p++;
    }
    free(buf);
    pfail("unterminated string");
    return NULL;
}

static JNode *parse_value(void);

static JNode *parse_value(void)
{
    if (++g_depth > 64) { g_depth--; pfail("nesting too deep"); return NULL; }
    skip_ws();
    JNode *n = NULL;
    if (g_p >= g_end) { g_depth--; pfail("unexpected end of input"); return NULL; }
    char c = *g_p;
    if (c == '{') {
        g_p++;
        n = node_new(JN_OBJ);
        if (!n) { g_depth--; pfail("out of memory"); return NULL; }
        skip_ws();
        if (g_p < g_end && *g_p == '}') { g_p++; }
        else for (;;) {
            skip_ws();
            if (g_p >= g_end || *g_p != '"') { g_depth--; pfail("expected object key"); return NULL; }
            char *k = parse_string();
            if (!k) { g_depth--; return NULL; }
            skip_ws();
            if (g_p >= g_end || *g_p != ':') { free(k); g_depth--; pfail("expected ':'"); return NULL; }
            g_p++;
            JNode *v = parse_value();
            if (!v) { free(k); g_depth--; return NULL; }
            v->key = k;
            child_add(n, v);
            skip_ws();
            if (g_p < g_end && *g_p == ',') { g_p++; continue; }
            if (g_p < g_end && *g_p == '}') { g_p++; break; }
            g_depth--; pfail("expected ',' or '}'"); return NULL;
        }
    } else if (c == '[') {
        g_p++;
        n = node_new(JN_ARR);
        if (!n) { g_depth--; pfail("out of memory"); return NULL; }
        skip_ws();
        if (g_p < g_end && *g_p == ']') { g_p++; }
        else for (;;) {
            JNode *v = parse_value();
            if (!v) { g_depth--; return NULL; }
            child_add(n, v);
            skip_ws();
            if (g_p < g_end && *g_p == ',') { g_p++; continue; }
            if (g_p < g_end && *g_p == ']') { g_p++; break; }
            g_depth--; pfail("expected ',' or ']'"); return NULL;
        }
    } else if (c == '"') {
        n = node_new(JN_STR);
        if (!n) { g_depth--; pfail("out of memory"); return NULL; }
        n->str = parse_string();
        if (!n->str) { g_depth--; return NULL; }
    } else if (g_end - g_p >= 4 && !strncmp(g_p, "true", 4)) {
        g_p += 4; n = node_new(JN_BOOL); if (n) n->str = (char *)"1";
    } else if (g_end - g_p >= 5 && !strncmp(g_p, "false", 5)) {
        g_p += 5; n = node_new(JN_BOOL); if (n) n->str = (char *)"0";
    } else if (g_end - g_p >= 4 && !strncmp(g_p, "null", 4)) {
        g_p += 4; n = node_new(JN_NULL);
    } else if (c == '-' || (c >= '0' && c <= '9')) {
        const char *s = g_p;
        while (g_p < g_end && ((*g_p >= '0' && *g_p <= '9') || *g_p == '-' ||
                               *g_p == '+' || *g_p == '.' || *g_p == 'e' || *g_p == 'E'))
            g_p++;
        n = node_new(JN_NUM);
        if (n) {
            n->str = (char *)malloc((size_t)(g_p - s) + 1);
            if (n->str) { memcpy(n->str, s, (size_t)(g_p - s)); n->str[g_p - s] = 0; }
        }
        if (!n || !n->str) { g_depth--; pfail("out of memory"); return NULL; }
    } else {
        g_depth--; pfail("unexpected character");
        return NULL;
    }
    g_depth--;
    return n;
}

static JNode *obj_get(JNode *o, const char *key)
{
    if (!o || o->type != JN_OBJ) return NULL;
    for (JNode *c = o->first; c; c = c->next)
        if (c->key && !strcmp(c->key, key)) return c;
    return NULL;
}

static const char *jstr(JNode *n)
{
    return (n && n->type == JN_STR && n->str) ? n->str : NULL;
}

static int jint(JNode *n, int def)
{
    if (!n || n->type != JN_NUM || !n->str) return def;
    return (int)strtol(n->str, NULL, 10);
}

/* --------------------------- helpers --------------------------------- */

/* full UTF-8 validation of the raw file bytes (encoding sniffing) */
static int valid_utf8(const unsigned char *s, size_t n)
{
    size_t i = 0;
    while (i < n) {
        unsigned c = s[i];
        int k;
        if (c < 0x80) { i++; continue; }
        else if ((c & 0xE0) == 0xC0) k = 1;
        else if ((c & 0xF0) == 0xE0) k = 2;
        else if ((c & 0xF8) == 0xF0) k = 3;
        else return 0;
        if (i + (size_t)k >= n) return 0;
        for (int j = 1; j <= k; j++)
            if ((s[i + j] & 0xC0) != 0x80) return 0;
        i += (size_t)k + 1;
    }
    return 1;
}

/* escape for HTML text and double-quoted attribute contexts */
static void fesc(FILE *f, const char *s)
{
    for (; *s; s++) switch (*s) {
    case '&':  fputs("&amp;", f);  break;
    case '<':  fputs("&lt;", f);   break;
    case '>':  fputs("&gt;", f);   break;
    case '"':  fputs("&quot;", f); break;
    case '\'': fputs("&#39;", f);  break;
    default:   fputc((unsigned char)*s, f); break;
    }
}

static const char *sev_norm(JNode *msg_obj)
{
    const char *s = jstr(obj_get(msg_obj, "severity"));
    if (s && (!strcmp(s, "error") || !strcmp(s, "warning") ||
              !strcmp(s, "notice") || !strcmp(s, "info")))
        return s;
    return "info";
}

static void count_msgs(JNode *arr, int *ne, int *nw, int *nn, int *ni)
{
    *ne = *nw = *nn = *ni = 0;
    if (!arr || arr->type != JN_ARR) return;
    for (JNode *m = arr->first; m; m = m->next) {
        if (m->type != JN_OBJ) continue;
        const char *s = sev_norm(m);
        if      (!strcmp(s, "error"))   (*ne)++;
        else if (!strcmp(s, "warning")) (*nw)++;
        else if (!strcmp(s, "notice"))  (*nn)++;
        else                            (*ni)++;
    }
}

/* default output: replace the input extension with .html */
static wchar_t *default_out(const wchar_t *in)
{
    size_t n = wcslen(in);
    wchar_t *o = (wchar_t *)malloc((n + 6) * sizeof *o);
    if (!o) return NULL;
    wcscpy(o, in);
    wchar_t *base = o;
    for (wchar_t *p = o; *p; p++) if (*p == L'\\' || *p == L'/') base = p + 1;
    wchar_t *dot = NULL;
    for (wchar_t *p = base; *p; p++) if (*p == L'.') dot = p;
    if (dot) *dot = 0;
    wcscat(o, L".html");
    return o;
}

/* wide path -> ANSI (or UTF-8) bytes for console printing / HTML footer */
static void wconv(const wchar_t *w, char *out, size_t cap, UINT cp)
{
    out[0] = 0;
    if (!WideCharToMultiByte(cp, 0, w, -1, out, (int)cap, NULL, NULL))
        snprintf(out, cap, "?");
    out[cap - 1] = 0;
}

/* ------------------------- report writer ----------------------------- */

static int write_report(const wchar_t *inpath, const wchar_t *outpath,
                        const unsigned char *json, size_t jl, int utf8)
{
    g_p = (const char *)json;
    g_end = (const char *)json + jl;
    g_start = g_p;
    g_depth = 0;
    g_err[0] = 0;

    JNode *root = parse_value();
    if (!g_err[0]) { skip_ws(); if (g_p != g_end) pfail("trailing data after JSON value"); }
    if (!root || g_err[0]) {
        fprintf(stderr, "json_report: %ls: invalid JSON: %s\n",
                inpath, g_err[0] ? g_err : "empty input");
        return 1;
    }

    const char *map = jstr(obj_get(root, "map"));
    JNode *sum = obj_get(root, "summary");
    int errs  = jint(obj_get(sum, "errors"), 0);
    int warns = jint(obj_get(sum, "warnings"), 0);
    int notes = jint(obj_get(sum, "notices"), 0);
    int tms   = jint(obj_get(root, "processing_time_ms"), 0);
    JNode *msgs = obj_get(root, "messages");

    int ne, nw, nn, ni;
    count_msgs(msgs, &ne, &nw, &nn, &ni);
    int total = ne + nw + nn + ni;

    /* footer source path in the same encoding as the file content */
    char src[600];
    wconv(inpath, src, sizeof src, utf8 ? CP_UTF8 : CP_ACP);

    /* UI glyphs must match the report encoding: UTF-8, or the matching
     * single cp1251 byte (U+00B7 MIDDLE DOT -> 0xB7, U+2014 EM DASH -> 0x97),
     * otherwise a windows-1251 report renders them as mojibake. */
    const char *dot  = utf8 ? "\xC2\xB7" : "\xB7";
    const char *dash = utf8 ? "\xE2\x80\x94" : "\x97";

    SYSTEMTIME st;
    GetLocalTime(&st);
    char ts[64];
    snprintf(ts, sizeof ts, "%04u-%02u-%02u %02u:%02u:%02u",
             st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);

    FILE *f = _wfopen(outpath, L"wb");
    if (!f) {
        fprintf(stderr, "json_report: cannot write %ls (%s)\n", outpath, strerror(errno));
        return 1;
    }

    /* ---------------- head ---------------- */
    fprintf(f, "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"%s\">\n",
            utf8 ? "utf-8" : "windows-1251");
    fputs("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
          "<title>", f);
    fesc(f, map ? map : "(no map)");
    fprintf(f, "%s INI2MAP report</title>\n<style>\n", dot);
    fputs(
      ":root{--err:#d93025;--warn:#b86400;--note:#1a73e8;--info:#5f6368}\n"
      "*{box-sizing:border-box}\n"
      "body{margin:0;font:14px/1.45 'Segoe UI',system-ui,sans-serif;background:#f5f6f8;color:#202124}\n"
      "header{background:#1f2226;color:#fff;padding:14px 22px}\n"
      "header h1{margin:0;font-size:16px;font-weight:600}\n"
      "header .sub{opacity:.75;font-size:12px;margin-top:4px}\n"
      ".cards{display:flex;gap:12px;padding:16px 22px 6px;flex-wrap:wrap}\n"
      ".card{background:#fff;border:1px solid #e4e7ea;border-radius:8px;padding:10px 18px;min-width:118px}\n"
      ".card .num{font-size:26px;font-weight:700}\n"
      ".card .lbl{font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:#6b7075}\n"
      ".card.err .num{color:var(--err)}\n"
      ".card.warn .num{color:var(--warn)}\n"
      ".card.note .num{color:var(--note)}\n"
      ".card.info .num{color:var(--info)}\n"
      ".controls{display:flex;gap:8px;align-items:center;flex-wrap:wrap;padding:12px 22px;position:sticky;top:0;background:#f5f6f8;border-bottom:1px solid #e4e7ea;z-index:2}\n"
      "#q{flex:1;min-width:180px;max-width:420px;padding:7px 10px;border:1px solid #d5d9dd;border-radius:6px;font:inherit;background:#fff}\n"
      ".chip{border:1px solid #d5d9dd;background:#fff;border-radius:999px;padding:4px 12px;font-size:12px;cursor:pointer;font:inherit}\n"
      ".chip .cnt{opacity:.55;margin-left:4px}\n"
      ".chip.off{opacity:.45;text-decoration:line-through}\n"
      ".chip.c-error{border-color:var(--err);color:var(--err)}\n"
      ".chip.c-warn{border-color:var(--warn);color:var(--warn)}\n"
      ".chip.c-note{border-color:var(--note);color:var(--note)}\n"
      ".chip.c-info{border-color:var(--info);color:var(--info)}\n"
      "#status{font-size:12px;color:#6b7075}\n"
      ".list{padding:8px 22px 20px}\n"
      ".row{display:flex;gap:10px;align-items:baseline;padding:6px 8px;border-bottom:1px solid #eceff1}\n"
      ".row:hover{background:#fafbfc}\n"
      ".row.hide{display:none}\n"
      ".badge{flex:0 0 74px;font-size:10px;font-weight:700;text-align:center;padding:3px 0;border-radius:4px;color:#fff;letter-spacing:.03em}\n"
      ".badge.error{background:var(--err)}\n"
      ".badge.warning{background:var(--warn)}\n"
      ".badge.notice{background:var(--note)}\n"
      ".badge.info{background:var(--info)}\n"
      ".msg{white-space:pre-wrap;word-break:break-word;font-family:Consolas,'Cascadia Mono',monospace;font-size:13px}\n"
      ".empty{padding:36px;text-align:center;color:#6b7075}\n"
      "footer{padding:8px 22px 30px;font-size:11px;color:#9aa0a6}\n"
      "@media(max-width:640px){.cards{gap:8px}.card{min-width:100px;padding:8px 12px}}\n",
      f);
    fputs("</style>\n</head>\n<body>\n", f);

    /* ---------------- header + cards ---------------- */
    fprintf(f, "<header><h1>INI2MAP Tester %s validation report</h1>"
               "<div class=\"sub\">", dash);
    fesc(f, map ? map : "(unknown map)");
    fprintf(f, " %s %d ms</div></header>\n", dot, tms);

    fputs("<div class=\"cards\">", f);
    fprintf(f, "<div class=\"card err\"><div class=\"num\">%d</div><div class=\"lbl\">Errors</div></div>", errs);
    fprintf(f, "<div class=\"card warn\"><div class=\"num\">%d</div><div class=\"lbl\">Warnings</div></div>", warns);
    fprintf(f, "<div class=\"card note\"><div class=\"num\">%d</div><div class=\"lbl\">Notices</div></div>", notes);
    fprintf(f, "<div class=\"card info\"><div class=\"num\">%d</div><div class=\"lbl\">Info</div></div>", ni);
    fprintf(f, "<div class=\"card total\"><div class=\"num\">%d</div><div class=\"lbl\">Messages</div></div></div>\n", total);

    /* ---------------- controls ---------------- */
    fputs("<div class=\"controls\">"
          "<input id=\"q\" type=\"search\" placeholder=\"Search messages...\">", f);
    fprintf(f, "<button class=\"chip c-error\" data-sev=\"error\">Errors<span class=\"cnt\">%d</span></button>", ne);
    fprintf(f, "<button class=\"chip c-warn\" data-sev=\"warning\">Warnings<span class=\"cnt\">%d</span></button>", nw);
    fprintf(f, "<button class=\"chip c-note\" data-sev=\"notice\">Notices<span class=\"cnt\">%d</span></button>", nn);
    fprintf(f, "<button class=\"chip c-info\" data-sev=\"info\">Info<span class=\"cnt\">%d</span></button>", ni);
    fprintf(f, "<span id=\"status\">showing %d of %d</span></div>\n", total, total);

    /* ---------------- message rows ---------------- */
    fputs("<div class=\"list\" id=\"list\">\n", f);
    if (msgs && msgs->type == JN_ARR) {
        for (JNode *m = msgs->first; m; m = m->next) {
            if (m->type != JN_OBJ) continue;
            const char *sev = sev_norm(m);
            const char *msg = jstr(obj_get(m, "message"));
            if (!msg) msg = "";
            const char *label = !strcmp(sev, "error")   ? "ERROR"
                              : !strcmp(sev, "warning") ? "WARNING"
                              : !strcmp(sev, "notice")  ? "NOTICE" : "INFO";
            fputs("<div class=\"row\" data-sev=\"", f);
            fputs(sev, f);
            fputs("\" data-text=\"", f);
            fesc(f, msg);
            fputs("\"><span class=\"badge ", f);
            fputs(sev, f);
            fputs("\">", f);
            fputs(label, f);
            fputs("</span><span class=\"msg\">", f);
            fesc(f, msg);
            fputs("</span></div>\n", f);
        }
    }
    fputs("</div>\n"
          "<div class=\"empty\" id=\"empty\" hidden>No messages match the current filter</div>\n", f);

    /* ---------------- footer ---------------- */
    fputs("<footer>Generated ", f);
    fputs(ts, f);
    fprintf(f, " by json_report.exe %s source: ", dot);
    fesc(f, src);
    fputs("</footer>\n", f);

    /* ---------------- filter/search script ---------------- */
    fputs("<script>\n'use strict';\n", f);
    fputs("var rows = document.querySelectorAll('#list .row');\n"
          "var chips = document.querySelectorAll('.chip[data-sev]');\n"
          "var q = document.getElementById('q');\n"
          "var st = document.getElementById('status');\n"
          "var empty = document.getElementById('empty');\n"
          "var active = { error: true, warning: true, notice: true, info: true };\n"
          "function apply() {\n"
          "  var needle = q.value.trim().toLowerCase();\n"
          "  var shown = 0;\n"
          "  for (var i = 0; i < rows.length; i++) {\n"
          "    var r = rows[i];\n"
          "    var sev = r.getAttribute('data-sev');\n"
          "    var vis = active[sev] && (!needle || r.getAttribute('data-text').toLowerCase().indexOf(needle) !== -1);\n"
          "    r.classList.toggle('hide', !vis);\n"
          "    if (vis) shown++;\n"
          "  }\n"
          "  st.textContent = 'showing ' + shown + ' of ' + rows.length;\n"
          "  empty.hidden = !(shown === 0 && rows.length > 0);\n"
          "}\n"
          "for (var j = 0; j < chips.length; j++) {\n"
          "  chips[j].addEventListener('click', function () {\n"
          "    var s = this.getAttribute('data-sev');\n"
          "    active[s] = !active[s];\n"
          "    this.classList.toggle('off', !active[s]);\n"
          "    apply();\n"
          "  });\n"
          "}\n"
          "q.addEventListener('input', apply);\n"
          "apply();\n", f);
    fputs("</script>\n</body>\n</html>\n", f);

    if (fclose(f)) {
        fprintf(stderr, "json_report: write error on %ls (%s)\n", outpath, strerror(errno));
        return 1;
    }

    char ain[600], aout[600];
    wconv(inpath, ain, sizeof ain, CP_ACP);
    wconv(outpath, aout, sizeof aout, CP_ACP);
    printf("json_report: %s -> %s (%d messages: %d error, %d warning, %d notice, %d info)\n",
           ain, aout, total, ne, nw, nn, ni);
    return 0;
}

/* ---------------------------- driver --------------------------------- */

static int process_file(const wchar_t *in, const wchar_t *out_opt, int do_open)
{
    FILE *f = _wfopen(in, L"rb");
    if (!f) {
        fprintf(stderr, "json_report: cannot open %ls (%s)\n", in, strerror(errno));
        return 1;
    }
    if (fseek(f, 0, SEEK_END)) { fclose(f);
        fprintf(stderr, "json_report: cannot seek %ls\n", in); return 1; }
    long sz = ftell(f);
    if (sz < 0) { fclose(f);
        fprintf(stderr, "json_report: cannot size %ls\n", in); return 1; }
    rewind(f);
    unsigned char *buf = (unsigned char *)malloc((size_t)sz + 1);
    if (!buf) { fclose(f);
        fprintf(stderr, "json_report: out of memory\n"); return 1; }
    size_t rd = fread(buf, 1, (size_t)sz, f);
    fclose(f);

    const unsigned char *json = buf;
    size_t jl = rd;
    int utf8;
    if (rd >= 3 && buf[0] == 0xEF && buf[1] == 0xBB && buf[2] == 0xBF) {
        json = buf + 3; jl = rd - 3; utf8 = 1;          /* UTF-8 BOM */
    } else {
        utf8 = valid_utf8(buf, rd);                     /* else assume windows-1251 */
    }

    int rc;
    wchar_t *out_free = NULL;
    const wchar_t *outpath = out_opt;
    if (!outpath) {
        out_free = default_out(in);
        if (!out_free) { free(buf);
            fprintf(stderr, "json_report: out of memory\n"); return 1; }
        outpath = out_free;
    }

    if (jl == 0) {
        fprintf(stderr, "json_report: %ls: file is empty\n", in);
        rc = 1;
    } else {
        rc = write_report(in, outpath, json, jl, utf8);
    }

    if (rc == 0 && do_open) {
        HINSTANCE h = ShellExecuteW(NULL, L"open", outpath, NULL, NULL, SW_SHOWNORMAL);
        if ((INT_PTR)h <= 32)
            fprintf(stderr, "json_report: cannot open browser for %ls\n", outpath);
    }

    free(out_free);
    free(buf);
    return rc;
}

static void usage(void)
{
    printf(
      "json_report - INI2MAP Tester JSON log -> standalone HTML report\n"
      "\n"
      "Usage:\n"
      "  json_report [options] <mission.log.json> [more.json...]\n"
      "\n"
      "Options:\n"
      "  -o <file>   output HTML path (single input only; default: <input>.html)\n"
      "  -open       open the generated report in the default browser\n"
      "  -h, --help  show this help\n"
      "\n"
      "Exit codes: 0 = ok, 1 = error (bad args, unreadable or invalid JSON)\n");
}

int wmain(int argc, wchar_t **argv)
{
    setlocale(LC_ALL, "");

    const wchar_t **files = (const wchar_t **)calloc((size_t)argc, sizeof *files);
    if (!files) { fprintf(stderr, "json_report: out of memory\n"); return 1; }
    int nfiles = 0;
    const wchar_t *out = NULL;
    int do_open = 0;
    int rc = 0;

    for (int i = 1; i < argc; i++) {
        if (!wcscmp(argv[i], L"-h") || !wcscmp(argv[i], L"--help") || !wcscmp(argv[i], L"/?")) {
            usage();
            free(files);
            return 0;
        } else if (!wcscmp(argv[i], L"-open")) {
            do_open = 1;
        } else if (!wcscmp(argv[i], L"-o")) {
            if (i + 1 >= argc) {
                fprintf(stderr, "json_report: -o requires a path\n");
                free(files);
                return 1;
            }
            out = argv[++i];
        } else if (argv[i][0] == L'-') {
            fprintf(stderr, "json_report: unknown option %ls\n", argv[i]);
            free(files);
            return 1;
        } else {
            files[nfiles++] = argv[i];
        }
    }

    if (nfiles == 0) {
        usage();
        free(files);
        return 1;
    }
    if (out && nfiles > 1) {
        fprintf(stderr, "json_report: -o works with a single input file\n");
        free(files);
        return 1;
    }

    for (int i = 0; i < nfiles; i++)
        if (process_file(files[i], out, do_open)) rc = 1;

    free(files);
    return rc;
}
