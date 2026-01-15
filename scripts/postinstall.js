const { execSync } = require('child_process');
const fs = require('fs');

console.log('\x1b[36m[DeepSeek-OCR-CLI] Post-install check...\x1b[0m');

try {
  // Check if python3 is available
  const pyVersion = execSync('python3 --version').toString().trim();
  console.log(`\x1b[32m✔ Python detected: ${pyVersion}\x1b[0m`);
} catch (e) {
  console.warn('\x1b[33mWarning: python3 not found. This CLI requires Python 3.10+.\x1b[0m');
}

try {
  // Check if dsocr (pipx installed) is available
  execSync('dsocr --help', { stdio: 'ignore' });
  console.log('\x1b[32m✔ "dsocr" command detected.\x1b[0m');
} catch (e) {
  console.log('\x1b[33mNotice: "dsocr" command not found in PATH.\x1b[0m');
  console.log('To use this CLI, please ensure the Python package is installed:');
  console.log('\x1b[36m  pipx install git+https://github.com/ttieli/DeepSeek-OCR-macOS.git\x1b[0m');
  console.log('\nEnvironment variables passed to Python process:');
  console.log('  - HF_HOME: Custom Hugging Face cache');
  console.log('  - DSOCR_MODEL_DIR: Explicit model path');
  console.log('  - DSOCR_OFFLINE: Set "1" to disable network');
}