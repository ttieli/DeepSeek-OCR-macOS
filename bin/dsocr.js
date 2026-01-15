#!/usr/bin/env node

const { spawn } = require('child_process');

// Check if dsocr is available
const checkCommand = spawn('which', ['dsocr']);

checkCommand.on('close', (code) => {
  if (code !== 0) {
    console.error('\x1b[31mError: "dsocr" command not found.\x1b[0m');
    console.error('Please ensure you have installed the python package via pipx:');
    console.error('\x1b[36m  pipx install git+https://github.com/ttieli/DeepSeek-OCR-macOS.git\x1b[0m');
    process.exit(1);
  }

  // Execute dsocr with passed arguments
  const args = process.argv.slice(2);
  const dsocr = spawn('dsocr', args, { 
    stdio: 'inherit',
    env: { ...process.env }
  });

  dsocr.on('close', (code) => {
    process.exit(code);
  });
});
