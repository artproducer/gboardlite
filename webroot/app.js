// =========================================
// i18n
// =========================================
const i18n = {
    es: {
        headerSubtitle: 'KernelSU WebUI — gboardlite_apmods',
        statusTitle: 'Estado',
        verifyingModule: 'Verificando módulo...',
        themesLabel: 'Temas',
        executingCommand: 'Espera...',
        configureThemes: 'Configurar Temas',
        lightTheme: 'Tema Claro',
        darkTheme: 'Tema Oscuro',
        lightThemeLabel: 'Tema para modo claro:',
        darkThemeLabel: 'Tema para modo oscuro:',
        selectOption: 'Seleccionar...',
        applyBtn: 'Aplicar',
        systemLog: 'Log',
        clearBtn: 'Limpiar',
        copyLogBtn: 'Copiar',
        moduleFound: 'Módulo activo',
        moduleNotFound: 'Módulo no encontrado',
        selectBothThemes: 'Selecciona ambos temas',
        applyingThemes: 'Aplicando temas...',
        themesApplied: '¡Temas aplicados! Reinicia para ver los cambios.',
        configSaved: 'Configuración guardada',
        restartRequired: 'Reinicio necesario',
        applyError: 'Error al aplicar temas',
        logCleared: 'Log limpiado',
        logCopied: 'Log copiado',
        nothingToCopy: 'Nada que copiar',
        noRootDetected: 'Root no detectado',
        currentLightTheme: 'Tema claro:',
        currentDarkTheme: 'Tema oscuro:',
        notConfigured: 'No configurado',
        themesFound: 'Temas encontrados',
        noThemesFound: 'Sin temas disponibles',
        loadThemesError: 'Error cargando temas',
        verifyModuleFirst: 'Verifique el módulo primero'
    },
    en: {
        headerSubtitle: 'KernelSU WebUI — gboardlite_apmods',
        statusTitle: 'Status',
        verifyingModule: 'Verifying module...',
        themesLabel: 'Themes',
        executingCommand: 'Please wait...',
        configureThemes: 'Configure Themes',
        lightTheme: 'Light Theme',
        darkTheme: 'Dark Theme',
        lightThemeLabel: 'Theme for light mode:',
        darkThemeLabel: 'Theme for dark mode:',
        selectOption: 'Select...',
        applyBtn: 'Apply',
        systemLog: 'Log',
        clearBtn: 'Clear',
        copyLogBtn: 'Copy',
        moduleFound: 'Module active',
        moduleNotFound: 'Module not found',
        selectBothThemes: 'Select both themes',
        applyingThemes: 'Applying themes...',
        themesApplied: 'Themes applied! Restart to see changes.',
        configSaved: 'Configuration saved',
        restartRequired: 'Restart required',
        applyError: 'Error applying themes',
        logCleared: 'Log cleared',
        logCopied: 'Log copied',
        nothingToCopy: 'Nothing to copy',
        noRootDetected: 'Root not detected',
        currentLightTheme: 'Light theme:',
        currentDarkTheme: 'Dark theme:',
        notConfigured: 'Not configured',
        themesFound: 'Themes found',
        noThemesFound: 'No themes available',
        loadThemesError: 'Error loading themes',
        verifyModuleFirst: 'Verify module first'
    }
};

let lang = localStorage.getItem('gboardLang') || 'en';

function t(key) {
    return i18n[lang]?.[key] || i18n.en[key] || key;
}

function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        const val = i18n[lang]?.[key];
        if (val) el.textContent = val;
    });
    document.documentElement.lang = lang;
}

function toggleLanguage() {
    lang = lang === 'es' ? 'en' : 'es';
    localStorage.setItem('gboardLang', lang);
    const sw = document.getElementById('langSwitch');
    const es = document.getElementById('langEs');
    const en = document.getElementById('langEn');
    sw.classList.toggle('en', lang === 'en');
    es.classList.toggle('active', lang === 'es');
    en.classList.toggle('active', lang === 'en');
    applyTranslations();
    log(lang === 'en' ? 'Language → English' : 'Idioma → Español', 'info');
}

// =========================================
// State
// =========================================
let moduleActive = false;
let availableThemes = [];
const MODDIR = '/data/adb/modules/gboardlite_apmods';
const THEME_PATH = '/system/etc/gboard_theme';
const CONFIG_PATH = `${MODDIR}/system.prop`;

// =========================================
// Log
// =========================================
const MAX_LOG_LINES = 60;

function log(msg, type = 'info') {
    const c = document.getElementById('logContainer');
    const el = document.createElement('div');
    const ts = new Date().toLocaleTimeString('en-US', { hour12: false });
    el.className = `log-line log-${type}`;
    el.textContent = `[${ts}] ${msg}`;
    c.appendChild(el);
    c.scrollTop = c.scrollHeight;
    while (c.children.length > MAX_LOG_LINES) c.removeChild(c.firstChild);
}

function clearLog() {
    document.getElementById('logContainer').innerHTML = '';
    log(t('logCleared'), 'info');
}

async function copyLog() {
    const lines = Array.from(document.getElementById('logContainer').children).map(l => l.textContent);
    const text = lines.join('\n');
    if (!text.trim()) { showAlert(t('nothingToCopy'), 'warning'); return; }
    try {
        await navigator.clipboard.writeText(text);
        showAlert(t('logCopied'), 'success');
    } catch {
        showAlert(t('logCopied'), 'warning');
    }
}

// =========================================
// UI Helpers
// =========================================
function showAlert(msg, type = 'success') {
    const id = `alert${type.charAt(0).toUpperCase() + type.slice(1)}`;
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = msg;
    el.style.display = 'block';
    setTimeout(() => el.style.display = 'none', 3500);
}

function showLoading(v) {
    document.getElementById('loading').style.display = v ? 'block' : 'none';
}

function setStatus(active, msg) {
    const el = document.getElementById('moduleStatus');
    moduleActive = active;
    el.className = `module-status ${active ? 'status-active' : 'status-inactive'}`;
    el.innerHTML = active
        ? `<svg class="icon" viewBox="0 0 24 24"><polyline points="20,6 9,17 4,12"/></svg> ${msg}`
        : `<svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg> ${msg}`;
}

// =========================================
// KSU Shell
// =========================================
async function exec(cmd) {
    if (typeof ksu?.exec !== 'function') throw new Error('KSU API unavailable');
    const r = await ksu.exec(cmd);
    return r?.toString() || '';
}

// =========================================
// Init
// =========================================
async function init() {
    showLoading(true);
    log('Initializing...', 'info');

    try {
        // Root check
        const who = await exec('whoami');
        const root = who.includes('root');
        document.getElementById('rootStatus').textContent = root ? '✓' : '✗';
        document.getElementById('rootStatus').style.color = root ? '#4ade80' : '#f87171';
        if (!root) log(t('noRootDetected'), 'warning');

        // Module check
        const exists = await exec(`test -d "${MODDIR}" && echo ok || echo no`);
        if (exists.includes('ok')) {
            setStatus(true, t('moduleFound'));

            // Config check
            const cfgExists = await exec(`test -f "${CONFIG_PATH}" && echo ok || echo no`);
            document.getElementById('configStatus').textContent = cfgExists.includes('ok') ? '✓' : '!';
            document.getElementById('configStatus').style.color = cfgExists.includes('ok') ? '#4ade80' : '#fbbf24';

            await loadThemes();
            await readConfig();
        } else {
            setStatus(false, t('moduleNotFound'));
            document.getElementById('configStatus').textContent = '✗';
            document.getElementById('configStatus').style.color = '#f87171';
        }
    } catch (e) {
        log(`Error: ${e.message}`, 'error');
        document.getElementById('rootStatus').textContent = '✗';
        document.getElementById('rootStatus').style.color = '#f87171';
    } finally {
        showLoading(false);
    }
}

// =========================================
// Themes
// =========================================
async function loadThemes() {
    log('Loading themes...', 'info');
    try {
        const res = await fetch('themes.json', { cache: 'no-store' });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();

        const themes = [...new Set(
            data.map(i => (i.filename || '').trim()).filter(n => n.endsWith('.zip'))
        )].sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));

        availableThemes = themes;
        document.getElementById('themeCount').textContent = themes.length;
        populateSelector(themes);
        log(`${t('themesFound')}: ${themes.length}`, 'success');
    } catch (e) {
        log(`${t('loadThemesError')}: ${e.message}`, 'error');
        availableThemes = [];
        document.getElementById('themeCount').textContent = '0';
    }
}

function populateSelector(themes) {
    const selLight = document.getElementById('lightTheme');
    const selDark = document.getElementById('darkTheme');
    const defaultOpt = `<option value="">${t('selectOption')}</option>`;
    selLight.innerHTML = defaultOpt;
    selDark.innerHTML = defaultOpt;
    themes.forEach(th => {
        const label = th.replace('.zip', '');
        selLight.appendChild(Object.assign(document.createElement('option'), { value: th, textContent: label }));
        selDark.appendChild(Object.assign(document.createElement('option'), { value: th, textContent: label }));
    });
}

// =========================================
// Config Read
// =========================================
async function readConfig() {
    try {
        const raw = await exec(`cat "${CONFIG_PATH}" 2>/dev/null || echo ""`);
        const content = raw.trim();
        if (!content) return;

        const lines = content.split(/\r?\n/).map(l => l.trim()).filter(l => l && !l.startsWith('#'));

        let lightTheme = '';
        let darkTheme = '';
        for (const line of lines) {
            if (line.startsWith('ro.com.google.ime.theme_file=')) {
                lightTheme = line.split('=')[1]?.trim() || '';
            } else if (line.startsWith('ro.com.google.ime.d_theme_file=')) {
                darkTheme = line.split('=')[1]?.trim() || '';
            }
        }

        // Pre-select in dropdowns
        if (lightTheme && availableThemes.includes(lightTheme)) {
            document.getElementById('lightTheme').value = lightTheme;
        }
        if (darkTheme && availableThemes.includes(darkTheme)) {
            document.getElementById('darkTheme').value = darkTheme;
        }

        // Show current config
        const cfgEl = document.getElementById('currentConfig');
        const cfgContent = document.getElementById('configContent');
        cfgContent.innerHTML = `
            <div style="font-size:12px;color:#94a3b8;margin-bottom:6px;">☀️ ${t('currentLightTheme')} <strong>${lightTheme || t('notConfigured')}</strong></div>
            <div class="config-line">ro.com.google.ime.theme_file=${lightTheme}</div>
            <div style="font-size:12px;color:#94a3b8;margin:8px 0 6px;">🌙 ${t('currentDarkTheme')} <strong>${darkTheme || t('notConfigured')}</strong></div>
            <div class="config-line">ro.com.google.ime.d_theme_file=${darkTheme}</div>
        `;
        cfgEl.style.display = 'block';

        log(`☀️ ${t('currentLightTheme')} ${lightTheme || t('notConfigured')}`, 'info');
        log(`🌙 ${t('currentDarkTheme')} ${darkTheme || t('notConfigured')}`, 'info');
    } catch (e) {
        log(`Config read error: ${e.message}`, 'error');
    }
}

// =========================================
// Apply Themes
// =========================================
async function applyThemes() {
    if (!moduleActive) { showAlert(t('verifyModuleFirst'), 'warning'); return; }

    const lightTheme = document.getElementById('lightTheme').value;
    const darkTheme = document.getElementById('darkTheme').value;
    if (!lightTheme || !darkTheme) { showAlert(t('selectBothThemes'), 'warning'); return; }

    showLoading(true);
    log(t('applyingThemes'), 'info');

    try {
        // Remove old entries
        await exec(`sed -i '/^ro.com.google.ime.theme_file=/d' "${CONFIG_PATH}"`);
        await exec(`sed -i '/^ro.com.google.ime.d_theme_file=/d' "${CONFIG_PATH}"`);

        // Write light and dark themes
        await exec(`echo "ro.com.google.ime.theme_file=${lightTheme}" >> "${CONFIG_PATH}"`);
        await exec(`echo "ro.com.google.ime.d_theme_file=${darkTheme}" >> "${CONFIG_PATH}"`);

        // Fix permissions
        await exec(`chmod 644 "${CONFIG_PATH}" && chown root:root "${CONFIG_PATH}"`);

        // Update display
        const cfgContent = document.getElementById('configContent');
        cfgContent.innerHTML = `
            <div style="font-size:12px;color:#94a3b8;margin-bottom:6px;">☀️ ${t('currentLightTheme')} <strong>${lightTheme}</strong></div>
            <div class="config-line">ro.com.google.ime.theme_file=${lightTheme}</div>
            <div style="font-size:12px;color:#94a3b8;margin:8px 0 6px;">🌙 ${t('currentDarkTheme')} <strong>${darkTheme}</strong></div>
            <div class="config-line">ro.com.google.ime.d_theme_file=${darkTheme}</div>
        `;
        document.getElementById('currentConfig').style.display = 'block';

        showAlert(t('themesApplied'), 'success');
        log(t('configSaved'), 'success');
        log(`⚠ ${t('restartRequired')}`, 'warning');
    } catch (e) {
        log(`${t('applyError')}: ${e.message}`, 'error');
        showAlert(t('applyError'), 'error');
    } finally {
        showLoading(false);
    }
}

// =========================================
// Boot
// =========================================
document.addEventListener('DOMContentLoaded', () => {
    // Init language
    const sw = document.getElementById('langSwitch');
    const es = document.getElementById('langEs');
    const en = document.getElementById('langEn');
    sw.classList.toggle('en', lang === 'en');
    es.classList.toggle('active', lang === 'es');
    en.classList.toggle('active', lang === 'en');
    applyTranslations();

    log('🚀 Gboard Theme Manager v2.4', 'success');
    setTimeout(init, 400);
});

window.addEventListener('error', e => log(`JS Error: ${e.message}`, 'error'));
window.addEventListener('unhandledrejection', e => log(`Promise error: ${e.reason}`, 'error'));
