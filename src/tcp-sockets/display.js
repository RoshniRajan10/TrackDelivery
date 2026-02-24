const readline = require('readline');

function printAbovePrompt(rl, message) {
  // Clear current line
  readline.clearLine(process.stdout, 0);
  readline.cursorTo(process.stdout, 0);

  // Print the message
  debugPrint(message);

  // Restore the prompt with what user was typing
  rl._refreshLine();
}

module.exports = { printAbovePrompt };