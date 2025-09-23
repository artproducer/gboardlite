// Variables globales
let ksuAvailable = false;
let moduleActive = false;
let availableThemes = [];
const MODDIR = '/data/adb/modules/gboardlite_apmods';
// const THEME_PATH = `${MODDIR}/system/etc/gboard_theme`;
const THEME_PATH = `/system/etc/gboard_theme`;
const CONFIG_PATH = `${MODDIR}/system.prop`;

// Funciones de logging
function log(message, type = 'info') {
    const logContainer = document.getElementById('logContainer');
    const timestamp = new Date().toLocaleTimeString();
    const logLine = document.createElement('div');
    logLine.className = `log-line log-${type}`;
    logLine.textContent = `[${timestamp}] ${message}`;
    logContainer.appendChild(logLine);
    logContainer.scrollTop = logContainer.scrollHeight;

    // Limitar líneas del log
    const lines = logContainer.children;
    if (lines.length > 100) {
        logContainer.removeChild(lines[0]);
    }
}

function showAlert(message, type = 'success') {
    const alertId = `alert${type.charAt(0).toUpperCase() + type.slice(1)}`;
    const alertElement = document.getElementById(alertId);
    if (alertElement) {
        alertElement.textContent = message;
        alertElement.style.display = 'block';
        setTimeout(() => {
            alertElement.style.display = 'none';
        }, 4000);
    }
}

function showLoading(show = true) {
    document.getElementById('loading').style.display = show ? 'block' : 'none';
}

// Función principal para ejecutar comandos shell via KSU
async function executeCommand(command) {
    log(`Ejecutando: ${command}`, 'info');

    if (typeof window.ksu !== 'undefined' && typeof window.ksu.exec === 'function') {
        try {
            const result = await window.ksu.exec(command);
            const resultStr = result?.toString() || '';
            const previewLength = Math.min(resultStr.length, 80);
            log(`Resultado (${resultStr.length} chars): ${resultStr.substring(0, previewLength)}${resultStr.length > previewLength ? '...' : ''}`, 'success');
            return resultStr;
        } catch (error) {
            log(`❌ Error ejecutando comando: ${error.message}`, 'error');
            throw error;
        }
    } else {
        const msg = '❌ API KSU no disponible (window.ksu.exec no encontrado)';
        log(msg, 'error');
        throw new Error(msg);
    }
}

// Inicialización del sistema KSU
async function initializeKSU() {
    showLoading(true);
    log('🔍 Detectando entorno KernelSU...', 'info');

    // Debug: Detectar APIs disponibles
    await debugKSUEnvironment();

    try {
        // Verificar acceso root
        const whoami = await executeCommand('whoami');
        const hasRoot = whoami.includes('root');

        document.getElementById('rootStatus').textContent = hasRoot ? '✓' : '✗';
        document.getElementById('rootStatus').style.color = hasRoot ? '#4CAF50' : '#dc2626';

        if (!hasRoot) {
            log('⚠️ No se detectó acceso root', 'warning');
            showAlert('No se detectó acceso root. Verifique permisos.', 'warning');
        }

        // Verificar proveedor de root (KSU / Magisk)
        async function detectRootProvider() {
            try {
                // 1. Detectar si estamos en KernelSU
                const ksuProp = await executeCommand('getprop ro.kernel.su.version || echo ""');
                if (ksuProp && ksuProp.trim().length > 0) {
                    ksuAvailable = true;
                    document.getElementById('ksuStatus').textContent = `KSU: v${ksuProp.trim()}`;
                    log(`✅ KernelSU detectado: ${ksuProp.trim()}`, 'success');
                    return 'ksu';
                }

                // 2. Detectar si estamos en Magisk
                const magiskCheck = await executeCommand('which magisk 2>/dev/null || echo ""');
                if (magiskCheck && magiskCheck.includes('magisk')) {
                    document.getElementById('ksuStatus').textContent = 'Magisk detectado';
                    log('✅ Magisk detectado', 'success');
                    return 'magisk';
                }

                // 3. Ninguno encontrado
                document.getElementById('ksuStatus').textContent = 'Root no soportado';
                log('❌ No se detectó KernelSU ni Magisk', 'error');
                return 'none';

            } catch (e) {
                document.getElementById('ksuStatus').textContent = 'Error detectando root';
                log(`❌ Error en detectRootProvider: ${e.message}`, 'error');
                return 'error';
            }
        }

        // Verificar módulo
        await checkModule();

        if (hasRoot || ksuAvailable) {
            showAlert('Sistema inicializado correctamente', 'success');
        } else {
            showAlert('Sistema en modo limitado - Verifique permisos root y KSU', 'warning');
        }

    } catch (error) {
        log(`❌ Error inicializando: ${error.message}`, 'error');
        showAlert('Error al inicializar el sistema', 'error');

        // Actualizar estados de error
        document.getElementById('rootStatus').textContent = '✗';
        document.getElementById('rootStatus').style.color = '#dc2626';
        document.getElementById('ksuStatus').textContent = 'KSU: Error';
    } finally {
        showLoading(false);
    }
}

async function debugKSUEnvironment() {
    log('🔍 DEBUG: Detectando API KernelSU...', 'info');

    const hasExec = typeof window.ksu?.exec === 'function';
    log(`📊 window.ksu.exec: ${hasExec ? 'OK' : 'NO'}`, hasExec ? 'success' : 'error');

    if (hasExec) {
        try {
            log('🧪 Probando ejecución de comando simple...', 'info');
            const testResult = await executeCommand('echo "test"');
            log(`🧪 Resultado de prueba: "${testResult}"`, testResult ? 'success' : 'warning');
        } catch (e) {
            log(`🧪 Error en prueba: ${e.message}`, 'error');
        }
    } else {
        log('❌ No se puede ejecutar comandos: API KSU no disponible', 'error');
    }
}

// Verificar estado del módulo
async function checkModule() {
    log('Verificando módulo gboardlite_apmods...', 'info');

    try {
        // Verificar si existe el directorio del módulo
        const moduleCheck = await executeCommand(`test -d "${MODDIR}" && echo "exists" || echo "missing"`);

        if (moduleCheck.includes('exists')) {
            moduleActive = true;
            updateModuleStatus(true, 'Módulo encontrado y activo');

            // Verificar configuración
            try {
                await executeCommand(`test -f "${CONFIG_PATH}"`);
                document.getElementById('configStatus').textContent = '✓';
                document.getElementById('configStatus').style.color = '#4CAF50';
            } catch (e) {
                document.getElementById('configStatus').textContent = '!';
                document.getElementById('configStatus').style.color = '#f59e0b';
                log('Archivo system.prop no encontrado', 'warning');
            }

            await scanThemes(true);
            await updateCurrentConfig(true);
        } else {
            moduleActive = false;
            updateModuleStatus(false, 'Módulo no encontrado');
            document.getElementById('configStatus').textContent = '✗';
            document.getElementById('configStatus').style.color = '#dc2626';
            document.getElementById('currentConfig').style.display = 'none';
            document.getElementById('configContent').textContent = '';
        }

    } catch (error) {
        log(`Error verificando módulo: ${error.message}`, 'error');
        moduleActive = false;
        updateModuleStatus(false, 'Error de verificación');
    }
}

function updateModuleStatus(active, message) {
    const statusElement = document.getElementById('moduleStatus');
    moduleActive = active;

    if (active) {
        statusElement.className = 'module-status status-active';
        statusElement.innerHTML = `
                    <svg class="icon" viewBox="0 0 24 24">
                        <polyline points="20,6 9,17 4,12"/>
                    </svg>
                    ${message}
                `;
    } else {
        statusElement.className = 'module-status status-inactive';
        statusElement.innerHTML = `
                    <svg class="icon" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="15" y1="9" x2="9" y2="15"/>
                        <line x1="9" y1="9" x2="15" y2="15"/>
                    </svg>
                    ${message}
                `;
    }
}

// Escanear temas disponibles desde themes.json vía fetch
async function scanThemes(autoTrigger = false) {
    if (!moduleActive) {
        if (!autoTrigger) {
            showAlert('Debe verificar el módulo primero', 'warning');
        }
        return;
    }

    showLoading(true);
    log('📂 Cargando lista de temas desde themes.json (fetch)...', 'info');

    try {
        const response = await fetch('themes.json', { cache: 'no-store' });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const themeData = await response.json();

        // Extraer solo los nombres de archivo .zip
        const themeFiles = themeData
            .map(item => (typeof item.filename === 'string' ? item.filename.trim() : ''))
            .filter(name => name.endsWith('.zip'));

        // Quitar duplicados y ordenar
        const uniqueThemes = Array.from(new Set(themeFiles));
        uniqueThemes.sort((a, b) => a.localeCompare(b, 'es', { sensitivity: 'base' }));

        availableThemes = uniqueThemes;
        populateThemeSelectors(uniqueThemes);

        document.getElementById('themeCount').textContent = uniqueThemes.length;

        if (uniqueThemes.length > 0) {
            log(`🎨 Temas encontrados (${uniqueThemes.length}): ${uniqueThemes.join(', ')}`, 'success');
            if (!autoTrigger) {
                showAlert(`Encontrados ${uniqueThemes.length} temas`, 'success');
            }
        } else {
            log('⚠️ No se encontraron temas en themes.json', 'warning');
            if (!autoTrigger) {
                showAlert('No se encontraron temas en el archivo JSON', 'warning');
            }
        }

    } catch (error) {
        log(`❌ Error cargando themes.json vía fetch: ${error.message}`, 'error');
        showAlert('Error cargando lista de temas', 'error');
        availableThemes = [];
    } finally {
        showLoading(false);
    }
}



// Mostrar temas en la interfaz
function displayThemes(themes) {
    const themesList = document.getElementById('themesList');
    if (!themesList) {
        return;
    }

    themesList.innerHTML = '';
    themesList.style.display = themes.length > 0 ? 'block' : 'none';

    if (themes.length === 0) {
        themesList.innerHTML = `
                    <div style="text-align: center; padding: 20px; color: #6b7280;">
                        <svg class="icon" viewBox="0 0 24 24" style="width: 40px; height: 40px; margin-bottom: 10px; opacity: 0.5;">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="15" y1="9" x2="9" y2="15"/>
                            <line x1="9" y1="9" x2="15" y2="15"/>
                        </svg>
                        <p>No hay temas disponibles</p>
                        <p style="font-size: 11px; margin-top: 8px;">Coloque archivos .zip en: ${THEME_PATH}</p>
                    </div>
                `;
        return;
    }

    const fragment = document.createDocumentFragment();

    themes.forEach((theme, index) => {
        const themeItem = document.createElement('div');
        themeItem.className = 'theme-item';
        themeItem.innerHTML = `
                    <div class="theme-item-name">
                        <svg class="icon" viewBox="0 0 24 24" style="width: 16px; height: 16px; color: #4CAF50;">
                            <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>
                            <rect x="8" y="2" width="8" height="4" rx="1" ry="1"/>
                        </svg>
                        <span>${theme}</span>
                    </div>
                    <div class="theme-item-size" id="size-${index}">...</div>
                `;

        themeItem.addEventListener('click', () => {
            document.querySelectorAll('.theme-item').forEach(item => {
                item.classList.remove('selected');
            });
            themeItem.classList.add('selected');
            log(`Tema seleccionado: ${theme}`, 'info');
        });

        fragment.appendChild(themeItem);
        getFileSize(theme, index);
    });

    themesList.appendChild(fragment);
}

// Obtener tamaño de archivo
async function getFileSize(filename, index) {
    try {
        const sizeBytes = await executeCommand(`stat -c%s "${THEME_PATH}/${filename}" 2>/dev/null || echo "0"`);
        const bytes = parseInt(sizeBytes.trim()) || 0;
        const sizeText = formatFileSize(bytes);
        const sizeElement = document.getElementById(`size-${index}`);
        if (sizeElement) {
            sizeElement.innerHTML = `
                        <svg class="icon" viewBox="0 0 24 24" style="width: 14px; height: 14px;">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                        </svg>
                        ${sizeText}
                    `;
        }
    } catch (error) {
        const sizeElement = document.getElementById(`size-${index}`);
        if (sizeElement) {
            sizeElement.textContent = 'Error';
        }
    }
}

// Formatear tamaño de archivo
function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

// Poblar selectores de temas
function populateThemeSelectors(themes) {
    const lightThemeSelect = document.getElementById('lightTheme');
    const darkThemeSelect = document.getElementById('darkTheme');

    lightThemeSelect.innerHTML = '<option value="">Seleccionar...</option>';
    darkThemeSelect.innerHTML = '<option value="">Seleccionar...</option>';

    themes.forEach(theme => {
        const optionLight = document.createElement('option');
        optionLight.value = theme;
        optionLight.textContent = theme;
        lightThemeSelect.appendChild(optionLight);

        const optionDark = document.createElement('option');
        optionDark.value = theme;
        optionDark.textContent = theme;
        darkThemeSelect.appendChild(optionDark);
    });

    log(`Selectores actualizados con ${themes.length} opciones`, 'info');
}

async function updateCurrentConfig(autoTrigger = false) {
    if (!moduleActive) {
        if (!autoTrigger) {
            showAlert('Debe verificar el módulo primero', 'warning');
        }
        document.getElementById('currentConfig').style.display = 'none';
        document.getElementById('configContent').textContent = '';
        return;
    }

    try {
        const result = await executeCommand(`cat "${CONFIG_PATH}" 2>/dev/null || echo ""`);
        const configContent = result.trim();

        if (!configContent) {
            document.getElementById('currentConfig').style.display = 'none';
            document.getElementById('configContent').textContent = '';

            if (!autoTrigger) {
                showAlert('Archivo de configuración vacío', 'warning');
            }
            return;
        }

        const lines = configContent.split(/\r?\n/)
            .map(line => line.trim())
            .filter(line => line.length > 0 && !line.startsWith('#'));

        let lightTheme = '';
        let darkTheme = '';

        for (const line of lines) {
            if (line.startsWith('ro.com.google.ime.theme_file=')) {
                lightTheme = line.split('=')[1]?.trim() || '';
            } else if (line.startsWith('ro.com.google.ime.d_theme_file=')) {
                darkTheme = line.split('=')[1]?.trim() || '';
            }
        }

        displayCurrentConfig({
            lightTheme,
            darkTheme,
            fullConfig: configContent
        });

        if (lightTheme && availableThemes.includes(lightTheme)) {
            document.getElementById('lightTheme').value = lightTheme;
        }
        if (darkTheme && availableThemes.includes(darkTheme)) {
            document.getElementById('darkTheme').value = darkTheme;
        }

        if (!autoTrigger) {
            showAlert('Configuración cargada', 'success');
        }

        log(`Tema claro actual: ${lightTheme || 'No configurado'}`, 'info');
        log(`Tema oscuro actual: ${darkTheme || 'No configurado'}`, 'info');

    } catch (error) {
        log(`Error leyendo configuración: ${error.message}`, 'error');
        document.getElementById('currentConfig').style.display = 'none';
        document.getElementById('configContent').textContent = '';
        if (!autoTrigger) {
            showAlert('Error al leer la configuración', 'error');
        }
    }
}

// Mostrar configuración actual
function displayCurrentConfig(config) {
    const configContainer = document.getElementById('currentConfig');
    const configContent = document.getElementById('configContent');

    const fullConfigLines = config.fullConfig
        .split(/\r?\n/)
        .map(line => line.trim())
        .filter(line => line.length > 0);

    const themeLines = fullConfigLines
        .filter(line => line.startsWith('ro.com.google.ime.theme_file=') && line.startsWith('ro.com.google.ime.d_theme_file='));

    const otherLines = fullConfigLines
        .filter(line => !line.startsWith('ro.com.google.ime.theme_file=') && !line.startsWith('ro.com.google.ime.d_theme_file='));

    configContent.innerHTML = `
    <h5>🔧 Configuración de Temas:</h5>
    <div class="config-line">ro.com.google.ime.theme_file=${config.lightTheme}</div>
    <div class="config-line">ro.com.google.ime.d_theme_file=${config.darkTheme}</div>
    
    ${otherLines.length > 0 ? `
        <details style="margin-top: 10px;">
            <summary style="cursor: pointer; font-weight: 500; font-size: 12px;">⚙️ Otras propiedades (${otherLines.length})</summary>
            <div style="max-height: 120px; overflow-y: auto; background: #f8fafc; padding: 8px; border-radius: 4px; font-family: monospace; font-size: 10px; margin-top: 5px;">
                ${otherLines.map(line => `<div style="color: #64748b;">${line}</div>`).join('')}
            </div>
        </details>
    ` : ''}
`;


    configContainer.style.display = 'block';
}

async function applyThemes() {
    if (!moduleActive) {
        showAlert('Debe verificar el módulo primero', 'warning');
        return;
    }


    const lightTheme = document.getElementById('lightTheme').value;
    const darkTheme = document.getElementById('darkTheme').value;

    if (!lightTheme || !darkTheme) {
        showAlert('Debe seleccionar ambos temas', 'warning');
        return;
    }

    showLoading(true);
    log('Aplicando configuración...', 'info');

    try {

        log(`Aplicando tema claro: ${lightTheme}`, 'info');
        log(`Aplicando tema oscuro: ${darkTheme}`, 'info');

        // Limpiar configuraciones previas
        await executeCommand(`sed -i '/^ro.com.google.ime.theme_file=/d' "${CONFIG_PATH}"`);
        await executeCommand(`sed -i '/^ro.com.google.ime.d_theme_file=/d' "${CONFIG_PATH}"`);

        // Escribir nuevas propiedades
        await executeCommand(`echo "ro.com.google.ime.theme_file=${lightTheme}" >> "${CONFIG_PATH}"`);
        await executeCommand(`echo "ro.com.google.ime.d_theme_file=${darkTheme}" >> "${CONFIG_PATH}"`);

        // Permisos correctos
        await executeCommand(`chmod 644 "${CONFIG_PATH}"`);
        await executeCommand(`chown root:root "${CONFIG_PATH}"`);

        // Verificar configuración escrita
        const verifyConfig = await executeCommand(`cat "${CONFIG_PATH}"`);
        log(`Verificación - Nueva configuración (${verifyConfig.length} chars):`, 'info');
        log(verifyConfig.substring(0, 200), 'info');

        displayCurrentConfig({
            lightTheme,
            darkTheme,
            fullConfig: verifyConfig
        });

        showAlert('¡Temas aplicados! Reinicia para ver los cambios.', 'success');
        log('Configuración guardada exitosamente', 'success');
        log('REINICIO REQUERIDO para aplicar cambios', 'warning');

    } catch (error) {
        log(`Error aplicando temas: ${error.message}`, 'error');
        showAlert('Error al aplicar temas', 'error');
    } finally {
        showLoading(false);
    }
}

// Limpiar log
function clearLog() {
    document.getElementById('logContainer').innerHTML = '';
    log('Log limpiado', 'info');
}

async function copyLog() {
    const logContainer = document.getElementById('logContainer');
    const entries = Array.from(logContainer.children).map(line => line.textContent);
    const logText = entries.join('\n');

    if (!logText.trim()) {
        showAlert('No hay contenido para copiar', 'warning');
        return;
    }

    try {
        if (navigator.clipboard?.writeText) {
            await navigator.clipboard.writeText(logText);
        } else {
            throw new Error('Clipboard API no disponible');
        }
        showAlert('Log copiado al portapapeles', 'success');
        log('Log copiado al portapapeles', 'success');
    } catch (error) {
        try {
            const textarea = document.createElement('textarea');
            textarea.value = logText;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
            showAlert('Log copiado al portapapeles', 'success');
            log('Log copiado al portapapeles', 'success');
        } catch (fallbackError) {
            showAlert('No se pudo copiar el log', 'error');
            log(`Error copiando log: ${fallbackError.message}`, 'error');
        }
    }
}

// Inicialización automática
document.addEventListener('DOMContentLoaded', function () {
    log('🚀 Gboard Theme Manager cargado', 'success');
    log(`📱 Módulo: gboardlite_apmods`, 'info');
    log(`📂 Ruta: ${MODDIR}`, 'info');
    log(`🎨 Temas: ${THEME_PATH}`, 'info');
    log('⚡ Listo para KernelSU', 'success');

    // Auto-inicializar después de 500ms
    setTimeout(() => {
        initializeKSU();
    }, 500);
});

// Manejo de errores globales
window.addEventListener('error', function (e) {
    log(`Error JS: ${e.message}`, 'error');
});

window.addEventListener('unhandledrejection', function (e) {
    log(`Promise rechazada: ${e.reason}`, 'error');
});