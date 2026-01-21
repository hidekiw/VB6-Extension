import * as vscode from 'vscode';
import { VB6DocumentSymbolProvider } from './vb6SymbolProvider';

/**
 * Ativa a extensão VB6 Outline
 * Registra o Document Symbol Provider para arquivos VB6
 */
export function activate(context: vscode.ExtensionContext) {
	console.log('=== VB6 Outline extension is now active! ===');
	vscode.window.showInformationMessage('VB6 Outline extension activated!');

	// Comando de teste
	const testCommand = vscode.commands.registerCommand('vb6-outline.testExtension', () => {
		const editor = vscode.window.activeTextEditor;
		if (editor) {
			const doc = editor.document;
			const msg = `File: ${doc.fileName}\nLanguage: ${doc.languageId}\nLines: ${doc.lineCount}`;
			vscode.window.showInformationMessage(msg);
			console.log('Active document info:', msg);
		} else {
			vscode.window.showWarningMessage('No active editor');
		}
	});

	// Seletor de documentos VB6 (.cls, .bas, .frm)
	const VB6_SELECTOR: vscode.DocumentSelector = [
		{ language: 'vb', scheme: 'file', pattern: '**/*.cls' },
		{ language: 'vb', scheme: 'file', pattern: '**/*.bas' },
		{ language: 'vb', scheme: 'file', pattern: '**/*.frm' },
		{ scheme: 'file', pattern: '**/*.cls' },
		{ scheme: 'file', pattern: '**/*.bas' },
		{ scheme: 'file', pattern: '**/*.frm' }
	];

	console.log('VB6 Selector configured:', VB6_SELECTOR);

	// Registra o Document Symbol Provider
	const symbolProvider = new VB6DocumentSymbolProvider();
	const disposable = vscode.languages.registerDocumentSymbolProvider(
		VB6_SELECTOR,
		symbolProvider,
		{ label: 'VB6' }
	);

	console.log('VB6 Document Symbol Provider registered successfully');

	context.subscriptions.push(testCommand);
	context.subscriptions.push(disposable);
}

export function deactivate() {}
